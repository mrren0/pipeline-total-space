podTemplate(
    containers: [
        containerTemplate(
            name: 'kaniko',
            image: 'gcr.io/kaniko-project/executor:latest',
            command: ["/busybox/cat"],
            args: ["-"],
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

            stage('Build and Push Docker Image via Kaniko') {
                steps {
                    container('kaniko') {
                        sh '''
                        mkdir -p /workspace/site/target
                        cp -r site/target /workspace/site/target
                        cp Dockerfile /workspace/Dockerfile

                        /kaniko/executor \
                          --dockerfile=/workspace/Dockerfile \
                          --context=/workspace \
                          --destination=localhost:5000/total-site:${BUILD_TAG} \
                          --insecure \
                          --skip-tls-verify
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
