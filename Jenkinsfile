pipeline {
    agent any

    environment {
        JAVA_HOME = tool name: 'JDK17', type: 'jdk' // Use Jenkins-managed JDK
        PATH = "${JAVA_HOME}/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:${env.PATH}"
        SONAR_TOKEN = credentials('01') // SonarQube token
        SONAR_HOST_URL = 'http://localhost:9000/' // SonarQube URL
        DOCKER_IMAGE = 'kunj22/secure-app:latest'
        DOCKER_CREDENTIALS = credentials('09') // Docker credentials
    }

    stages {
        stage('Clone') {
            steps {
                git url: 'https://github.com/kunjbhuva7/secure-devops-pipline.git', branch: 'main', credentialsId: '001'
            }
        }

        stage('Parallel Checks') {
            parallel {
                stage('SonarQube Analysis') {
                    steps {
                        withSonarQubeEnv('MySonarQube') {
                            script {
                                def scannerHome = tool name: 'SonarQubeScanner', type: 'hudson.plugins.sonar.SonarRunnerInstallation'
                                sh """
                                    ${scannerHome}/bin/sonar-scanner \
                                    -Dsonar.projectKey=secure-app \
                                    -Dsonar.sources=. \
                                    -Dsonar.login=\${SONAR_TOKEN} \
                                    -Dsonar.host.url=\${SONAR_HOST_URL} || true
                                """
                            }
                        }
                    }
                }

                stage('OWASP Dependency Check') {
                    agent {
                        docker {
                            image 'owasp/dependency-check:latest'
                            args '-v ${WORKSPACE}/reports:/usr/share/dependency-check/data'
                        }
                    }
                    steps {
                        sh 'dependency-check --scan . --format ALL --out /usr/share/dependency-check/data || true'
                    }
                }

                stage('Trivy FS Scan') {
                    agent {
                        docker {
                            image 'aquasec/trivy:latest'
                            args '-v ${WORKSPACE}:/workspace'
                        }
                    }
                    steps {
                        sh 'trivy fs --format json --output /workspace/trivy-fs-report.json /workspace || true'
                    }
                }
            }
        }

        stage('Build Docker') {
            steps {
                script {
                    // Verify Docker is accessible
                    sh 'docker info || { echo "Docker daemon not running"; exit 1; }'
                    sh 'docker build -t ${DOCKER_IMAGE} .'
                }
            }
        }

        stage('Trivy Image Scan') {
            agent {
                docker {
                    image 'aquasec/trivy:latest'
                }
            }
            steps {
                sh 'trivy image --format json --output trivy-image-report.json ${DOCKER_IMAGE} || true'
            }
        }

        stage('Archive Trivy Report') {
            steps {
                archiveArtifacts artifacts: 'trivy-*.json', allowEmptyArchive: true
            }
        }

        stage('Terraform Validate') {
            steps {
                script {
                    // Check if terraform directory exists
                    if (fileExists('terraform')) {
                        dir('terraform') {
                            sh 'terraform init || { echo "Terraform init failed"; exit 1; }'
                            sh 'terraform validate || { echo "Terraform validate failed"; exit 1; }'
                        }
                    } else {
                        echo "Terraform directory not found, skipping stage"
                    }
                }
            }
        }

        stage('tfsec Scan') {
            agent {
                docker {
                    image 'aquasec/tfsec:latest'
                    args '-v ${WORKSPACE}/terraform:/workspace'
                }
            }
            steps {
                script {
                    if (fileExists('terraform')) {
                        dir('terraform') {
                            sh 'tfsec /workspace --format json --out tfsec-report.json || true'
                        }
                    } else {
                        echo "Terraform directory not found, skipping stage"
                    }
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: '09', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    script {
                        sh '''
                            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin || { echo "Docker login failed"; exit 1; }
                            docker push ${DOCKER_IMAGE} || { echo "Docker push failed"; exit 1; }
                        '''
                    }
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
                        <p>Check logs at <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>
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
                        <p>The Jenkins pipeline <strong>${currentBuild.fullDisplayName}</strong> has failed. Please check the logs at <a href="${env.BUILD_URL}">${env.BUILD_URL}</a>.</p>
                    </body>
                </html>''',
                to: 'kunjbhuva301@gmail.com',
                mimeType: 'text/html',
                attachLog: true
            )
        }
        unstable {
            emailext (
                subject: "UNSTABLE: Jenkins Pipeline - ${currentBuild.fullDisplayName}",
                body: '''<html>
                    <body>
                        <h2 style="color: orange;">Unstable!</h2>
                        <p>The Jenkins pipeline <strong>${currentBuild.fullDisplayName}</strong> is unstable. Please check the logs at <a href="${env.BUILD_URL}">${env.BUILD_URL}</a>.</p>
                    </body>
                </html>''',
                to: 'kunjbhuva301@gmail.com',
                mimeType: 'text/html',
                attachLog: true
            )
        }
    }
}
