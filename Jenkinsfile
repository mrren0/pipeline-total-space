podTemplate(
    containers: [
        containerTemplate(
            name: 'docker',
            image: 'docker:dind',
            privileged: true,
            args: '--host=tcp://127.0.0.1:2375 --registry-mirror=https://mirror.gcr.io',
            ttyEnabled: true
        )
    ]
) {
    node(POD_LABEL) {

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
                    script {
                        RAW_BRANCH = env.BRANCH_NAME ?: "master"
                        BRANCH = RAW_BRANCH.replaceAll('[^a-zA-Z0-9-]', '-').toLowerCase()
                        BUILD_TAG = "${BRANCH}-${new Date().format('yyyyMMdd-HHmmss')}"
                        echo "Branch detected: ${RAW_BRANCH}, normalized: ${BRANCH}"
                    }

                    dir('site') {
                        git branch: env.BRANCH_NAME ?: "master", url: 'https://github.com/mrren0/site-total-space.git'
                    }

                    sh 'ls -la'
                    sh 'ls -la site'
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

            stage('Build and Push Docker Image') {
                steps {
                    container('docker') {
                        sh '''
                        docker version
                        cp Dockerfile site/
                        cd site
                        docker build -t localhost:5000/total-site:${BUILD_TAG} .
                        docker push localhost:5000/total-site:${BUILD_TAG}
                        '''
                    }
                }
            }

            stage('Deploy to Kubernetes') {
                steps {
                    sh """
                    kubectl create namespace ${BRANCH} --dry-run=client -o yaml | kubectl apply -f -

                    kubectl delete deployment total-site -n ${BRANCH} --ignore-not-found=true
                    kubectl delete service total-site -n ${BRANCH} --ignore-not-found=true
                    kubectl delete ingress total-site -n ${BRANCH} --ignore-not-found=true

                    sed -e "s/dev/${BRANCH}/g" -e "s/localhost:5000\\/total-site:dev/localhost:5000\\/total-site:${BUILD_TAG}/g" deployment.yaml | kubectl apply -f -
                    sed "s/dev/${BRANCH}/g" service.yaml | kubectl apply -f -
                    sed -e "s/dev/${BRANCH}/g" -e "s/dev.total-space.online/${BRANCH}.total-space.online/g" ingress.yaml | kubectl apply -f -
                    """
                }
            }
        }
    }
}
