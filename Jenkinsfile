pipeline {
    agent any

    environment {
        JAVA_HOME = "/opt/homebrew/opt/openjdk"
        PATH = "${JAVA_HOME}/bin:/opt/homebrew/bin:$PATH"
        SONAR_TOKEN = credentials('Hello-sonarqube') // Using credentials instead of hardcoding the token
        SONAR_HOST_URL = 'http://localhost:9000' // URL of your SonarQube instance
        DOCKER_IMAGE = 'kunj22/secure-app'
    }

    stages {
        stage('Clone') {
            steps {
                script {
                    // Fetch all branches and updates before checking out the main branch
                    sh 'git fetch --all'
                    // Checkout to main branch explicitly to avoid any issues
                    sh 'git checkout main'
                    // Ensure the correct repository is being used and the latest code is fetched
                    git url: 'https://github.com/kunjbhuva7/secure-devops-pipline.git', branch: 'main'
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarScanner') { // Use the SonarQube server configured in Jenkins
                    sh '''
                         sonar-scanner \
                        -Dsonar.projectKey=secure-app \
                        -Dsonar.sources=. \
                        -Dsonar.login=${SONAR_TOKEN} \
                        -Dsonar.host.url=${SONAR_HOST_URL}
                    '''
                }
            }
        }

        stage('OWASP Dependency Check') {
            steps {
                sh 'dependency-check --scan . --format "ALL" --out reports/'
            }
        }

        stage('Build Docker') {
            steps {
                sh 'docker build -t $DOCKER_IMAGE .'
            }
        }

        stage('Trivy Scan') {
            steps {
                script {
                    echo "Running Trivy Scan on Docker image"
                    // Run Trivy Scan and save output to a report file
                    sh 'trivy image $DOCKER_IMAGE > trivy-report.txt || true'
                }
            }
        }

        stage('Archive Trivy Report') {
            steps {
                // Save Trivy report as an artifact
                archiveArtifacts artifacts: 'trivy-report.txt', allowEmptyArchive: true
            }
        }

        stage('Terraform Validate') {
            steps {
                dir('terraform') { // Run Terraform commands inside the 'terraform' directory
                    sh 'terraform init'
                    sh 'terraform validate'
                }
            }
        }

        stage('tfsec Scan') {
            steps {
                dir('terraform') { // Run tfsec to scan the Terraform code for security issues
                    sh 'tfsec . > tfsec-report.txt || true'
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                    sh '''
                        echo "$PASS" | docker login -u "$USER" --password-stdin  // Log into Docker Hub
                        docker push $DOCKER_IMAGE  // Push Docker image to the registry
                    '''
                }
            }
        }
    }

    post {
        always {
            // Archive the reports and logs, even if the build fails
            archiveArtifacts artifacts: '**/*.txt, **/reports/**', allowEmptyArchive: true
        }
        success {
            script {
                // Send success email with green color
                emailext (
                    subject: "SUCCESS: Jenkins Pipeline - ${currentBuild.fullDisplayName}",
                    body: '''<html>
                        <body>
                            <h2 style="color: green;">Success!</h2>
                            <p>The Jenkins pipeline <strong>${currentBuild.fullDisplayName}</strong> has successfully completed.</p>
                        </body>
                    </html>''',
                    to: 'kunjbhuva301@gmail.com'
                )
            }
        }
        failure {
            script {
                // Send failure email with red color
                emailext (
                    subject: "FAILURE: Jenkins Pipeline - ${currentBuild.fullDisplayName}",
                    body: '''<html>
                        <body>
                            <h2 style="color: red;">Failure!</h2>
                            <p>The Jenkins pipeline <strong>${currentBuild.fullDisplayName}</strong> has failed. Please check the logs for more details.</p>
                        </body>
                    </html>''',
                    to: 'kunjbhuva301@gmail.com'
                )
            }
        }
        unstable {
            script {
                // Send unstable email with pink color
                emailext (
                    subject: "UNSTABLE: Jenkins Pipeline - ${currentBuild.fullDisplayName}",
                    body: '''<html>
                        <body>
                            <h2 style="color: pink;">Unstable!</h2>
                            <p>The Jenkins pipeline <strong>${currentBuild.fullDisplayName}</strong> is unstable. Please check the logs for more details.</p>
                        </body>
                    </html>''',
                    to: 'kunjbhuva301@gmail.com'
                )
            }
        }
    }
}

