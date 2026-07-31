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

                python3 -m ensurepip || true
                python3 -m venv venv
                source venv/bin/activate

                pip install --upgrade pip
                pip install build
                '''
            }
        }


        stage('Build Wheel') {
            steps {
                sh '''
                source venv/bin/activate

                python -m build
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
