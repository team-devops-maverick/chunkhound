pipeline {

    agent any

    stages {

        stage('Checkout') {
            steps {
                git branch: 'feature/my-change',
                    url: 'https://github.com/team-devops-maverick/chunkhound.git'
            }
        }


        stage('Python Setup') {
            steps {
                sh '''
                echo "Hostname: $(hostname)"
                whoami
                pwd
                which python3
                python3 --version
                        curl -LsSf https://astral.sh/uv/install.sh | sh
        export PATH="$HOME/.local/bin:$PATH"
        uv --version
                '''
            }
        }


        stage('Build Wheel') {
            steps {
                sh '''
                        export PATH="$HOME/.local/bin:$PATH"
        uv venv
        . .venv/bin/activate
        uv sync
        uv build
                '''
            }
        }


        stage('Archive Artifact') {
            steps {
                archiveArtifacts artifacts: 'dist/*.whl',
                                  fingerprint: true
            }
        }


    }

}
