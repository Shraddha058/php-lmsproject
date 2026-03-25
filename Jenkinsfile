// diff --git a/c:\Users\st892\OneDrive\Desktop\lmsproject\Jenkinsfile b/c:\Users\st892\OneDrive\Desktop\lmsproject\Jenkinsfile
// --- a/c:\Users\st892\OneDrive\Desktop\lmsproject\Jenkinsfile
// +++ b/c:\Users\st892\OneDrive\Desktop\lmsproject\Jenkinsfile
// @@ -2,14 +2,59 @@
   agent any
+
  options { disableConcurrentBuilds() }
+
   environment {
-    IMAGE_NAME = "marketing-service"
-    IMAGE_TAG = "${env.BUILD_NUMBER}"
+    IMAGE_NAME       = "marketing-service"
+    IMAGE_TAG        = "${env.BUILD_NUMBER}"
+    AWS_REGION       = "us-east-1"              // update to your region
+    AWS_ACCOUNT_ID   = "123456789012"           // set to your account
+    ECR_REPO         = "marketing-service"      // existing ECR repo name
+    K8S_CLUSTER      = "marketing-eks"          // EKS cluster name
+    K8S_NAMESPACE    = "marketing"
+    K8S_DEPLOYMENT   = "marketing-service"      // Deployment metadata.name
+    CONTAINER_NAME   = "app"                    // container name inside the Deployment
+    IMAGE_URI        = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}"
   }
+
   stages {
-    stage("Checkout") { steps { checkout scm } }
-    stage("Build") { steps { sh "docker build --target runtime -t ${IMAGE_NAME}:${IMAGE_TAG} ." } }
-    stage("Test") { steps { sh "docker run --rm ${IMAGE_NAME}:${IMAGE_TAG} php -m | grep -E 'pdo_mysql|mbstring|intl'" } }
-    stage("Push") {
+    stage("Checkout") {
+      steps { checkout scm }
+    }
+
+    stage("Build") {
+      steps { sh "docker build --target runtime -t ${IMAGE_NAME}:${IMAGE_TAG} ." }
+    }
+
+    stage("Test") {
+      steps { sh "docker run --rm ${IMAGE_NAME}:${IMAGE_TAG} php -m | grep -E 'pdo_mysql|mbstring|intl'" }
+    }
+
+    stage("Push to ECR") {
+      when { branch "main" }
+      steps {
+        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-jenkins']]) {
+          sh '''
+            aws ecr describe-repositories --repository-names $ECR_REPO --region $AWS_REGION >/dev/null 2>&1 || \
+              aws ecr create-repository --repository-name $ECR_REPO --region $AWS_REGION
+
+            aws ecr get-login-password --region $AWS_REGION \
+              | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
+
+            docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${IMAGE_URI}
+            docker push ${IMAGE_URI}
+          '''
+        }
+      }
+    }
+
+    stage("Deploy to EKS") {
       when { branch "main" }
       steps {
-        sh "echo 'Configure docker login and push commands here for your registry.'"
+        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-jenkins']]) {
+          sh '''
+            aws eks update-kubeconfig --region $AWS_REGION --name $K8S_CLUSTER
+            kubectl -n $K8S_NAMESPACE set image deployment/$K8S_DEPLOYMENT $CONTAINER_NAME=${IMAGE_URI}
+            kubectl -n $K8S_NAMESPACE rollout status deployment/$K8S_DEPLOYMENT --timeout=2m
+          '''
+        }
       }
@@ -17,3 +62,8 @@
   }
-  post { always { sh "docker image rm -f ${IMAGE_NAME}:${IMAGE_TAG} || true" } }
+
+  post {
+    always {
+      sh "docker image rm -f ${IMAGE_NAME}:${IMAGE_TAG} ${IMAGE_URI} || true"
+    }
+  }
 }
