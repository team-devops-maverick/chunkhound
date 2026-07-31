pipeline {

    agent any

        environment {
        GH_TOKEN = credentials('github-token')
    }

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
                        rm -rf .venv
        uv venv
        . .venv/bin/activate
        uv sync
                uv pip install -r requirements.txt
                '''
            }
        }


        stage('Archive Artifact') {
            steps {
                archiveArtifacts artifacts: 'dist/*.whl',
                                  fingerprint: true
            }
        }
        stage('Publish GitHub Release') {
    steps {
        sh '''
        gh release create v${BUILD_NUMBER} \
            dist/*.whl \
            --repo team-devops-maverick/chunkhound \
            --title "Build ${BUILD_NUMBER}" \
            --notes "Automated release from Jenkins"
        '''
    }
    }
    }
        post {
        always {
            sh '''
            rm -rf .venv
            '''
        }
    }

}
