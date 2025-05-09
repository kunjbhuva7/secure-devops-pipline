pipeline {
    agent any

    environment {
        JAVA_HOME = "/opt/homebrew/opt/openjdk"
        PATH = "${JAVA_HOME}/bin:/opt/homebrew/bin:/opt/sonar-scanner/bin:$PATH"
        SONAR_TOKEN = credentials('01') // Using credentials for SonarQube token
        SONAR_HOST_URL = 'http://localhost:9000' // SonarQube instance URL
        DOCKER_IMAGE = 'kunj22/secure-app'
    }

    stages {
        stage('Clone') {
            steps {
                script {
                    // Fetch and checkout the main branch
                    git url: 'https://github.com/kunjbhuva7/secure-devops-pipline.git', branch: 'main', credentialsId: '001'
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('MySonarQube') {
                    script {
                        def scannerHome = tool name: 'SonarScanner', type: 'hudson.plugins.sonar.SonarRunnerInstallation'
                        sh "${scannerHome}/bin/sonar-scanner -Dsonar.projectKey=secure-app -Dsonar.sources=. -Dsonar.login=${SONAR_TOKEN} -Dsonar.host.url=${SONAR_HOST_URL}"
                    }
                }
            }
        }

        stage('OWASP Dependency Check') {
            steps {
                sh 'dependency-check --scan . --format ALL --out reports/ || true'
            }
        }

        stage('Build Docker') {
            steps {
                sh 'docker build -t ${DOCKER_IMAGE} .'
            }
        }

        stage('Trivy Scan') {
            steps {
                script {
                    echo "Running Trivy Scan on Docker image"
                    sh 'trivy image --format json --output trivy-report.json ${DOCKER_IMAGE} || true'
                }
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
                withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
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
