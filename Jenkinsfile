pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "region-health-monitor"
        DOCKER_TAG = "${BUILD_NUMBER}"
        REGISTRY = "<your-dockerhub-username>"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Install Dependencies') {
            steps {
                sh '''
                    python3 -m venv venv
                    . venv/bin/activate
                    pip install -r requirements.txt
                '''
            }
        }

        stage('Unit Tests') {
            steps {
                sh '''
                    . venv/bin/activate
                    pytest -v --junitxml=test-results.xml
                '''
            }
            post {
                always {
                    junit 'test-results.xml'
                }
            }
        }

        stage('Security: Dependency Scan') {
            steps {
                sh '''
                    . venv/bin/activate
                    pip-audit -r requirements.txt || true
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${REGISTRY}/${DOCKER_IMAGE}:${DOCKER_TAG} ."
            }
        }

        stage('Security: Container Scan') {
            steps {
                sh '''
                    # Install Trivy if not present
                    if ! command -v trivy &> /dev/null; then
                        curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sudo sh -s -- -b /usr/local/bin
                    fi
                    trivy image --severity HIGH,CRITICAL --exit-code 0 ${REGISTRY}/${DOCKER_IMAGE}:${DOCKER_TAG}
                '''
            }
        }

        stage('Push Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh '''
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        docker push ${REGISTRY}/${DOCKER_IMAGE}:${DOCKER_TAG}
                    '''
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh '''
                    # Ensure kind cluster exists
                    if ! kind get clusters | grep -q health-monitor; then
                        bash scripts/setup-node.sh
                    fi
                    # Update image tag in manifest
                    sed -i "s|image:.*|image: ${REGISTRY}/${DOCKER_IMAGE}:${DOCKER_TAG}|" k8s/deployment.yaml
                    kubectl apply -f k8s/deployment.yaml
                    kubectl rollout status deployment/health-monitor --timeout=60s
                '''
            }
        }
    }

    post {
        always {
            sh 'bash scripts/cleanup-images.sh || true'
        }
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed. Check logs above.'
        }
    }
}
