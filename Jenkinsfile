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
        sh """
          docker build -t ${ECR_REPO}:${IMAGE_TAG} .
        """
      }
    }

    stage('Trivy Image Scan') {
      steps {
        sh """
          trivy image \
            --severity HIGH,CRITICAL \
            --ignore-unfixed \
            ${ECR_REPO}:${IMAGE_TAG}
        """
      }
    }

    stage('Push Image to AWS ECR') {
      steps {
        sh """
          aws ecr get-login-password --region ${AWS_REGION} \
          | docker login --username AWS \
            --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

          docker tag ${ECR_REPO}:${IMAGE_TAG} \
            ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}

          docker tag ${ECR_REPO}:${IMAGE_TAG} \
            ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:latest

          docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}
          docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:latest
        """
      }
    }
    stage('Blue-Green Deployment') {
      steps {
          sshagent(['deploy-ec2-ssh']) {
              sh '''
              ssh ubuntu@172.31.21.49 '
                set -e
  
                IMAGE=079662785620.dkr.ecr.us-east-1.amazonaws.com/spring-petclinic:latest
                ACTIVE=$(cat /etc/petclinic-active | cut -d= -f2)
  
                if [ "$ACTIVE" = "BLUE" ]; then
                  NEW=GREEN
                  NEW_PORT=8082
                else
                  NEW=BLUE
                  NEW_PORT=8081
                fi
  
                echo "Deploying $NEW on port $NEW_PORT"
                
                aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 079662785620.dkr.ecr.us-east-1.amazonaws.com
                
                docker pull $IMAGE
                
                echo "Checking if port $NEW_PORT is already in use..."

                EXISTING_CONTAINER=$(docker ps --filter "publish=$NEW_PORT" --format "{{.Names}}")
                
                if [ -n "$EXISTING_CONTAINER" ]; then
                  echo "Port $NEW_PORT is used by $EXISTING_CONTAINER. Stopping it..."
                  docker stop $EXISTING_CONTAINER
                  docker rm $EXISTING_CONTAINER
                fi

                docker run -d \
                  --name petclinic-$NEW \
                  --restart unless-stopped \
                  -p $NEW_PORT:8080 \
                  $IMAGE
  
                sleep 20
  
                curl -f http://localhost:$NEW_PORT/actuator/health
  
                sudo sed -i "s/server 127.0.0.1:808[12];/server 127.0.0.1:$NEW_PORT;/" /etc/nginx/sites-available/default
                sudo systemctl reload nginx
  
                echo ACTIVE=$NEW | sudo tee /etc/petclinic-active
              '
              '''
          }
      }
    }

    stage('CD - Deploy to EC2') {
      steps {
        sshagent(['petclinic-ec2-ssh']) {
          sh """
            ssh -o StrictHostKeyChecking=no ubuntu@34.198.128.20 '
              docker stop petclinic-app || true
              docker rm petclinic-app || true
              docker pull ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:latest
              docker run -d \
                -p 8080:8080 \
                --name petclinic-app \
                --memory="2g" \
                ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:latest
            '
          """
        }
      }
    }

  }

  post {
    always {
      echo "✅ Spring PetClinic CI + DevSecOps pipeline completed successfully"
    }
  }
}
