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
            steps {
                sh 'docker --version || (echo "Docker not found!" && exit 1)'
            }
        }

        stage('Clone') {
            steps {
                git url: 'https://github.com/kunjbhuva7/secure-devops-pipline.git', branch: 'main', credentialsId: '001'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('MySonarQube') {
                    script {
                        def scannerHome = tool name: 'SonarQubeScanner', type: 'hudson.plugins.sonar.SonarRunnerInstallation'
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
            steps {
                sh '''
                docker run --rm \
                    -v $(pwd):/src \
                    owasp/dependency-check \
                    --scan /src \
                    --format ALL \
                    --out /src/reports || true
                '''
            }
        }

        stage('Build Docker') {
            steps {
                sh 'docker build -t ${DOCKER_IMAGE} .'
            }
        }

        stage('Trivy Scan') {
            steps {
                sh '''
                docker run --rm \
                    -v /var/run/docker.sock:/var/run/docker.sock \
                    -v $(pwd):/root/.cache/ \
                    aquasec/trivy image --format json --output trivy-report.json ${DOCKER_IMAGE} || true
                '''
            }
        }

        stage('Archive Trivy Report') {
            steps {
                archiveArtifacts artifacts: 'trivy-report.json', allowEmptyArchive: true
            }
        }

        stage('Terraform Validate') {
            steps {
                dir('terraform') {
                    sh 'terraform init'
                    sh 'terraform validate'
                }
            }
        }

        stage('tfsec Scan') {
            steps {
                dir('terraform') {
                    sh 'tfsec . --format json --out tfsec-report.json || true'
                }
            }
        }

        stage('Push Docker Image') {
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
                        <h2 style="color: pink;">Unstable!</h2>
                        <p>The Jenkins pipeline <strong>${currentBuild.fullDisplayName}</strong> is unstable. Please check the logs for more details.</p>
                    </body>
                </html>''',
                to: 'kunjbhuva301@gmail.com',
                mimeType: 'text/html'
            )
        }
    }
}

