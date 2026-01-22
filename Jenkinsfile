pipeline {
  agent any

  environment {
    AWS_REGION     = 'us-east-1'
    AWS_ACCOUNT_ID = '079662785620'
    ECR_REPO       = 'spring-petclinic'
    IMAGE_TAG      = "${BUILD_NUMBER}"
  }

  stages {

    stage('Checkout') {
      steps {
        git branch: 'main',
            url: 'https://github.com/ayushmahajan267/spring-petclinic.git'
      }
    }

    stage('Build (Skip Tests for CI)') {
      steps {
        sh 'mvn clean package -DskipTests'
      }
    }

    stage('SonarQube SAST') {
      steps {
        withSonarQubeEnv('SonarQube') {
          script {
            def scannerHome = tool 'SonarScanner'
            sh """
              ${scannerHome}/bin/sonar-scanner \
              -Dsonar.projectKey=spring-petclinic \
              -Dsonar.sources=src/main/java \
              -Dsonar.java.binaries=target/classes
            """
          }
        }
      }
    }

    stage('SonarQube Quality Gate') {
      steps {
        timeout(time: 10, unit: 'MINUTES') {
          waitForQualityGate abortPipeline: true
        }
      }
    }

    stage('Docker Build') {
      steps {
        sh '''
          docker build -t ${ECR_REPO}:${IMAGE_TAG} .
        '''
      }
    }

    stage('Trivy Image Scan') {
      steps {
        sh '''
          trivy image \
            --severity HIGH,CRITICAL \
            --ignore-unfixed \
            ${ECR_REPO}:${IMAGE_TAG}
        '''
      }
    }

    stage('Push Image to AWS ECR') {
      steps {
        sh '''
          echo "🔐 Logging in to Amazon ECR..."
          aws ecr get-login-password --region ${AWS_REGION} \
          | docker login --username AWS \
            --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

          echo "🏷️ Tagging Docker image..."
          docker tag ${ECR_REPO}:${IMAGE_TAG} \
            ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}

          echo "🚀 Pushing image to ECR..."
          docker push \
            ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}
        '''
      }
    }
  }

  post {
    always {
      echo "✅ Spring PetClinic pipeline completed successfully"
    }
  }
}
