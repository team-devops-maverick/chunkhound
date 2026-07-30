#!/usr/bin/env bash

echo "Hello"

set -e
cd "$(dirname "$0")"
exec npx -y supergateway \
  --stdio "uv run chunkhound mcp --db .chunkhound/db ." \
  --port 8080 \
  --cors \
  --outputTransport streamableHttp
