pipeline {
    agent any

    environment {
        REGISTRY = "localhost:5000"
        IMAGE_NAME = "total-site"
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: "${BRANCH_NAME}", url: 'https://github.com/mrren0/site-total-space.git'
            }
        }

        stage('Build') {
            steps {
                sh 'mvn clean package'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh """
                docker build -t ${REGISTRY}/${IMAGE_NAME}:${BRANCH_NAME} .
                """
            }
        }

        stage('Push Docker Image') {
            steps {
                sh """
                docker push ${REGISTRY}/${IMAGE_NAME}:${BRANCH_NAME}
                """
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh """
                kubectl delete deployment total-site -n ${BRANCH_NAME} --ignore-not-found=true
                kubectl delete service total-site -n ${BRANCH_NAME} --ignore-not-found=true
                kubectl delete ingress total-site -n ${BRANCH_NAME} --ignore-not-found=true

                sed "s/dev/${BRANCH_NAME}/g" deployment.yaml | sed "s/dev/${BRANCH_NAME}/g" | sed "s/localhost:5000\\/total-site:dev/localhost:5000\\/total-site:${BRANCH_NAME}/g" | kubectl apply -f -
                sed "s/dev/${BRANCH_NAME}/g" service.yaml | kubectl apply -f -
                sed "s/dev/${BRANCH_NAME}/g" | sed "s/dev.total-space.online/${BRANCH_NAME}.total-space.online/g" ingress.yaml | kubectl apply -f -
                """
            }
        }
    }
}
