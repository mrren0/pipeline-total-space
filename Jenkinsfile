pipeline {
    agent any
    options {
        // Отключаем автоматический checkout SCM, чтобы избежать конфликтов
        skipDefaultCheckout(true)
    }
    environment {
        REGISTRY = "registry.ci.svc.cluster.local:5000"
        IMAGE_NAME = "total-site"
        RAW_BRANCH = "${env.BRANCH_NAME ?: 'main'}" // Используем 'main' вместо 'master'
        BRANCH = "${RAW_BRANCH.replaceAll('[^a-zA-Z0-9-]', '-').toLowerCase()}"
        BUILD_TAG = "${BRANCH}-${new Date().format('yyyyMMdd-HHmmss')}"
        KUBECONFIG = "/var/lib/jenkins/.kube/config"
    }
    stages {
        stage('Debug') {
            steps {
                // Диагностика: выводим состояние директории и переменные
                sh 'ls -la'
                sh 'pwd'
                echo "Branch: ${RAW_BRANCH}, Build Tag: ${BUILD_TAG}"
            }
        }
        stage('Checkout SCM') {
            steps {
                // Очищаем и клонируем репозиторий
                checkout scm: [
                    $class: 'GitSCM',
                    branches: [[name: "${RAW_BRANCH}"]],
                    userRemoteConfigs: [[
                        url: 'https://github.com/mrren0/site-total-space.git',
                        credentialsId: 'github-credentials' // Укажите ID ваших credentials
                    ]],
                    extensions: [[$class: 'WipeWorkspace'], [$class: 'CloneOption', depth: 1, noTags: true, shallow: true]]
                ]
                // Проверяем, что клонирование прошло успешно
                sh 'git status'
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
        stage('Deploy to Kubernetes') {
            steps {
                dir('site') {
                    sh """
                        kubectl create namespace ${BRANCH} --dry-run=client -o yaml | kubectl apply -f -
                        kubectl delete deployment total-site -n ${BRANCH} --ignore-not-found
                        kubectl delete service total-site -n ${BRANCH} --ignore-not-found
                        kubectl delete ingress total-site -n ${BRANCH} --ignore-not-found

                        sed -e "s/dev/${BRANCH}/g" -e "s|localhost:5000/total-site:dev|${REGISTRY}/${IMAGE_NAME}:${BUILD_TAG}|g" deployment.yaml | kubectl apply -f -
                        sed "s/dev/${BRANCH}/g" service.yaml | kubectl apply -f -
                        sed -e "s/dev/${BRANCH}/g" -e "s/dev.total-space.online/${BRANCH}.total-space.online/g" ingress.yaml | kubectl apply -f -
                    """
                }
            }
        }
    }
    post {
        always {
            echo 'Pipeline completed.'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}