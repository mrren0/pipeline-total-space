pipeline {
    agent any

    environment {
        REGISTRY = "localhost:5000"
        IMAGE_NAME = "total-site"
        BUILD_TAG = "${BRANCH_NAME}-${new Date().format('yyyyMMdd-HHmmss')}"
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: "${BRANCH_NAME}", url: 'https://github.com/mrren0/site-total-space.git'
            }
        }

        stage('Build Maven') {
            steps {
                sh 'mvn clean package'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh """
                docker build -t ${REGISTRY}/${IMAGE_NAME}:${BUILD_TAG} .
                """
            }
        }

        stage('Push Docker Image') {
            steps {
                sh """
                docker push ${REGISTRY}/${IMAGE_NAME}:${BUILD_TAG}
                """
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh """
                kubectl create namespace ${BRANCH_NAME} --dry-run=client -o yaml | kubectl apply -f -

                kubectl delete deployment total-site -n ${BRANCH_NAME} --ignore-not-found=true
                kubectl delete service total-site -n ${BRANCH_NAME} --ignore-not-found=true
                kubectl delete ingress total-site -n ${BRANCH_NAME} --ignore-not-found=true

                sed -e "s/dev/${BRANCH_NAME}/g" -e "s/localhost:5000\\/total-site:dev/${REGISTRY}\\/total-site:${BUILD_TAG}/g" deployment.yaml | kubectl apply -f -
                sed "s/dev/${BRANCH_NAME}/g" service.yaml | kubectl apply -f -
                sed -e "s/dev/${BRANCH_NAME}/g" -e "s/dev.total-space.online/${BRANCH_NAME}.total-space.online/g" ingress.yaml | kubectl apply -f -
                """
            }
        }
    }
}
