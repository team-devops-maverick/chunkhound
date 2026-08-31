# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

@AGENTS.md

## Architecture

ChunkHound is a local-first codebase intelligence tool (Python + a small Rust/PyO3
accelerator) exposed via a CLI and an MCP server. It indexes code with Tree-sitter,
embeds/searches it, and layers git-history and web research on top.

### Layering: interfaces → providers → services → registry

- `chunkhound/interfaces/` — `Protocol` definitions only (`DatabaseProvider`,
  `EmbeddingProvider`, `LanguageParser`, `LLMProvider`). Nothing here has logic.
- `chunkhound/providers/` — concrete implementations of those protocols:
  - `database/`: `duckdb_provider.py` (default) and `lancedb_provider.py`, both
    wrapped by a `serial_database_provider.py`/`serial_executor.py` that
    serializes access onto one thread (DuckDB/LanceDB connections aren't
    safely shared across threads/processes).
  - `embeddings/`: `openai_provider.py`, `voyageai_provider.py` (+ shared batching
    utils in `batch_utils.py`/`shared_utils.py`).
  - `llm/`: one provider per backend — `anthropic_llm_provider.py`,
    `openai_llm_provider.py`, `gemini_llm_provider.py`, plus **CLI-wrapper**
    providers (`claude_code_cli_provider.py`, `codex_cli_provider.py`,
    `opencode_cli_provider.py` via `base_cli_provider.py`) that shell out to an
    already-authenticated coding-agent CLI instead of calling an API directly —
    this is how `llm.provider: "claude-code-cli"` avoids needing an API key.
- `chunkhound/services/` — business logic that depends only on the interfaces,
  never on concrete providers directly. Key services: `indexing_coordinator.py`
  (the largest file in the repo — file discovery, chunking, dedup, DB writes),
  `search_service.py` (regex + semantic search, delegates strategy to
  `services/search/{single_hop,multi_hop}_strategy.py`), `embedding_service.py`
  (batching/backpressure to the embedding provider), and `deep_research_service.py`
  (orchestrates search + LLM to produce cited answers; versioned prompt/strategy
  logic lives under `services/research/{shared,v1}/`).
- `chunkhound/registry/__init__.py` — the DI container (`ProviderRegistry`/
  `get_registry()`). `Config` in → providers constructed and registered → services
  requested via `create_indexing_coordinator()` / `create_search_service()` /
  `create_embedding_service()`. Language parsers are registered as lazy factories
  (`LazyLanguageParsers`) so Tree-sitter grammars are only loaded on first use of
  that language. This is the one place that wires concrete providers to services —
  new provider implementations get registered here, not constructed ad hoc.

### Config precedence

`chunkhound/core/config/config.py`'s `Config` (Pydantic) resolves settings in this
order, highest first: CLI args → explicit `--config`/`CHUNKHOUND_CONFIG_FILE` →
project-local `.chunkhound.json` → global config (`~/.config/chunkhound/` or
`CHUNKHOUND_GLOBAL_CONFIG_FILE`) → `CHUNKHOUND_*` env vars → defaults. It composes
`DatabaseConfig`, `EmbeddingConfig`, `LLMConfig`, `MCPConfig`, `IndexingConfig`,
`ResearchConfig`. See `DB_PATH_GOTCHAS` in AGENTS.md — DB path resolution is a
frequent source of "silently returns 0 results" bugs.

### Entry points

- `chunkhound/api/cli/main.py` — argparse CLI (`index`, `mcp`, `search`,
  `research`, `websearch`, `autodoc`, `map`, `calibrate`, plus hidden internal
  commands `_quickresearch` and `_daemon`). Each subcommand's implementation is
  imported lazily inside `async_main()` to keep `--help` and unrelated commands
  fast to start.
- `chunkhound/mcp_server/` — the MCP protocol surface (`stdio.py` for the
  standard stdio transport; tool schemas/handlers in `tools.py`). This is what
  editors/agents talk to via `chunkhound mcp`.
- `chunkhound/daemon/` — an optional single-process, multi-client daemon
  (`server.py: ChunkHoundDaemon`) that owns the one DuckDB connection and serves
  multiple MCP proxy clients concurrently over a length-prefixed JSON-RPC 2.0 IPC
  protocol on a Unix socket (`discovery.py` finds/starts it, `client_proxy.py` is
  the thin client used by each MCP session). This exists because DuckDB doesn't
  support concurrent writers — running multiple editor windows/MCP clients
  against the same project would otherwise contend on the DB file.
- `chunkhound/watchman/` (+ bundled per-platform binaries in
  `watchman_runtime/platforms/`) drives realtime reindexing on file changes;
  `services/realtime/` and `services/realtime_path_filter.py` debounce and filter
  which changed files trigger reindexing.

### Rust accelerator

`src/lib.rs` is a small PyO3 extension (`chunkhound_native`, `#![forbid(unsafe_code)]`)
built with `maturin` and imported from `chunkhound_native/__init__.py`. It currently
exposes one function, `scan_files`, which does gitignore-aware directory walking
(via the `ignore` crate) faster than the Python equivalent. Rebuild it with
`make dev` (debug) or `make dev-release` after touching `src/lib.rs`; see
`RUST_RULES`/`RUST_COMMANDS` in AGENTS.md for the coding constraints.

### Higher-level features built on search/indexing

- `chunkhound/code_mapper/` — generates an architecture/coverage map of a
  codebase (`orchestrator.py`/`pipeline.py` drive scope selection, HyDE-style
  retrieval, and LLM synthesis; `coverage.py` tracks what fraction of the
  codebase the map accounts for).
- `chunkhound/autodoc/` — turns research output into a static doc site
  (`generator.py`, `site_writer*.py`, `ia.py` for information architecture).
- Git-history search (`--last-n`, `--commit-range`, `--commit-hash`) lives under
  `chunkhound/core/git_diff/` and is consumed by both `search` and `research`
  commands as an alternate vector source over diffs instead of the indexed DB.

### Data model

Everything downstream of parsing flows through three core models
(`chunkhound/core/models/`): `File`, `Chunk`, `Embedding`. Every `DatabaseProvider`
implementation and every `LanguageParser` implementation produces/consumes these
same types, which is what makes DuckDB/LanceDB and the many Tree-sitter language
mappings (`chunkhound/parsers/mappings/`) swappable behind their respective
interfaces.
