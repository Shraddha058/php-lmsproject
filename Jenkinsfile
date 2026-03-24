pipeline {
  agent any
  environment {
    IMAGE_NAME = "marketing-service"
    IMAGE_TAG = "${env.BUILD_NUMBER}"
  }
  stages {
    stage("Checkout") { steps { checkout scm } }
    stage("Build") { steps { sh "docker build --target runtime -t ${IMAGE_NAME}:${IMAGE_TAG} ." } }
    stage("Test") { steps { sh "docker run --rm ${IMAGE_NAME}:${IMAGE_TAG} php -m | grep -E 'pdo_mysql|mbstring|intl'" } }
    stage("Push") {
      when { branch "main" }
      steps {
        sh "echo 'Configure docker login and push commands here for your registry.'"
      }
    }
  }
  post { always { sh "docker image rm -f ${IMAGE_NAME}:${IMAGE_TAG} || true" } }
}
