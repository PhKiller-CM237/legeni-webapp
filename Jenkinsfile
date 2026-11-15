pipeline {
    agent any
    parameters {
        booleanParam(name: 'PUSH', defaultValue: false, description: 'Publier avec le credential dockerhub')
        string(name: 'DOCKERHUB_ID', defaultValue: '', description: 'Identifiant Docker Hub')
    }
    environment {
        VERSION = "1.0.$BUILD_NUMBER"
        IMAGE = 'legeni-webapp'
        TEST_CONTAINER = "tp35-test-$BUILD_NUMBER"
    }
    options { timestamps(); disableConcurrentBuilds(); timeout(time: 30, unit: 'MINUTES') }
    stages {
        stage('Tests unitaires') { steps { sh 'docker build --target test -t "$IMAGE:test" .' } }
        stage('Build image') {
            steps {
                sh 'docker build --build-arg APP_VERSION="$VERSION" --label org.opencontainers.image.revision="$GIT_COMMIT" -t "$IMAGE:$VERSION" .'
                sh 'printf "%s\\n" "$IMAGE:$VERSION" > tag.txt'
            }
        }
        stage('Acceptance') {
            steps {
                sh '''
                    docker run -d --name "$TEST_CONTAINER" "$IMAGE:$VERSION"
                    for i in $(seq 1 30); do
                        if docker exec "$TEST_CONTAINER" python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/health')"; then break; fi
                        sleep 1
                    done
                    docker exec "$TEST_CONTAINER" python -c "import urllib.request,json; d=json.load(urllib.request.urlopen('http://localhost:5000/api/info')); assert d['version']=='$VERSION',d"
                '''
            }
        }
        stage('Push Docker Hub') {
            when { expression { params.PUSH && !env.CHANGE_ID && (!env.BRANCH_NAME || env.BRANCH_NAME == 'main') } }
            steps {
                script { if (!params.DOCKERHUB_ID?.trim()) { error('DOCKERHUB_ID requis') } }
                withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'DH_USER', passwordVariable: 'DH_TOKEN')]) {
                    sh '''
                        export DOCKER_CONFIG="$WORKSPACE/.docker-tp"
                        trap 'rm -rf "$DOCKER_CONFIG"' EXIT
                        printf '%s' "$DH_TOKEN" | docker login -u "$DH_USER" --password-stdin
                        docker tag "$IMAGE:$VERSION" "$DOCKERHUB_ID/$IMAGE:$VERSION"
                        docker push "$DOCKERHUB_ID/$IMAGE:$VERSION"
                    '''
                }
            }
        }
    }
    post {
        always {
            sh 'docker rm -f "$TEST_CONTAINER" >/dev/null 2>&1 || true'
            archiveArtifacts artifacts: 'tag.txt', allowEmptyArchive: true
        }
    }
}
