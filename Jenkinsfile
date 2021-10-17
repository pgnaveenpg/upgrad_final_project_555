pipeline {
  environment {
    imagename = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${BUILD_NAME}"
    BUILD_NAME = 'upgrad_project_555'
    IMAGE_TAG = "$BUILD_NUMBER"
    AWS_DEFAULT_REGION = "us-east-1"
    AWS_ACCOUNT_ID="064349442911"
    dockerRun = "docker run -p 8080:8081 -d --name node-app $imagename:$IMAGE_TAG"
    dockerKill= "docker rm -f node-app"

  }
  agent any
  stages {
    stage('Cloning Git Repo') {
      steps {
        checkout([$class: 'GitSCM', branches: [[name: '*/main']], extensions: [], userRemoteConfigs: [[credentialsId: 'Personal_Access_Token', url: 'https://github.com/pgnaveenpg/upgrad_final_project_555.git']]]) 
      }
    }
    stage('Building Docker image') {
      steps{
        script {
          dockerImage = docker.build "${imagename}:${IMAGE_TAG}"
        }
      }
    }
    
    stage('Pushing to ECR') {
     steps{  
         script {
                sh "aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com"
                sh "docker push ${imagename}:${IMAGE_TAG}"
         }
        }
      }

    stage('Remove Unused docker image') {
      steps{
        sh "docker rmi $imagename:$IMAGE_TAG"
      }
    }
    
    stage('Run Container on Dev Server'){
        steps{
          sshagent(['SSH_Cred_For_App_Server']) {
          sh "ssh -o StrictHostKeyChecking=no ubuntu@10.0.3.125 ${dockerKill}"
          sh "ssh -o StrictHostKeyChecking=no ubuntu@10.0.3.125 ${dockerRun}"
         }
     }
   }

    
  }  
}
