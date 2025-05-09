pipeline {
    agent any

    environment {
        JAVA_HOME = tool name: 'JDK17', type: 'jdk' // Jenkins-managed JDK
        PATH = "${JAVA_HOME}/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:${env.PATH}"
        SONAR_TOKEN = credentials('01') // SonarQube token
        DOCKER_CREDENTIALS = credentials('09') // Docker credentials
        DOCKER_IMAGE = 'kunj22/secure-app:latest'
    }

    stages {
        stage('Debug Environment') {
            steps {
                script {
                    echo "Debugging Environment..."
                    sh '''
                        echo "PATH: $PATH"
                        echo "JAVA_HOME: $JAVA_HOME"
                        java -version || echo "Java not found"
                        git --version || echo "Git not found"
                        docker info || echo "Docker daemon not running"
                        whoami
                        pwd
                        ls -la
                    '''
                }
            }
        }

        stage('Clone') {
            steps {
                script {
                    echo "Cloning repository..."
                    git url: 'https://github.com/kunjbhuva7/secure-devops-pipline.git', branch: 'main', credentialsId: '001'
                    sh 'git log -1' // Verify the latest commit
                }
            }
        }

        stage('Build Docker') {
            steps {
                script {
                    echo "Building Docker image..."
                    sh 'docker info || { echo "Docker daemon not running"; exit 1; }'
                    sh 'docker build -t ${DOCKER_IMAGE} .'
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: '09', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    script {
                        echo "Pushing Docker image..."
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
            archiveArtifacts artifacts: '**/*.txt, **/*.json', allowEmptyArchive: true
            emailext (
                subject: "${currentBuild.currentResult}: Jenkins Pipeline - ${currentBuild.fullDisplayName}",
                body: '''<html>
                    <body>
                        <h2 style="color: ${currentBuild.currentResult == 'SUCCESS' ? 'green' : 'red'};">${currentBuild.currentResult}</h2>
                        <p>The Jenkins pipeline <strong>${currentBuild.fullDisplayName}</strong> has completed with status: ${currentBuild.currentResult}.</p>
                        <p>Check logs at <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>
                    </body>
                </html>''',
                to: 'kunjbhuva301@gmail.com',
                mimeType: 'text/html',
                attachLog: true
            )
        }
    }
}
