pipeline {
    agent any

    environment {
        SONAR_TOKEN = credentials('01')
        SONAR_HOST_URL = 'http://localhost:9000'
        DOCKER_IMAGE = 'kunj22/secure-app'
    }

    stages {
        stage('Clone') {
            steps {
                git 'https://github.com/kunjbhuva7/secure-devops-pipline.git'
            }
        }

        stage('SonarQube') {
            steps {
                withSonarQubeEnv('MySonarQube') {
                    sh 'sonar-scanner'
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
                sh 'trivy image $DOCKER_IMAGE > trivy-report.txt || true'
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
                    sh 'tfsec . > tfsec-report.txt || true'
                }
            }
        }

        stage('Push Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                    sh '''
                        echo "$PASS" | docker login -u "$USER" --password-stdin
                        docker push $DOCKER_IMAGE
                    '''
                }
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: '**/*.txt, **/reports/**', allowEmptyArchive: true
        }
    }
}

