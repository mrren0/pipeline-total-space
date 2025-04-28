podTemplate(
    containers: [
        containerTemplate(
            name: 'docker',
            image: 'docker:dind',
            privileged: true,
            args: '--host=tcp://127.0.0.1:2375 --registry-mirror=https://mirror.gcr.io --insecure-registry=registry.ci.svc.cluster.local:5000',
            ttyEnabled: true
        ),
        containerTemplate(
            name: 'kubectl',
            image: 'bitnami/kubectl:1.27.13',
            command: 'cat',
            ttyEnabled: true
        )
    ]
) {
    node(POD_LABEL) {

        def REGISTRY = "registry.ci.svc.cluster.local:5000"
        def IMAGE_NAME = "total-site"
        def RAW_BRANCH = env.BRANCH_NAME ?: "master"
        def BRANCH = RAW_BRANCH.replaceAll('[^a-zA-Z0-9-]', '-').toLowerCase()
        def BUILD_TAG = "${BRANCH}-${new Date().format('yyyyMMdd-HHmmss')}"

        stage('Checkout') {
            echo "Branch detected: ${RAW_BRANCH}, normalized: ${BRANCH}"

            dir('site') {
                git branch: env.BRANCH_NAME ?: "master", url: 'https://github.com/mrren0/site-total-space.git'
            }

            sh 'ls -la'
            sh 'ls -la site'
        }

        stage('Build Maven') {
            dir('site') {
                withMaven(maven: 'maven-3.9.9') {
                    sh 'mvn clean package'
                }
            }
        }

        stage('Build and Push Docker Image') {
            container('docker') {
                sh """
                docker version
                cd site
                docker build -t ${REGISTRY}/${IMAGE_NAME}:${BUILD_TAG} .
                docker push ${REGISTRY}/${IMAGE_NAME}:${BUILD_TAG}
                """
            }
        }

        stage('Deploy to Kubernetes') {
            container('kubectl') {
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
