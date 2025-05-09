pipeline {
    agent any

    environment {
        JAVA_HOME = "/usr/lib/jvm/java-17-openjdk"
        PATH = "${JAVA_HOME}/bin:/usr/local/bin:/usr/bin:/bin:/opt/sonar-scanner/bin:$PATH"
        SONAR_TOKEN = credentials('01')
        SONAR_HOST_URL = 'http://localhost:9000'
        DOCKER_IMAGE = 'kunj22/secure-app'
        DOCKER_CREDENTIALS = credentials('09')
    }

    stages {

        stage('Check Docker Installed') {
            when { always() }
            steps {
                script {
                    def dockerExists = sh(script: 'command -v docker || true', returnStdout: true).trim()
                    if (!dockerExists) {
                        echo "Docker not found! Installing Docker..."
                        sh '''
                            apt-get update && \
                            apt-get install -y docker.io && \
                            systemctl start docker && \
                            systemctl enable docker
                        '''
                    } else {
                        echo "Docker already installed: ${dockerExists}"
                    }
                }
            }
        }

        stage('Clone') {
            when { always() }
            steps {
                git url: 'https://github.com/kunjbhuva7/secure-devops-pipline.git', branch: 'main', credentialsId: '001'
            }
        }

        stage('SonarQube Analysis') {
            when { always() }
            steps {
                withSonarQubeEnv('MySonarQube') {
                    script {
                        def scannerHome = tool name: 'SonarQubeScanner', type: 'hudson.plugins.sonar.SonarRunnerInstallation'
                        if (!scannerHome) {
                            error "SonarQube Scanner not found. Please install it under Global Tools."
                        }
                        sh """
                            ${scannerHome}/bin/sonar-scanner \
                            -Dsonar.projectKey=secure-app \
                            -Dsonar.sources=. \
                            -Dsonar.login=${SONAR_TOKEN} \
                            -Dsonar.host.url=${SONAR_HOST_URL} || true
                        """
                    }
                }
            }
        }

        stage('OWASP Dependency Check') {
            when { always() }
            steps {
                sh 'dependency-check --scan . --format ALL --out reports/ || true'
            }
        }

        stage('Build Docker') {
            when { always() }
            steps {
                sh 'docker build -t ${DOCKER_IMAGE} .'
            }
        }

        stage('Trivy Scan') {
            when { always() }
            steps {
                echo "Running Trivy Scan on Docker image"
                sh 'trivy image --format json --output trivy-report.json ${DOCKER_IMAGE} || true'
            }
        }

        stage('Archive Trivy Report') {
            when { always() }
            steps {
                archiveArtifacts artifacts: 'trivy-report.json', allowEmptyArchive: true
            }
        }

        stage('Terraform Validate') {
            when { always() }
            steps {
                dir('terraform') {
                    sh 'terraform init'
                    sh 'terraform validate'
                }
            }
        }

        stage('tfsec Scan') {
            when { always() }
            steps {
                dir('terraform') {
                    sh 'tfsec . --format json --out tfsec-report.json || true'
                }
            }
        }

        stage('Push Docker Image') {
            when { always() }
            steps {
                withCredentials([usernamePassword(credentialsId: '09', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh '''
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        docker push ${DOCKER_IMAGE}
                    '''
                }
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: '**/*.txt, **/*.json, **/reports/**', allowEmptyArchive: true
        }
        success {
            emailext (
                subject: "SUCCESS: Jenkins Pipeline - ${currentBuild.fullDisplayName}",
                body: '''<html>
                    <body>
                        <h2 style="color: green;">Success!</h2>
                        <p>The Jenkins pipeline <strong>${currentBuild.fullDisplayName}</strong> has successfully completed.</p>
                    </body>
                </html>''',
                to: 'kunjbhuva301@gmail.com',
                mimeType: 'text/html'
            )
        }
        failure {
            emailext (
                subject: "FAILURE: Jenkins Pipeline - ${currentBuild.fullDisplayName}",
                body: '''<html>
                    <body>
                        <h2 style="color: red;">Failure!</h2>
                        <p>The Jenkins pipeline <strong>${currentBuild.fullDisplayName}</strong> has failed. Please check the logs for more details.</p>
                    </body>
                </html>''',
                to: 'kunjbhuva301@gmail.com',
                mimeType: 'text/html'
            )
        }
        unstable {
            emailext (
                subject: "UNSTABLE: Jenkins Pipeline - ${currentBuild.fullDisplayName}",
                body: '''<html>
                    <body>
                        <h2 style="color: orange;">Unstable!</h2>
                        <p>The Jenkins pipeline <strong>${currentBuild.fullDisplayName}</strong> is unstable. Please check the logs for more details.</p>
                    </body>
                </html>''',
                to: 'kunjbhuva301@gmail.com',
                mimeType: 'text/html'
            )
        }
    }
}

