pipeline {
  agent any

  stages {

    stage('Checkout') {
      steps {
        git branch: 'main',
            url: 'https://github.com/spring-projects/spring-petclinic.git'
      }
    }

    stage('Unit Tests') {
      steps {
        sh './mvnw test'
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
              -Dsonar.sources=src
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

  post {
    always {
      echo "✅ Spring PetClinic pipeline completed"
    }
  }
}
