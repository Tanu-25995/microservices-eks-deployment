pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = 'ap-northeast-1'
        DOCKER_CLIENT_TIMEOUT = '300'
        COMPOSE_HTTP_TIMEOUT = '300'
    }

    stages {

        stage('Checkout Code') {
            steps {
                git branch: 'main', url: 'https://github.com/Tanu-25995/microservices-eks-deployment.git'
            }
        }

        stage('Build & Push Docker Images') {
            steps {
                sh '''
                cd microservices
                chmod +x docker_image_buid_push.sh
                ./docker_image_buid_push.sh
                '''
            }
        }

        stage('Deploy to EKS') {
            steps {
                sh '''
                kubectl apply -f microservices/kubernetes-manifests
                '''
            }
        }

        stage('Verify Deployment') {
            steps {
                sh 'kubectl get pods'
            }
        }
    }
}
