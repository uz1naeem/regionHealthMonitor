pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "region-health-monitor"
        DOCKER_TAG = "${BUILD_NUMBER}"
        REGISTRY = "uz1naeem"
        TF_DIR = "infra/terraform/environments/dev"
        TF_ENV = "dev"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Format & Validate') {
            steps {
                dir("${TF_DIR}") {
                    sh 'terraform fmt -check -recursive'
                    sh 'terraform init -input=false'
                    sh 'terraform validate'
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir("${TF_DIR}") {
                    sh 'terraform plan -input=false -out=tfplan'
                }
                archiveArtifacts artifacts: "${TF_DIR}/tfplan", fingerprint: true
            }
        }

        stage('Terraform Apply') {
            when { branch 'main' }
            steps {
                dir("${TF_DIR}") {
                    script {
                        if (env.TF_ENV == 'dev') {
                            // Development applies automatically
                            sh 'terraform apply -input=false -auto-approve tfplan'
                        } else {
                            // Staging / production require manual approval of the plan artefact
                            input message: "Apply Terraform plan to ${TF_ENV}?", ok: 'Apply'
                            sh 'terraform apply -input=false tfplan'
                        }
                    }
                }
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
                    if ! command -v trivy > /dev/null 2>&1; then
                        curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sudo sh -s -- -b /usr/local/bin
                    fi
                    trivy image --ignore-unfixed --severity CRITICAL --exit-code 1 ${REGISTRY}/${DOCKER_IMAGE}:${DOCKER_TAG}
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
