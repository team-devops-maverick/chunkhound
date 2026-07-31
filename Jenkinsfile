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
    }
        post {
        always {
            sh '''
            rm -rf .venv
            '''
        }
    }

}
