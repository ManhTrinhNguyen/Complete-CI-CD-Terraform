// library identifier: 'jenkins-shared-library@main', retriever: modernSCM(
//     [$class: 'GitSCMSource',
//      remote: 'https://github.com/ManhTrinhNguyen/Share_Library_Exercise.git',
//      credentialsId: 'Github_Credential'
//     ]
// )

pipeline {   
    agent any
    tools {
        gradle 'gradle-8.14'
    }

    environment {
      ECR_URL = "565393037799.dkr.ecr.us-west-1.amazonaws.com"
      ECR_REPO = "${ECR_URL}/java-app"
    }

    stages {
        stage("Version Increment Dynamic"){
            steps {
                script {
                    echo 'Increase Patch Version ....'

                    sh 'gradle patchVersionUpdate'

                    def version = readProperties(file: 'version.properties')

                    env.IMAGE_NAME = "${ECR_REPO}:${version['major']}.${version['minor']}.${version['patch']}"

                    echo "${env.IMAGE_NAME}"
                }
            }
        }

        stage("Build Jar") {
          steps {
            script {
              echo "Build Gradle Jar ...."

              sh 'gradle clean build'
            }
          }
        }

        stage("Build Docker Image") {
          steps {
            script {
              echo "Build Docker Image ...."

              sh "docker build -t ${env.IMAGE_NAME} ."
            }
          }
        }

        stage("Login to ECR") {
          steps {
            script {
              withCredentials([
                usernamePassword(credentialsId: 'AWS_Credential', usernameVariable: 'USER', passwordVariable: 'PWD')
              ]){
                sh "echo ${PWD} | docker login --username ${USER} --password-stdin ${ECR_URL}"

                echo "Login successfully"
              }
            }
          }
        }

        stage("Push Docker Image to ECR") {
          steps {
            script {
              sh "docker push ${IMAGE_NAME}"
              echo "Push Image Success ....."
            }
          }
        }

        stage("Provision Server"){
          environment{
            AWS_ACCESS_KEY_ID = credentials('Aws_Access_Key_Id')
            AWS_SECRET_ACCESS_KEY = credentials('Aws_Secret_Access_Key')
            TF_VAR_env_prefix = "test"
          }

          steps{
            script {
              dir('terraform') {
                sh 'terraform init'
                sh 'terraform apply --auto-approve'

                // Capture the EC2 public IP output from Terraform
                def ec2_public_ip = EC2_PUBLIC_IP = sh(
                script: "terraform output ec2_public_ip",
                returnStdout: true 
                ).trim() 

                // Set environment variable for use in later stages if needed
                env.EC2_PUBLIC_IP = ec2_public_ip
              }
            }
          }
        }

        stage("Deploy with Kubernetes") {
          environment{
            AWS_ACCESS_KEY_ID = credentials('Aws_Access_Key_Id')
            AWS_SECRET_ACCESS_KEY = credentials('Aws_Secret_Access_Key')
            APP_NAME = "java-app"
          }
          steps {
            script {
              
            }
          }
        }

        stage("Commit to Git") {
          steps {
            script {
              withCredentials([
                usernamePassword(credentialsId: 'Github_Credential', usernameVariable: 'USER', passwordVariable: 'PWD')
              ]){
                // To set configuration that kept in .git folder and global configuration in git .
                // I want to set git config Global I can put a flag --global
                sh 'git config --global user.email "jenkin@gmail.com"' // If there is no User Email at all, Jenkin will complain when commiting changes . It will say there is no email that was detected to attach to as a metadata to that commit
                sh 'git config --global user.name "Jenkins"'

                // Set Origin access
                sh "git remote set-url origin https://${USER}:${PWD}@github.com/ManhTrinhNguyen/AWS-EKS-exercise.git"

                sh "git add ."
                sh 'git commit -m "ci: version bump"'
                sh 'git push origin HEAD:main'
              }
            }
          }
        }
    }
} 
