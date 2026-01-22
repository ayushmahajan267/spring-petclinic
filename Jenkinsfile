pipeline {
  agent any

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
        sh 'docker build -t spring-petclinic:latest .'
      }
    }

    stage('Trivy Image Scan') {
      steps {
        sh '''
          trivy image \
            --severity HIGH,CRITICAL \
            --ignore-unfixed \
            spring-petclinic:latest
        '''
      }
    }
  }
   stage('Push Image to AWS ECR') {
      steps {
        sh '''
          echo "🔐 Logging in to Amazon ECR..."
          aws ecr get-login-password --region us-east-1 \
          | docker login --username AWS \
            --password-stdin 079662785620.dkr.ecr.us-east-1.amazonaws.com

          echo "🏷️ Tagging Docker image..."
          docker tag spring-petclinic:latest \
            079662785620.dkr.ecr.us-east-1.amazonaws.com/spring-petclinic:latest

          echo "🚀 Pushing image to ECR..."
          docker push 079662785620.dkr.ecr.us-east-1.amazonaws.com/spring-petclinic:latest
        '''
      }
    }
  }
  post {
    always {
      echo "✅ Spring PetClinic pipeline completed"
    }
  }
}
