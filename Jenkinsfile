pipeline {

    agent any
    environment {
        GH_TOKEN = credentials('github-token')
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'newBranch',
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
                                rm -f dist/*.whl dist/*.tar.gz
                        rm -rf .venv
                        uv venv
                        . .venv/bin/activate
                        uv -q sync
                        uv pip install -q -r requirements.txt
                        uv build
                '''
            }
        }    
        stage('Smoke Test') {
    steps {
        sh '''
        export PATH="$HOME/.local/bin:$PATH"

        rm -rf smoke-test
        uv venv smoke-test
        . smoke-test/bin/activate

        uv pip install dist/*.whl

        python -c "
import chunkhound
print('Version:', getattr(chunkhound, '__version__', 'unknown'))
print('Import successful')
"
        '''
    }
}
        stage('Publish Release') {
    steps {
        withCredentials([string(credentialsId: 'github-token', variable: 'GH_TOKEN')]) {
            sh '''
                gh release create v0.1.1 \
                  --title "Chunkhound Maverick v0.1.1" \
                  --notes "Automated Jenkins release" || true

                gh release upload v0.1.1 dist/*.whl --clobber
            '''
        }
    }
}
    }
        post {
        always {
            sh '''
            rm -rf smoke-test
            rm -rf .venv
            '''
        }
    }

}
