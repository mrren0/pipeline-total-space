pipeline {
    agent any

    tools {
        maven 'maven-3.9.9'
    }

    environment {
        REGISTRY = "localhost:5000"
        IMAGE_NAME = "total-site"
    }

    stages {
stage('Checkout') {
    steps {
        checkout scm
        script {
            RAW_BRANCH = env.BRANCH_NAME ?: "master"
            BRANCH = RAW_BRANCH.replaceAll('[^a-zA-Z0-9-]', '-').toLowerCase()
            BUILD_TAG = "${BRANCH}-${new Date().format('yyyyMMdd-HHmmss')}"
            echo "Branch detected: ${RAW_BRANCH}, normalized: ${BRANCH}"
        }
        sh 'ls -la'
    }
}


        stage('Build Maven') {
            steps {
                withMaven(maven: 'maven-3.9.9') {
                    sh 'mvn clean package'
                }
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
                kubectl create namespace ${BRANCH} --dry-run=client -o yaml | kubectl apply -f -

                kubectl delete deployment total-site -n ${BRANCH} --ignore-not-found=true
                kubectl delete service total-site -n ${BRANCH} --ignore-not-found=true
                kubectl delete ingress total-site -n ${BRANCH} --ignore-not-found=true

                sed -e "s/dev/${BRANCH}/g" -e "s/localhost:5000\\/total-site:dev/${REGISTRY}\\/total-site:${BUILD_TAG}/g" deployment.yaml | kubectl apply -f -
                sed "s/dev/${BRANCH}/g" service.yaml | kubectl apply -f -
                sed -e "s/dev/${BRANCH}/g" -e "s/dev.total-space.online/${BRANCH}.total-space.online/g" ingress.yaml | kubectl apply -f -
                """
            }
        }
    }
}
