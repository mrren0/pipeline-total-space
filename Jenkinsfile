pipeline {
    agent { node { label 'deploy' } } // <- используем обычную Jenkins-ноду

    environment {
        REGISTRY = "registry.ci.svc.cluster.local:5000"
        IMAGE_NAME = "total-site"
        RAW_BRANCH = "${env.BRANCH_NAME ?: 'master'}"
        BRANCH = "${RAW_BRANCH.replaceAll('[^a-zA-Z0-9-]', '-').toLowerCase()}"
        BUILD_TAG = "${BRANCH}-${new Date().format('yyyyMMdd-HHmmss')}"
        KUBECONFIG = "/var/lib/jenkins/.kube/config"
    }

    stages {
        stage('Checkout') {
            steps {
                echo "Branch: ${env.BRANCH}, Tag: ${env.BUILD_TAG}"
                dir('site') {
                    git branch: "${env.RAW_BRANCH}", url: 'https://github.com/mrren0/site-total-space.git'
                }
            }
        }

        stage('Build Maven') {
            steps {
                dir('site') {
                    withMaven(maven: 'maven-3.9.9') {
                        sh 'mvn clean package'
                    }
                }
            }
        }

        stage('Build & Push Docker Image') {
            steps {
                dir('site') {
                    sh """
                        docker build -t ${REGISTRY}/${IMAGE_NAME}:${BUILD_TAG} .
                        docker push ${REGISTRY}/${IMAGE_NAME}:${BUILD_TAG}
                    """
                }
            }
        }

        stage('Deploy to K8s') {
            steps {
                dir('site') {
                    sh """
                        kubectl create namespace ${BRANCH} --dry-run=client -o yaml | kubectl apply -f -
                        kubectl delete deployment total-site -n ${BRANCH} --ignore-not-found=true
                        kubectl delete service total-site -n ${BRANCH} --ignore-not-found=true
                        kubectl delete ingress total-site -n ${BRANCH} --ignore-not-found=true

                        sed -e "s/dev/${BRANCH}/g" -e "s|localhost:5000/total-site:dev|${REGISTRY}/${IMAGE_NAME}:${BUILD_TAG}|g" deployment.yaml | kubectl apply -f -
                        sed "s/dev/${BRANCH}/g" service.yaml | kubectl apply -f -
                        sed -e "s/dev/${BRANCH}/g" -e "s/dev.total-space.online/${BRANCH}.total-space.online/g" ingress.yaml | kubectl apply -f -
                    """
                }
            }
        }
    }
}
