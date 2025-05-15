- [Project Overview](#Project-Overview)

- [Setup Continuous Deployment with Jenkins](#Setup-Continuous-Deployment-with-Jenkins)

  - [Create Ubuntu Server on DigitalOcean](#Create-Ubuntu-Server-on-DigitalOcean) 

  - [Deploy Jenkins as a Docker Container](#Deploy-Jenkins-as-a-Docker-Container)
 
  - [Install Stage View Plugin](#Install-Stage-View-Plugin)
 
  - [Install Docker In Jenkins](#Install-Docker-In-Jenkins)
 
  - [Install Build tools in Jenkins](#[Install-Build-tools-in-Jenkins)
 
  - [Create Multi Branches Pipelines](#Create-Multi-Branches-Pipelines)
 
  - [Required field of Jenkins](#Required-field-of-Jenkins)
 
  - [Configure build tools in Jenkinsfile](#Configure-build-tools-in-Jenkinsfile)
 
  - [CI Stage](#CI-Stage)
    
    - [Increment Version Dynamically Stage](#Increment-Version-Dynamically-Stage)
   
    - [Build Jar Stage](#Build-Jar-Stage)

    - [Build Docker Image Stage](#Build-Docker-Image-Stage)
   
    - [Docker Login](#Docker-Login)
   
    - [Push Docker Image to ECR](#Push-Docker-Image-to-ECR)
   
    - [Make Jenkin commit and push to Repository](#Make-Jenkin-commit-and-push-to-Repository)
   
    - [Configure Webhook to Trigger CI Pipeline Automatically on Every Change](#Configure-Webhook-to-Trigger-CI-Pipeline-Automatically-on-Every-Change)
   
    - [Ignore Jenkins Commit for Jenkins Pipeline Trigger](#Ignore-Jenkins-Commit-for-Jenkins-Pipeline-Trigger)

- [Automate AWS Infrastructure](#Automate-AWS-Infrastructure)

  - [Overview](#Overview)
 
  - [VPC and Subnet](#VPC-and-Subnet)
 
  - [Route Table And Internet Gateway](#Route-Table-And-Internet-Gateway)
 
  - [Create new Route Table](#Create-new-Route-Table)
 
  - [Create Internet Gateway](#Create-Internet-Gateway)
 
  - [Subnet Association with Route Table](#Subnet-Association-with-Route-Table)
 
  - [Security Group](#Security-Group)
 
  - [Amazon Machine Image for EC2](#Amazon-Machine-Image-for-EC2)
 
  - [Create EC2 Instance](#Create-EC2-Instance)
 
  - [Automate create SSH key Pair](#Automate-create-SSH-key-Pair)
 
  - [Run entrypoint script to start Docker container](#Run-entrypoint-script-to-start-Docker-container)
 
  - [Extract to shell script](#Extract-to-shell-script)
 
- [Complete CI/CD with Terraform CD Stage](#Complete-CI-CD-with-Terraform-CD-Stage)

  - [Overview Provsion Terraform in CI CD Pipelines](#Overview-Provsion-Terraform-in-CI-CD-Pipelines)
 
    - [Create SSH key pair](#Create-SSH-key-pair)
   
    - [Install Terraform inside Jenkins Container](#Install-Terraform-inside-Jenkins-Container)
   
    - [Terraform Configuration File](#Terraform-Configuration-File)
 
  - [Provision Stage In Jenkinsfile](#Provision-Stage-In-Jenkinsfile)
 
  - [Deploy Stage in Jenkinsfile](#Deploy-Stage-in-Jenkinsfile)
 
    - [Docker compose](#Docker-compose)
   
    - [Set IP address of Jenkins to allow Jenkin to ssh to AWS](#Set-IP-address-of-Jenkins-to-allow-Jenkin-to-ssh-to-AWS)
   
    - [Docker Login to pull Docker Image](#Docker-Login-to-pull-Docker-Image)

 - [Remote State](#Remote-State)

   - [Configure Remote State](#Configure-Remote-State)
  
   - [Execute Jenkins Pipeline](#Execute-Jenkins-Pipeline)
  
- [Module my Terraform project](#Module-my-Terraform-project)

  - [Create module](#Create-module)
 
    - [VPC module](#VPC-module)
   
    - [Subnet module](#Subnet-module)
   
    - [Security Group module](#Security-Group-module)
   
    - [EC2 Module](#EC2-Module)
   
  - [Use Modules](#Use-Modules)
 
    - [For VPC Module](#For-VPC-module)
   
    - [For Subnet Module](#For-Subnet-Module)
   
    - [For Security Group Module](#For-Security-Group-Module)
   
    - [For EC2 Module](#For-EC2-Module)
   
    - [In root main.tf](#In-root-main-tf)
  
- [Terraform Best Practice](Terraform-Best-Practice) 


## Project Overview

This project demonstrates a **complete CI/CD pipeline** using **Terraform**, **Jenkins**, **Docker**, and **AWS**. It automates the provisioning of cloud infrastructure and deploys a Java application using industry-standard DevOps practices.

#### 🚀 Key Objectives

- Automate application build, versioning, and deployment using Jenkins.
- Provision AWS infrastructure (VPC, EC2, Security Groups) with Terraform.
- Deploy Dockerized apps to EC2 via Docker Compose.
- Use secure credentials and remote state management best practices.


#### 🔧 Technologies & Tools Used

| Category               | Tools & Services                                 |
|------------------------|--------------------------------------------------|
| CI/CD Pipeline         | Jenkins, Gradle, GitHub                          |
| Infrastructure as Code | Terraform                                        |
| Cloud Platform         | AWS (EC2, VPC, S3, ECR, IAM)                     |
| Containerization       | Docker, Docker Compose                           |
| Secrets Management     | Jenkins Credentials                              |
| State Management       | S3 Backend (Remote Terraform State + Versioning) |
| Automation             | Bash Scripting, User Data, SSH                   |


#### Key Features

✅ Multi-branch Jenkins pipeline integration

✅ Dynamic versioning with Gradle

✅ Docker image build & push to AWS ECR

✅ Secure secret injection with Jenkins credentials

✅ EC2 provisioning and app deployment via Terraform

✅ Remote Terraform state stored in S3 with versioning

✅ Full lifecycle automation from Git push to deployment


## Setup Continuous Deployment with Jenkins

#### Create Ubuntu Server on DigitalOcean 

Step 1 : Go to Digital ocean -> Create Droplet -> Choose Region and Capacity -> Create SSH key

Step 2 : To create SSH key :

 - In terminal : `ssh-keygen` . There will be .ssh/id_rsa and .ssh/id_rsa.pub . Then `cat .ssh/id_rsa.pub` take this content and put it into Digital ocean
   
    <img width="600" alt="Screenshot 2025-03-18 at 14 37 03" src="https://github.com/user-attachments/assets/49d7f9df-e2c3-4162-9a5e-7495435fd593" />


#### Deploy Jenkins as a Docker Container

Step 1 : Connect to Server : `ssh root@<IP-address>`

Step 2 : Create Firewall Rule to it

  - Add Custom Port 8080 : This is where Jenkin start . This is where I will expose it 
   
- Add Port 22 : To SSH

Step 3 : Install Docker : `apt install docker.io`

Step 4 : Install Jenkins : `docker run -p 8080:8080 -p 50000:50000 -d -v jenkins_home:/var/jenkins_home jenkins/jenkins:lts`

 - First 8080 Port : Where the browser access to (The server itself).
   
 - Second 8080 Port : Is the Port of the Container itsefl (Jenkins itself) 
   
 - Port 50000:50000 : This is where Jenkins Master and Worker nodes communicate . Jenkins can actually built and started as a Cluster if I have large Workloads that I am running with Jenkins
   
 - `-d` : Detach Mode. Run the cotainer in the background

 - `-v jenkins_home:/var/jenkins_home`: Mount volumes
        
   - Jenkins is just like Nexus, It will store a lot of data . When I configure Jenkins, Create User, Create Jobs to run, Install Plugin and so ons . All of these will be store as Data
     
   - jenkins_home : This folder doesn't exist yet (Name Volume references) . Docker will create a physical path on the server will store a data with that Name References
     
   - /var/jenkins_home : This is a Actual directory in Cotnainer (Inside Jenkins) that will store data

Step 5 : In the UI . First Access Jenkins will give me a path to get the Password . I will `docker exec -t <container-id> bash` go inside Jenkins and get the password

 - To check Volume that I create : `docker inspect volume jenkins_home`

#### Install Stage View Plugin

This Plugins help me see diffent stage defined in the UI . This mean Build Stage, Test, Deploy will displayed as separate stage in the UI 

Go to Available Plugin -> Stage View

#### Install Docker In Jenkins

Most of scenerio I will need to build Docker Image in Jenkins . That mean I need Docker Command in Jenkins . The way to do that is attaching a volume to Jenkins from the host file

In the Server (Droplet itself) I have Docker command available, I will mount Docker directory from Droplet into a Container as a volume . This will make Docker available inside the container

To do that I first need to kill current Container and create a new : `docker stop <container-id>`

Check the volume : `docker ls volume` . All the data from the container before will be persist in here and I can use that to create a new Container

Start a new container : `docker run -d -p 8080:8080 -p 50000:50000 -v jenkins_home:/var/jenkins_home -v /var/run/docker.sock:/var/run/docker.sock jenkins/jenkins:lts`

 - `/var/run/docker.sock:/var/run/docker.sock` : I mount a Docker from Droplet to inside Jenkins
   
Get inside Jenkins as Root : `docker exec -it -u 0 <container_id> bash`

Things need to fix :

 - `apt update` To update Package Manager

 - `apt install curl` : Install `curl`

 - `curl https://get.docker.com/ > dockerinstall && chmod 777 dockerinstall && ./dockerinstall` . With this Curl command Jenkins container is going to fetch the latest Version of Docker from official size so it can run inside the container, then I will set correct permission the run through the Install

 - Set correct Permission on docker.sock so I can run command inside the container as Jenkins User `chmod 666 /var/run/docker.sock`: docker.sock is a Unix socket file used by Docker daemon to communicate with Docker Client
   
#### Install Build tools in Jenkins

Go to Dashboard -> Manage Jenkins -> Choose Tools -> Add Gradle (Bcs in this project I use Gradle) -> Give it a name is `gradle-8.14`

#### Create Multi Branches Pipelines 

In Jenkins UI -> Dashboard -> New items -> Choose Multi branch Pipelines 

In the Configuration : 

 - Branch Source: Choose Git then add Github url into it

 - Credentials : To create my Github Credential -> Jenkins Dashboard -> Manage Jenkins -> Choose Credentials -> Choose Add Credentials -> Choose Username with Password -> Then give my Github user name and my Github password to it (Github password is a Github token)

 - Behaviors : Choose `Filter by name (with regular expression)` give it value `.*` this mean choose all the branch

 - Build Configuration : By Jenkins -> Script path : Jenkinsfile this mean Jenkins will look for the Jenkins from the Repo url I gave above

Now I have my Multi Branches Pipelines I can start building in the `Jenkinsfile`

### CI Stage 

CI include : 

 - Increment Version Dynamically Stage
 
 - Testing Stage
 
 - Build Jar Stage

 - Build Docker Image Stage

 - Login to ECR stage

 - Push Image to ECR

#### Required field of Jenkins 

`pipeline` : Must be top level

`agent any`: This build on any available Jenkins Agent . Agent can be a Node, it could be executable on that Node . This is more relevant when I have Jenkins Cluster with Master and Slaves where I have Window Nodes and Linux Nodes ....

`stages` : Where the whole work happen . I have many diffent Stages in Pipeline . Inside Stages I have Stage , Inside Stage I have steps to execute that Stage

#### Configure build tools in Jenkinsfile 

Before any Stages I need to configure build tools  that I use in this project . In this case I use Gradle 

```
pipeline {   
    agent any
    tools {
        gradle 'gradle-8.14'
    }
}
```

#### Increment Version Dynamically Stage 

To automatically Increase Version with Gradle Document (https://theekshanawj.medium.com/gradle-automate-application-version-management-with-gradle-4b97e1df84a3)

I want to be able to automatically increase that version inside my build . So When I commit changes to Jenkins, Jenkins build pipeline basically should increment the version and release a new application . This should all happen immediately .

After followed the Docs I have configured Dynamic Increase Version in Gradle :

 - To Increase Major Version : `gradle majorVersionUpdate`
   
 - To Increase Minor Version : `gradle minorVersionUpdate`
   
 - To Increase Patch Version : `gradle patchVersionUpdate`
   
 - To Realse : `gradlew releaseVersion` # Remove SNAPSHOT

Now In Jenkinsfile I will create a new Stage called `Version Increment Dynamic`

 - In this case I want to increase Patch version : `sh 'gradle patchVersionUpdate'` 

 - To read `version.properties` file in Gradle 
  
   - Install `Pipeline Utility Steps` plugin so I can use `readProperties(file: 'version.properties')`
  
   - `readProperties`, `writeProperties`, `readYaml`, `readJSON`, etc., are all inside this plugin.
  
 - After I have a Version values I can set `IMAGE_NAME` and put it in the ENV for the next Stage use `env.IMAGE_NAME = "${ECR_REPO}:${version['major']}.${version['minor']}.${version['patch']}"`

 - I also created the ENV for ECR_REPO :

   ```
   environment {
      ECR_REPO = "565393037799.dkr.ecr.us-west-1.amazonaws.com/java-app"
    }
   ```
The whole code will look like this : 

```
pipeline {   
    agent any
    tools {
        gradle 'gradle-8.14'
    }

    environment {
      ECR_REPO = "565393037799.dkr.ecr.us-west-1.amazonaws.com/java-app"
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
    }
} 
```

#### Build Jar Stage 

To build Gradle jar : `gradle clean build` 

 - I want to clean the previous stage and then build new one

The code will look like this : 

```
stage("Build Jar") {
  steps {
    script {
      echo "Build Gradle Jar ...."

      sh 'gradle clean build'
    }
  }
}
```

#### Build Docker Image Stage 

I have Dockefile created in my Repository 

```
FROM openjdk:17.0.2-jdk
EXPOSE 8080
RUN mkdir /opt/app
COPY build/libs/bootcamp-docker-java-mysql-project-1.0-SNAPSHOT.jar /opt/app
WORKDIR /opt/app
CMD ["java", "-jar", "bootcamp-docker-java-mysql-project-1.0-SNAPSHOT.jar"]
```

But I want my Dockerfile to read Version dynamically so I will put a `*` in a version like this : 

```
FROM openjdk:17.0.2-jdk
EXPOSE 8080
RUN mkdir /opt/app
COPY build/libs/bootcamp-docker-java-mysql-project-*-SNAPSHOT.jar /opt/app
WORKDIR /opt/app

CMD java -jar bootcamp-docker-java-mysql-project-*-SNAPSHOT.jar
```

To build docker Image : `docker build -t <ecr-repo>/<app-name>:<app-version>`

  - I need to tag ECR repo endpoint bcs When I want to push docker image into ECR, Docker know to endpoint that it need to push to image to

  - In the `Version Increment Dynamic Stage` I already have a IMAGE_NAME with a ECR repo tags I can use it as a ENV

The whole code will look like this :

```
stage("Build Docker Image") {
  steps {
    script {
      echo "Build Docker Image"

      sh "docker build -t ${env.IMAGE_NAME} ."
    }
  }
}
```

#### Docker Login 

I want to login to ECR for Jenkins to able to pull image from there .

I need to configure AWS ECR credentials on in Jenkins : 

 - To get AWS ECR Password : `aws ecr get-login-password --region us-west-1`

 - Username would be : `AWS`

 - Now in Jenkins I will go to Dashboard Credentials and choose Username with Password

 - !!! NOTE : AWS Credentails only available 12 hours. I have to re-generate a new one after 12 hours

In order to use those credentials I will use `withCredentials([]){}` plugin to pull Username and Password from Credential

The Code would look like this : 

```
stage("Login to ECR") {
  steps {
    script {
      withCredentials([
        usernamePassword(credentialsId: 'AWS_Credential', usernameVariable: 'USER', passwordVariable: 'PWD')
      ]){
        sh "echo ${PWD} | docker login --username ${USER} --password-stdin 565393037799.dkr.ecr.us-west-1.amazonaws.com"

        echo "Login successfully"
      }
    }
  }
}
```

#### Push Docker Image to ECR 

In order to push Docker Image to ECR I must login to ECR successfully . That mean the previous Stage must success before this Stage 

The Code will look like this :

```
stage("Push Docker Image to ECR") {
  steps {
    script {
      sh "docker push ${IMAGE_NAME}"
    }
  }
}
```

#### Make Jenkin commit and push to Repository

Everytime pipeline run in Jenkins, it will create a new Image Version, the `versions.properties` in my Gradle project automatically increase, I want to make Jenkin commit and push to the Repository, so when my teammate I want use it, first they have to pull the newest code 

I will add the Git commit Stage :

 - I need credentials to login to Github . Now in Jenkins I will go to Dashboard Credentials and choose Username with Password 

 - In order to use those credentials I will use `withCredentials([]){}` plugin to pull Username and Password from Credential

The code will look like this : 

```
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
        sh "git remote set-url origin http://${USER}:${PASSWORD}@github.com/ManhTrinhNguyen/AWS-EKS-exercise.git"

        sh "git add ."
        sh 'git commit -m "ci: version bump"'
        sh 'git push origin HEAD:main'
      }
    }
  }
}
```

When Jenkins check outs up to date code in order to start a pipeline it doesn't check out the Branch, it checkout the commit hash (the last commit from that branch). That is the reason why I need to do `sh 'git push origin HEAD:<job-branch>'`. So it saying that push all the commits that we have made inside this commit Branch inside this Jenkin Job.

#### Configure Webhook to Trigger CI Pipeline Automatically on Every Change

**This way for single Pipeline in Github**

I want to trigger build automatically whenever commit is push to Repository 

Other ways to trigger build scheduling. For example I want this build to run every 2 hours 

Go to Github repo -> Settings -> Webhooks -> Click Add Webhooks -> Payload URL : `http://<my-jenkins-domain>/github-webhook/` -> Content type: application/json -> Choose just push event -> Save Webhook 

**This way for multiple Branches Pipeline**

I need a Plugin call Multibranch Scan Webhook Trigger 

Once installed I have `Scan by Webhook` in Multibranch Configuration -> Choose Scan by Webhook, then I have Trigger Token (This is a token that I can name whatever I want this Token will be use for the communication between Gitlab and Jenkin, or Github and Jenkins ...)

To use this token I will go to Github Repo -> Choose Webhook (Webhook is basically same Integration above) . 

The way it work is It will tell Github to send the notifications on specific URL using that token, and when Jenkins receive that a request it will trigger multibranch pipeline which has scan by webhook configured for that specific token . I don't need secret token 

#### Ignore Jenkins Commit for Jenkins Pipeline Trigger

I need someway to detect that commit was made by Jenkins not the Developer and Ignore the Trigger when the Commit from Jenkins 

I need the Plugin call `Ignore Commiter Strategy`

Go to my Pipeline Configuration -> Inside the Branch Sources I see the Build Strategy (This is an option just got through the plugin) -> In this option I will put the email address of the committer that I want to Ignore . I can provide a list of email

## Automate AWS Infrastructure

#### Overview 

I will Deploy EC2 Instances on AWS and I will run a simple Docker Container on it 

However before I create that Instance I will Provision AWS Infrastructure for it

To Provision AWS Infrastructure :

 - I need create custom VPC

 - Inside VPC I will create Subnet in one of AZs, I can create multiple Subnet in each AZ

 - Connect this VPC to Internet using Internet Gateway on AWS . Allow traffic to and from VPC with Internet

 - And then In this VPC I will deploy an EC2 Instance

 - Deploy Nginx Docker container

 - Create SG (Firewall) in order to access the nginx server running on the EC2

 - Also I want to SSH to my Server. Open port for that SSH as well

**Terraform Best Pratice**: That I want to create the whole Infrastructure from sratch, I want to deploy everything that I need. And when I don't need it anymore later I can just remove it by using `terraform destroy` without touching the defaults created by AWS . 

#### VPC and Subnet 

To create VPC and Subnet in AWS I need `resources "aws_vpc"` and  `resources "aws_subnet"`

To create VPC, I need to define `cidr_block` like this : 

```
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tag = {
    Name: "any-name"
  }
}
```

I can extract value to `variables.tf` file and give value to it in `terraform.tfvars` .

```
main.tf

resource "aws_vpc" "my-vpc" {
  cidr_block = var.cidr_block

  tags = {
    Name: "${var.env_prefix}-vpc"
  }
}

----

variables.tf

variable "cidr_block" {}
variable "env_prefix" {}

----

terraform.tfvars

cidr_block = "10.0.0.0/16"
env_prefix = "dev"
```

To create Subnet I will define like this :

 - To get VPC ID `aws_vpc.<vpc-name>.id`

```
main.tf

resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.my-vpc.id # 
  cidr_block = var.subnet_cidr_block
  availability_zone = var.availability_zone

  tags = {
    Name = "${var.env_prefix}-subnet"
  }
}

---

variables.tf

variable "subnet_cidr_block" {}
variable "availability_zone" {}

---

terraform.tfvars

subnet_cidr_block = "10.0.10.0/24"
availability_zone = "us-west-1a"
```

After I have configured VPC and Subnet I can use `terraform apply --auto-approve` to provision it 

#### Route Table And Internet Gateway

**Route table** was generated by AWS for my newly VPC .  

Route table is Virtual Router in VPC . Route Table is just a set of rules that tell my Network where to send traffic 

 - Route table decide where to send network to within a VPC

 - When I click into Route Table in AWS UI . I see `Target : Local` and `Destination: 10.0.0.0/16` mean only route traffic inside my VPC with a range `10.0.0.0/16` .

 - !!! Important NOTE : Route table doesn't care about specific IP address like `10.0.1.15`. It work with CIDR Block, it based on where the destination IP falls, it decides which target (Gateway, endppint, NAT, etc..) to use

**Internet Gateway Target**: This mean this Route Table acutally handles or will handle all the traffic coming from the Internet and leaving the Internet

 - Basically I need the Internet Gateway Target in my Custom VPC so I can connect my VPC to the Internet

#### Create new Route Table

I will create a new Route Table with : 

 - Local Target : Connect within VPC

 - Internet Gateway: Connect to the Internet

 - By default the entry for the VPC internal routing is configured automatically . So I just need to create the Internet Gateway route

To create a Route Table `resource "aws_route_table" "myapp-route-table" {}`

 - I need to give `vpc_id` where is Route Table will create from (required)

 - Then I will put Route into my Route table (Internet Gateway, NAT, or Local) . Local is automatically created

 - My route table will look like this :

  ```
  resource "aws_route_table" "myapp-route-table" {
  vpc_id = aws_vpc.myapp-vpc.id

    route {
      cidr_block = "0.0.0.0/0" ## Destination . Any IP address can access to my VPC 
      gateway_id = aws_internet_gateway.myapp-igw.id ## This is a Internet Gateway for my Route Table 
    }

    tags = {
      Name = "${var.env_prefix}-rtb"
    }
  }
  ```

But I don't have IGW yet . Now I will go and create my IGW 

#### Create Internet Gateway

To create Internet Gateway : `resource "aws_internet_gateway" "myapp-igw" {}`

 - I need to give `vpc_id` where is IGW will create from (required)

  ```
  resource "aws_internet_gateway" "myapp-igw" {
    vpc_id = aws_vpc.myapp-vpc.id
  
    tags = {
      Name = "${var.env_prefix}-rtb"
    }
  }
  ```

**Recap**: I have configured VPC and Subnet inside VPC . I am connecting VPC to Internet Gateway and then I am configureing a new Route Table that I am creating in the VPC to route all the Traffic to and from using the Internet Gateway

!!! Best Practice : Create new components, instead of using default ones

#### Subnet Association with Route Table

I have created a Route Table inside my VPC. However I need to associate Subnet with a Route Table so that Traffic within a Subnet also can handle by Route Table 

By default when I do not associate subnets to a route table they are automatically assigned or associated to the main route table in that VPC where the Subnet is running

To Associate Subnet : `resource "aws_route_table_association" "a-rtb-subnet" {}`

```
resource "aws_route_table_association" "a-rtb-subnet" {
  route_table_id = aws_route_table.myapp-route-table.id
  subnet_id = aws_subnet.myapp-subnet.id
}
```

**Best Practice** : is to create a new Route table instead of using a default one 

**Typical Best Practice Setup:**

 - Create a Public Route Table → route to Internet Gateway → associate with public subnets.

 - Create a Private Route Table → route to NAT Gateway → associate with private subnets.

 - Create an Internal Route Table → no external route → for database/backend subnets.

#### Security Group

When I deploy my virtual machine in the subnet, I want to be able to SSH into it at port 22 . As well as I want to accessing nginx web server that I deploy as a container, through the web browser so I want to open port 8080 so that I can access from the web browser

First I need `vpc_id`, so I have to associate the Security Group with the VPC so that Server inside that VPC can be associated with the Security Group and VPC ID 

Generally I have 2 type of rules: 

 - Traffic coming in inside the VPC called `Ingress` . For example When I SSH into EC2 or Access from the browser

   - The resone we have 2 Ports `from_port` and `to_port` It is bcs I can acutally configure a Range . For example If I want to open Port from 0 to 1000 I can do `from_port = 0` && and `to_port = 1000`

   - `cidr_blocks` : Sources who is allowed or which IP addresses are allowed to access to the VPC

   - For SSH accessing the server on SSH should be secure and not everyone allow to do it

   - If my IP address is dynamic (change alot) . I can configure it as a variable and access it or reference it from the variable value instead of hard coding . So I don't have to check the terraform.tfvars into the repository bcs this is the local variables file that I ignored . Bcs everyone can have their own copy of variable file and set their own IP address

 - Traffic outgoing call `egress` . The arrtribute for these are the same

   - Example of Traffic leaving the VPC is :

     - Installation : When I install Docker or some other tools on my Server these binaries need to be fetched from the Internet

     - Fetch Image From Docker Hub or somewhere else

To create SG : `resource "aws_security_group" "myapp-sg" {}`

```
resource "aws_security_group" "myapp-sg" {
  name = "myapp-sg"
  description = "Allow inbound traffic and all outbound traffic"
  vpc_id = aws_vpc.myapp-vpc.id 
}
```

To create Ingress rule : `resource "aws_vpc_security_group_ingress_rule" {}`

```
resource "aws_vpc_security_group_ingress_rule" "myapp-sg-ingress-ssh" {
  security_group_id = aws_security_group.myapp-sg.id 
  cidr_ipv4 = var.my_ip
  from_port = 22
  ip_protocol = "TCP"
  to_port = 22
}

resource "aws_vpc_security_group_ingress_rule" "myapp-sg-ingress-8080" {
  security_group_id = aws_security_group.myapp-sg.id 
  cidr_ipv4 = "0.0.0.0/0"
  from_port = 8080
  ip_protocol = "TCP"
  to_port = 8080
}
```

To create Egress rule : `resource "aws_vpc_security_group_egress_rule" "myapp-sg-egress" {}`

```
resource "aws_vpc_security_group_egress_rule" "myapp-sg-egress" {
  security_group_id = aws_security_group.myapp-sg.id 
  cidr_ipv4 = "0.0.0.0/0"
  ip_protocol = "-1"
}
```

#### Amazon Machine Image for EC2 

**Review** : I have a VPC that has a Subnet inside . Connect VPC to Internet using Internet Gate Way and configure it in the Route Table . I also have create Security Group that open Port 22, 8080

To get AWS Image for EC2 I use `data "aws_ami" "my_ami" {}`

 - `ami` : Is a Operating System Image . Values of this is a ID of the image `ami-065ab11fb3d0323d`

 - So Instead hard code `ami id` I will use `data` to fetch the Image ID

 - To get Owners got to EC2 -> Image AMIs -> paste the ami id image that I want to get owner from. I will see the owner on the tap

 - Then I have a `filter` . `filter` in data let me define the criteria for this query . Give me the most recent Image that are owned by Amazon that have the name that start with amzn2-ami-kernel (Or can be anything, any OS I like to filter) . In `filter {}` I have `name` attr that referencing which key I wants to filter on, and `values` that is a list

 - `Output` the aws_ami value to test my value is correct `output "aws_ami_id" { value = data.aws_ami.latest-amazon-linux-image }` . Then I will see terraform plan to see the output object . However with output is how I can actually validate what results I can getting with this data execution . After this I can get the AMI-ID and put it in ami

 - My `data "aws_ami" "my_ami" {}` look like this

  ```
  main.tf

  data "aws_ami" "amazon-linux-image" {

  owners = ["amazon"]
  most_recent = true 

  filter {
    name = "name"
    values =  ["al2023-ami-*-x86_64"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
    }
  }

  ---

  output.tf

  output "ami_id" {
    value = data.aws_ami.amazon-linux-image.id
  }
  ```

#### Create EC2 Instance

Now I have `aws_ami` image ID I can create EC2 Instance from that 

I can use `resource "aws_instance" ""` to create instance 

`ami` : Is my Instance image 

`instance_type`: I can choose `instance_type` like how much Resources I want 

Other Attribute is Optional like subnet id and security group id etc ... If I do not specify them explicitly, then the EC2 instance that we define here will acutally launched in a default VPC in one of the AZ in that Region in one of the Subnet . However I have create my own VPC and this EC2 end up in my VPC and be assign the Security Group that I created in my VPC .

To define specific Subnet : `subnet_id = aws_subnet.myapp-subnet-1.id`

To define specific SG : `vpc_security_group_ids = [aws_security_group.myapp-sg.id]`  To start the instance in 

`associate_public_ip_address = true`. I want to be able access this from the Browser and as well as SSH into it 

To define Availability Zone : `availability_zone`

I need the keys-pair (.pem file) to SSH to a server . Key pair allow me to SSH into the server by creating public private key pair or ssh key pair . AWS create Private Public Key Pair and I have the private part in this file .

 - To secure this file I will move it into my user .ssh folder : `mv ~/Downloads/server-key-pair-pem ~/.ssh/` and then restrict permission :`chmod 400 ~/.ssh/server-key-pair.pem`. This step is required bcs whenever I use a `.pem` doesn't a strict access aws will reject the SSH request to the server

My whole code will look like this : 

```
resource "aws_vpc" "myapp-vpc" {
  cidr_block = var.cidr_block

  tags = {
    Name: "${var.env_prefix}-vpc"
  }
}

resource "aws_subnet" "myapp-subnet" {
  vpc_id     = aws_vpc.myapp-vpc.id
  cidr_block = var.subnet_cidr_block
  availability_zone = var.availability_zone

  tags = {
    Name = "${var.env_prefix}-subnet"
  }
}

resource "aws_route_table" "myapp-route-table" {
  vpc_id = aws_vpc.myapp-vpc.id

  route {
    cidr_block = "0.0.0.0/0" ## Destination . Any IP address can access to my VPC 
    gateway_id = aws_internet_gateway.myapp-igw.id ## This is a Internet Gateway for my Route Table 
  }

  tags = {
    Name = "${var.env_prefix}-rtb"
  }
}

resource "aws_internet_gateway" "myapp-igw" {
  vpc_id = aws_vpc.myapp-vpc.id

  tags = {
    Name = "${var.env_prefix}-rtb"
  }
}

resource "aws_route_table_association" "a-rtb-subnet" {
  route_table_id = aws_route_table.myapp-route-table.id
  subnet_id = aws_subnet.myapp-subnet.id
}

resource "aws_security_group" "myapp-sg" {
  name = "myapp-sg"
  description = "Allow inbound traffic and all outbound traffic"
  vpc_id = aws_vpc.myapp-vpc.id 
}

resource "aws_vpc_security_group_ingress_rule" "myapp-sg-ingress-ssh" {
  security_group_id = aws_security_group.myapp-sg.id 
  cidr_ipv4 = var.my_ip
  from_port = 22
  ip_protocol = "TCP"
  to_port = 22

  tags = {
    Name = "${var.env_prefix}-ingress-ssh"
  }
}

resource "aws_vpc_security_group_ingress_rule" "myapp-sg-ingress-8080" {
  security_group_id = aws_security_group.myapp-sg.id 
  cidr_ipv4 = "0.0.0.0/0"
  from_port = 8080
  ip_protocol = "TCP"
  to_port = 8080

  tags = {
    Name = "${var.env_prefix}-ingress-8080"
  }
}

resource "aws_vpc_security_group_egress_rule" "myapp-sg-egress" {
  security_group_id = aws_security_group.myapp-sg.id 
  cidr_ipv4 = "0.0.0.0/0"
  ip_protocol = "-1"

  tags = {
    Name = "${var.env_prefix}-egress"
  }
}

data "aws_ami" "amazon-linux-image" {

  owners = ["amazon"]
  most_recent = true 

  filter {
    name = "name"
    values =  ["al2023-ami-*-x86_64"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "myapp" {
  ami = data.aws_ami.amazon-linux-image.id
  instance_type = var.instance_type
  subnet_id = aws_subnet.myapp-subnet.id 
  vpc_security_group_ids = [aws_security_group.myapp-sg.id]
  availability_zone = var.availability_zone

  associate_public_ip_address = true

  key_name = "terraform-exercise"
  tags = {
    Name = "${var.env_prefix}-myapp"
  }
}
```

----

```
terraform.tfvars

cidr_block = "10.0.0.0/16"
env_prefix = "dev"
subnet_cidr_block = "10.0.10.0/24"
availability_zone = "us-west-1a"
my_ip = "157.131.152.31/32"
instance_type = "t3.micro"

variables.tf

variable "cidr_block" {}
variable "env_prefix" {}
variable "subnet_cidr_block" {}
variable "availability_zone" {}
variable "my_ip" {}
variable "instance_type" {}
```

#### Automate create SSH key Pair

I will use `resource "aws_key_pair" "ssh-key"` to generate key-pair 

`public_key` : I need a Public Key so AWS can create the Private key pair out of that Public key value that I provide

To get `public_key` : `~/.ssh/id_rsa.pub` 

To use that `public_key` in Terraform I can extract that key into a `Variable` or I can use File location

 - `puclic_key = file("~/.ssh/rsa.pub")` or I can set location as variable `public_key = file(var.my_public_key`) and then in `terraform.tfvars` I set the `public_key_location` variable `public_key_location = "~/.ssh/id_rsa.pub"`

```
main.tf

variable public_key_location {}

resource "aws_key_pair" "ssh-key" {
  key_name = "server-key"
  public_key = file(var.public_key_location)
}
```
----

```
terraform.tfvars

public_key_location = "/Users/trinhnguyen/.ssh/id_rsa.pub"
```

#### Run entrypoint script to start Docker container

Now I have EC2 server is running and I have Networking configured . However there is nothing running on that Server yet . No Docker install, No container Deployed

I want to ssh to server, install docker, deploy container automatically . So i will create configuration for it too

With Terraform there is a way to execute commands on a server on EC2 server at the time of creation . As soon as Intances ready. I can define a set of commands that Terraform will execute on the Server . And the way to do that is using Attr `user_data`

`user_data` is like an Entry point script that get executeed on EC2 instance whenever the server is instantiated . I can provide the script using multiline string and I can define it using this syntax

My `user_data` would look like this inside `resources aws_instance`:

```
resource "aws_instance" "myapp" {
  ami = data.aws_ami.amazon-linux-image.id
  instance_type = var.instance_type
  subnet_id = aws_subnet.myapp-subnet.id 
  vpc_security_group_ids = [aws_security_group.myapp-sg.id]
  availability_zone = var.availability_zone

  associate_public_ip_address = true

  key_name = "terraform-exercise"


  user_data = <<EOF
    ### Inside this block I can define the whole shell script . Just like I would write it in a normal script file, in a bash file
                #!/bin/bash
                sudo yum update -y && sudo yum install -y docker
                sudo systemctl start docker
                sudo usermod -aG docker ec2_user
                docker run -p 8080:80 nginx
                EOF

  user_data_replace_on_change = true
  tags = {
    Name = "${var.env_prefix}-myapp"
  }
}
```

 - `-y`: Stand for automatic confirmation

 - sudo systemctl start docker : Start docker

 - sudo usermod -aG docker ec2_user : Make user can execute docker command without using sudo

 - So above is a user_data command that will run everytime the instance gets launched . I just need to configure the Terraform file, so that each time I change this user data file, The Instance actually get destroyed and re-created.

 - If I check AWS_Provider docs and check for `aws_intance` I can see the `user_data` input filed has an optional flag `user_data_replace_on_change` . I want enable this flag, I want to ensure that my Instance is destroyed and recreated when I modify this user_data field . This way I know that my user data script is going to run each time on the clean, brand-new instance, which will ge me a consistent State

!!! NOTE : user_data will only executed once . However bcs I add `user_data_replace_on_change = true` now if the `user_data` script itself changes this will force the recreation of the of the instance and re-execution of the user data script . But again this is only if something in the `user_data` script itself changes. If changes everything else like tags , key_name .... In this case it not going to force the recreation of the instance

#### Extract to shell script

Of course if I have longer and configuring a lot of different stuff I can also rerference it from a file .

I will use file location `user_data = file("entry-script.sh")`

In the same location I will create a `entry-script.sh` file

My `entry-script.sh` to install Docker and Docker-compose will look like this : 

```
#!/bin/bash

sudo yum update -y && sudo yum install -y docker

sudo systemctl start docker

sudo usermod -aG docker ec2-user

# Dowload docker compose
sudo curl -SL "https://github.com/docker/compose/releases/download/v2.35.0/docker-compose-linux-x86_64" -o /usr/local/bin/docker-compose

sudo chmod +x /usr/local/bin/docker-compose
```

## Complete CI CD with Terraform CD Stage  

#### Overview Provsion Terraform in CI CD Pipelines

In previous use case which built a docker Image in a pipeline and then deployed that Image on a remote Server by using Kubernetes, I will take that use case and integrate Terraform in order to provision that remote server as part of CI/CD process

I will create a new `stage("provision server")` in Jenkinsfile . And this will be a part where Terraform will provison create the new Server for me so that I can deploy my application on it, which lets me automate that part of creating a remote server also using CI/CD pipeline . In order to do that I have to do a couple of thing .

 - First I need to create a Key-pair an SSH key pair for the server . Whenever I create an Instance I need to assign an SSH key pair so that I can SSH into that Server .

 - Second : Install Terraform inside Jenkins Container . Bcs I want to execute Terraform Command in Jenkins

 - After that I will create Terraform file inside my Project so I can execute terraform apply inside the folder where I have defined Terraform config files

 - **Best Practice** To include everything that my application needs, including the Infrastructure automation, application configuration automation, all of this code inside the application itself

#### Create SSH key pair

I will create a key pair inside AWS and then give it to Jenkins instead of creating from Terraform

Go to AWS - EC2 -> Create key pair `.pem`

After that I need to give that PEM file to Jenkins . Inside Multi Branch Pipeline credentials I will create a new Credential and this is going to be SSH credential .

 - ID : `server-ssh-key`

 - Username: is the username that will be logging into the Server with SSH . On EC2 Instance the user I get out of the box is `ec2-user`

 - Private key : paste the content from `.pem` file

#### Install Terraform inside Jenkins Container

SSH into my Droplet and then go inside Jenkins container and we are going to install Terraform inside the Container

SSH to Droplet Server : `ssh root@<Ip-address>`

Go inside the container : `dockcer exec -it -u 0 <container-id> bash`

On Hashicorp Download I can see installation for different OS (https://developer.hashicorp.com/terraform/downloads) .

Check what OS that I have `cat /etc/os-release` .

```
wget -O - https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list

apt update && apt install terraform
```

#### Terraform Configuration File

I have already create a Terraform for deploy EC2 instances on AWS with SG and everything above 

In this case I want to deploy and execute `docker-compose`. I am copying the Docker Compose file to EC2 Instance and executing Docker Compsose command

To install docker compse inside Jenkins : (https://docs.docker.com/compose/install/standalone/)

In `entry-script.sh` : 

```
sudo yum update -y && sudo yum install -y docker
sudo systemctl start docker
sudo usermode -aG docker ec2-user

# Dowload docker compose
curl -SL "https://github.com/docker/compose/releases/download/v2.35.0/docker-compose-linux-x86_64" -o /usr/local/bin/docker-compose

chmod +x /usr/local/bin/docker-compose
```

In `main.tf` I can provide Default Values for `vpc_cidr_block` and `subnet_cidr_block` so I don't have to provide Value all the time and just use default values, however I still have the option to override it

```
main.tf

provider "aws" {
 region = var.region
}

variable vpc_cidr_block {
 defafult = "10.0.0/16"
}

variable subnet_cidr_block {
 default = "10.0.10.0/24"
}

variable avail_zone {
 default = "us-west-1a"
}

variable env_prefix {
 default = "dev"
}

variable my_ip {
 default = "my ip address"
}

variable instance_type {
 default = "t3.medium"
}

variable region {
 default = "us-west-1"
}
```

#### Provision Stage In Jenkinsfile

Inside `stage("provision server"){ steps { script {}}}` I will execute Terraform command

However Terraform configuration files are inside Terraform directory so I need execute `terraform init` and `terraform apply` from that directory . To do that I use `dir('terraform') {}` provide the folder name or relative path . Then I can execute Terraform command in that block

For `terraform apply` to work , Terraform and Jenkins Server basically needs to authenticate with AWS bcs I am creating resources inside AWS account, and obviously, AWS will need some kine of authentication to allow Terraform and Jenkins server to create those resources inside the AWS account in that Region

In the `provider "aws" {}` I can give `access_key` and `access_secret_key`. I can hardcode it in the Provider but the Best Practice is to set them as an ENV . So basically I need to set ENV in the stage for Terraform so that AWS provider can grab those ENV and connect to the AWS . Above `steps {}` I will provide `environment {}`

Let's say I want to set the environment to test. By default I have defined it to be `dev` . However from CI/CD pipeline I want to define which environment I am deploying to . Let's say this CI/CD Pipeline is for `test` environment . To override or set a value of a variable inside Terraform Configuration from Jenkinfile is using `TF_VAR_name` . Using `TF_VAR_name` I can override and set all the rest of variables as well

```
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
      }
    }
  }
}
```

#### Deploy Stage in Jenkinsfile

Bcs I create provisoning Server from Terraform I don't know what IP Address is going to be here, I need the right Public IP once Terraform create the Instance .

To reference the Attribute of Terraform `resource` from Jenkinsfile . And to get access to AWS instance Public IP . I can use `output {}` command in order to get a value . Right in the `stage ("provision server")` I will use `terraform output <name-of-output>` . However I need to save the result of the output command so I can use it in the next stage . I can do that by assigning the result of sh command to an `ENV` in Jenkins `EC2_PUBLIC_IP = sh "terraform output ec2_public_ip"` . However for that to work I need to add a parameter here inside the shell script execution and set `returnStdout: true` . What this does is basically it prints out the value to the standard output, so I can save it into a variable . I can also `trim()` that value if there are any spaces before or after

If I need othet Attribute as well I can easily define them in `output` section I can give it any value that I want and I can access them

```
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
        def ec2_public_ip = sh(
        script: "terraform output ec2_public_ip",
        returnStdout: true 
        ).trim() 

        // Set environment variable for use in later stages if needed
        env.EC2_PUBLIC_IP = ec2_public_ip
      }
    }
  }
}
```

Now In `deploy stage` I can reference IP address : `def ec2Instance = "ec2-user@${EC2_PUBLIC_IP}"`

Another thing I need to consider when working with Terraform . When `stage("provision server")` execute, Terraform will create an Instance so Terraform will wait until the Instance is created until AWS basically tells Terraform the Instance is already running and Terraform Return and after the next Stage will be execute . However after EC2 Instance is created, it needs sometime to initialize . So the issue here with Terraform when `terraform apply` executed and the server gets created, this instance gets created and the server gets created, this instance gets created and after that in the initialization process, the `entry_script.sh` will be executed so all of these commands of installing docker and starting Docker Service as well as installing docker-compose will be executed in the initialization process, So it could be that when we are in the deploy stage those commands haven't completed yet andthat mean we can't execute any remote command on that server bcs it's still installing all these technologies and it is still initializing some of the stuff and this could be timing issue and my build will fail if my server isn't ready yet. It will happen the first time when my server created

An easy solution to that problem is to basically just wait in the deploy Stage for a couple seconds to give a server time to initialize which will be the easiest solution . I can do `sleep(time: 90s, unit: "SECONDS")`

Another thing is to add `-o StrictHostKeyChecking=no` to the `scp ...` command as well

My deployment stage would look like this : 

```
stage("Deploy") {
  steps {
    script {
      sleep(time: 90, unit: "SECONDS")
      echo "Deploying the application to EC2..."

      // Define password, username, rootpassword for Mysql

      def shellCMD = "bash ./server-cmds.sh ${IMAGE_NAME}"
      def ec2_instance = "ec2-user@${EC2_PUBLIC_IP}"

      sshagent(['server-ssh-key']) {
        sh "scp docker-compose.yaml -o StrictHostKeyChecking=no ${ec2_instance}:/home/ec2-user"
        sh "scp entry_script.sh -o StrictHostKeyChecking=no ${ec2_instance}:/home/ec2-user"
        sh "ssh -o StrictHostKeyChecking=no ${ec2_instance} ${shellCMD}"
      }
    }
  }
}
```

#### Docker compose 

In my Deploy Stage above I have moved my `docker-compose` file to EC2 and also install `docker-compose` in the Bash Script 

My Docker-Compose file look like this : 

```
version: '3.8'
services:
  mysql: 
    image: ${IMAGE_NAME}
    restart: always
    environment:
      - MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
      - MYSQL_DATABASE=${DB_NAME}
      - MYSQL_USER=${DB_USER}
      - MYSQL_PASSWORD=${DB_PWD}
  java-gradle-app:
    image: ${IMAGE_NAME}
    ports:
      - 8080:8080
    environment:
      - DB_USER=${DB_USER}
      - DB_PWD=${DB_PWD}
      - DB_SERVER=mysql
      - DB_NAME=${DB_NAME}
```

Now I want to pass those values`${}` to my `docker-compose.yaml` file . I execute everything with my `server_cmds.sh` bash file therefore I will set those values in the bash file like this : 

```
#!/bin/bash

IMAGE_NAME=$1
MYSQL_ROOT_PASSWORD=$2
DB_USER=$3
DB_PWD=$4

export IMAGE_NAME
export MYSQL_ROOT_PASSWORD
export DB_USER
export DB_PWD

docker-compose -f docker-compose.yaml up --detach

echo "success"
```

Then I execute the bash file like this : `bash server_cmds.sh <image-name> <root-password> <db-user> <db-password> <db-server>` in EC2 

But I want it automatically execute it via Jenkins . But also I can not hard code those password bcs it is a sensitive data . So I will set it as a Credentials in Jenkins and get it with `credentials()` . My deploy stage now will look like this :

```
stage("Deploy") {
  environment {
    MYSQL_ROOT = credentials('mysql_root_password')
    MYSQL_USER = credentials('mysql_user_password')
    AWS_CRED = credentials('AWS_Credential')
  }
  steps {
    script {
      sleep(time: 90, unit: "SECONDS")
      echo "Deploying the application to EC2..."

      // Define password, username, rootpassword for Mysql

      def shellCMD = "bash ./server_cmds.sh ${IMAGE_NAME} ${MYSQL_ROOT_PSW} ${MYSQL_USER_USR} ${MYSQL_USER_PSW} ${AWS_CRED_USR} ${AWS_CRED_PSW} ${ECR_URL}"
      def ec2_instance = "ec2-user@${EC2_PUBLIC_IP}"

      sshagent(['server-ssh-key']) {
        sh "scp -o StrictHostKeyChecking=no docker-compose.yaml  ${ec2_instance}:/home/ec2-user"
        sh "scp -o StrictHostKeyChecking=no server_cmds.sh  ${ec2_instance}:/home/ec2-user"
        sh "ssh -o StrictHostKeyChecking=no ${ec2_instance} '${shellCMD}'"
      }
    }
  }
}
```

Example the way `('MYSQL_USER = credentials('mysql_user_password')')` works is after I get that credentials in the ENV Jenkin will give me 2 values in the background 1 for User, 1 for Password like this :` MYSQL_USER_USR` , `MYSQL_USER_PSW`

#### Set IP address of Jenkins to allow Jenkin to ssh to AWS

In `variable jenkins_ip { default = ""}` and I will add that to a security group resource . If the Jenkin IP is dynamic then I can have a default here and override it from `Jenkinfile` using `TF_VAR_name` . 

My ssh will have allow 2 ip address to access . One is mine other one is Jenkins

```
resource "aws_vpc_security_group_ingress_rule" "myapp-sg-ingress-ssh-my-ip" {
  security_group_id = aws_security_group.myapp-sg.id 
  cidr_ipv4 = var.my_ip
  from_port = 22
  ip_protocol = "TCP"
  to_port = 22

  tags = {
    Name = "${var.env_prefix}-ingress-ssh"
  }
}

resource "aws_vpc_security_group_ingress_rule" "myapp-sg-ingress-ssh-jenkins" {
  security_group_id = aws_security_group.myapp-sg.id 
  cidr_ipv4 = var.jenkins_ip
  from_port = 22
  ip_protocol = "TCP"
  to_port = 22

  tags = {
    Name = "${var.env_prefix}-ingress-ssh"
  }
}
```

#### Docker Login to pull Docker Image

The problem here is when I pull Image from Private repository I first have to do docker Login so that the Server we are trying to pull that image to authenticate with the Private Repository bcs it is secured

Docker login take `username` and `password` . Now the difference here is that `docker login` in build image stage get execute on Jenkin Server so Jenkin itself can authenticate with ECR private Repository to push an image bcs image is on the Jenkins server itself . But in deploy stage I want to do docker login from EC2 Server 

I need `ECR_URL`, `ECR_USER` and `ECR_PASSWORD` in order to login to ECR . So pass those value into a bash script then I will execute that script to login into ECR in my EC2 Server

So in my `server_cmds.sh` : 

```
#!/bin/bash

IMAGE_NAME=$1
MYSQL_ROOT_PASSWORD=$2
DB_USER=$3
DB_PWD=$4
ECR_USER=$5
ECR_PASSWORD=$6
ECR_URL=$7

echo "${ECR_PASSWORD}" | docker login --username ${ECR_USER} --password-stdin ${ECR_URL}

export IMAGE_NAME
export MYSQL_ROOT_PASSWORD
export DB_USER
export DB_PWD

docker-compose -f docker-compose.yaml up --detach

echo "success"
```

## Remote State

To share the Terraform State between different environments maybe different team members and there is actually a very simple way to do that, and it is also a **Best Practice** is to configure a remote Terraform State . So basically a remote storage where this Terraform State file will be stored .

It is also good for data backup in case something happens to the Server and the State file basically gets removed so to store it in a remote place securely is actually a good way to do that

#### Configure Remote State

To configure a Remote Storage for Terraform State file I use `terraform {}` block in `main.tf`

`terraform {}` block is for configuring metadata and information about Terraform itself

`backend` is a remote backend for Terraform and one of the Remote storages for Terraform State file is `S3 bucket`  . `S3 bucket` is a storage in AWS that is mostly used for storing files

A `backend` in Terraform determines **how and where the Terraform state is stored.**

`bucket` is to configure name of bucket . It needs to be globally unique

`key` is a path inside my bucket that I will create and it can have a folder structure like a folder hierarchy structure

`region` doesn't have to be the same region as the one that I am creating my resources in bcs it is just for storing the data

```
terraform {
 required_version = ">= 0.12"
 backend "s3" {
  bucket = "myapp-tf-s3-bucket-tim"
  key = "myapp/state.tfstate"
  region = "us-west-1"
 }
}
```

With those Configuration above Terraform will create the State file inside the bucket and then it will keep updating that Terraform state file inside the bucket everytime something changes

Before execute these changes make sure to `terraform destroy` current infrastructure first

#### Create AWS S3 Bucket

Go to AWS -> S3

When I switch to S3 service the Region will become global

Choose Create S3 bucket

 - `Block all public access` I can't open these files in the browser which makes sense bcs I want to protect my state files and I will able to access them obviously using AWS Credentials

 - `Bucket Versioning` this basically creates a versioning of the files that I am storing in the bucket so everytime a file content changes a new version is created . I basically end up with a bunch of file that, very similar to git repository, I have file that versioned bcs I have history of the changes

 - **Good practice** is to enable bucket versioning for my Terraform state file bcs if something happens and the up to date latest version of my State basically get messed up or somebody accidentally messes something up in the state file, then I still can go back to the previous State

 - `Default encryption` . Server-side encryption is now automatically selected as a default encryption type

 - `Bucket key` can be disable

#### Execute Jenkins Pipeline 

Once I have S3 Bucket create and set up . I can run my Jenkins pipeline again . 

Also make sure the previous Iac destroyed first

After execute the pipeline I can see the S3 bucket configured in Console log 

<img width="500" alt="Screenshot 2025-05-09 at 10 28 50" src="https://github.com/user-attachments/assets/178bf3f1-f778-402d-aeb2-cc7032655bc2" />

Then I go back to S3 Bucket in UI I can see the folder structure that I defined created 

<img width="500" alt="Screenshot 2025-05-09 at 10 30 58" src="https://github.com/user-attachments/assets/62f79958-cb1c-4fde-83c0-5cd44e15d5bd" />

And Inside that folder I have `state.tfstate` file . This file included the current state my infrastructure 

<img width="400" alt="Screenshot 2025-05-09 at 10 31 55" src="https://github.com/user-attachments/assets/53577229-7216-4b37-816a-3053b60092f1" />

If I already have a local State and I want to migrate it to the Remote State then I can do `terraform init` and basically just confirm that I want the migration but I have to do it manually by executing `terraform init`

If I want to access my Terraform State that currently exists in my AWS infrastructure I can actually do that locally bcs the State is not stored anymore on Jenkins but rather on a Shared remote backend as long as I have AWS credentials and everything configured to access the bucket

 - First in my local I will do `terraform init`

 - Second I do `terraform state list` it will connect to the bucket and actually give me the list of the `resource` that have been created from the remote storage . So this way everyone can access this shared remote state of Terraform

## Terraform Best Practice 

#### 1st Best Practice 

Bcs it is a simple JSON file, I could make adjustment to the Statefile directly . However, the first best practice is only change the State file contents through terraform command `terraform apply`

Do Not edit the file directly 

#### 2nd Best Practice 

When I first execute `terraform apply` Terraform will automatically create the state file locally . But what if I am working in a team so other team members also need to execute Terraform commands and they will need the State file for that . Every team member will need a latest State file before making their own update 

Always Set up a shared remote storage for State File 

In practice, remote storage backend for state file can be Amazon's S3 bucket, Terraform Cloud, Azure Storage, Google cloud storage etc .... 

#### 3st Best Practice 

What if 2 team members execute Terraform commands at the same time . Thing happen to the State file when I have concurrent changes is I might get a conflict or mess up my State file 

To avoid changing Terraform State at the same time is Locking the State file until update fully completed then unblock it for the next command 

In Practice, I will have this configured in my Storage Backend . In S3 bucket for example DynamoDB service is automatically used for State file locking

!!! NOTE : Not all Service Backend supported be aware when choosing a remote Storage for State file 

If supported TF will lock my state for all operating that could write state 

#### 4th Best pratice 

What happens if I lose my State file ? Something may happen to my remote storage location or someone may accidentally override the data or it may get corrupted . To avoid this the is to Back up State file 

In practice, I can do this enabling versioning for it and many storage backends will have such a feature 

This also mean that I have a nice history of state changes and I can reverse to any previouse Terraform State if I want to 

#### 5th Best Practice 

Now I have my State file in a Share remote location with locking enable and file versioning for backup so I have one State file for my Infrastructure . But usally I will have multiple environment like development, testing and production so which environment does this state file belong to ?

Use 1 dedicated State file per environment and each State file will have its own storage backend with locking and versioning configured 

#### Next 3 Best practice are about how to manage Terraform code itself and how to apply Infrastructure changes 

These Practices can be grouped into a relatively new trend that emerged in the IaC which is called GitOps

#### 6th Best Practice 

When I am working on Terraform scripts in a Team, it is important to share the code in orther to collaborate effectively 

I should host Terraform code in its own Git repository just like my Application code . This is not only beneficial for effective collaboration in a team but I also get versioning for my infrastructure code changes, So I can have history of changed for my Terraform code 

#### 7th Best Practice 

Who is allow to make changed to Terraform code ? 

Treat Terraform code just like my application code . This mean I should have the same process of reviewing and testing the changes in my Infrastructure code as I have for my application code 

This mean I should have the same process of reviweing and testing the changes in my Infrastructure code as I have for my application code with continuous intergration pipeline using merge requests to integrate code changed, this will allow my team to collaborate and produce quality infrastructure code which is tested and reviewed 

#### 8th Best Pratice 

I have tested and review my Iac code repository . How do I apply them to actual Infrastructure 

Execute Terraform command to apply changes in a continuous deployment pipeline. 

So instead of team members manually updating the infrastructure by executing Terraform commands from their own computers it should happen only from an automated build this way I have a single location from which all the infrastructure changes happen and I have a more streamlined process of updating my Infrastructure 


## Module my Terraform project

In Terraform we have concept of modules to make configuration not monolithic . So I am basically break up part of my configuration into logical groups and package them together in folders . and this folders then represent modules

Modularize my project

I will create a branch for module `git checkout -b modules`

Best practice: Separate Project structure . Extract everything from main to those file

 - main.tf

 - variable.tf

 - outputs.tf

 - providers.tf

I don't have to link that file I don't have to reference the variable.tf and output.tf bcs Terraform knows that these files belong together and it kind of grabs everyting and link them together

And I also have the providers.tf files that will hold all of the providers which I have configured already . Eventhough I have only 1 here which is our AWS provider it is Best Pratice to use providers file in the same way .

#### Create module 

Create folder call modules : `mkdir modules`

Inside `modules` fodler I will create 4 folder : 

 - `vpc` :  Include	VPC, Internet Gateway, Route Tables

 - `subnet`: Include Public/private subnets, subnet associations

 - `security_group`: Include All security group and ingress/egress rules

 - `ec2`: Include	EC2 instances, key pairs, user data

#### VPC module 

I will extract all the `resources` VPC, IGW, Route Tables to the `main.tf` like this : 

```
resource "aws_vpc" "myapp-vpc" {
  cidr_block = var.vpc_cidr_block

  tags = {
    Name: "${var.env_prefix}-vpc"
  }
}

resource "aws_route_table" "myapp-route-table" {
  vpc_id = aws_vpc.myapp-vpc.id

  route {
    cidr_block = "0.0.0.0/0" ## Destination . Any IP address can access to my VPC 
    gateway_id = aws_internet_gateway.myapp-igw.id ## This is a Internet Gateway for my Route Table 
  }

  tags = {
    Name = "${var.env_prefix}-rtb"
  }
}

resource "aws_internet_gateway" "myapp-igw" {
  vpc_id = aws_vpc.myapp-vpc.id

  tags = {
    Name = "${var.env_prefix}-igw"
  }
}
```

And set a variables in `variables.tf` like this : 

```
variable "vpc_cidr_block" {}
variable "env_prefix" {}
```

In this I don't need any `output` so I will leave it empty

#### Subnet module

I will extract all the `resources` Subnet, Route Table Association like this :

 - In Subnet module I don't have `vpc resource` and `route_table resource` in the same context so I set it as a `variable`

```
resource "aws_subnet" "myapp-subnet" {
  vpc_id     = var.vpc_id
  cidr_block = var.subnet_cidr_block
  availability_zone = var.availability_zone

  tags = {
    Name = "${var.env_prefix}-subnet"
  }
}

resource "aws_route_table_association" "a-rtb-subnet" {
  route_table_id = var.route_table_id
  subnet_id = aws_subnet.myapp-subnet.id
}
```


And set variables in `variables.tf`:

```
variable "vpc_id" {}
variable "subnet_cidr_block" {}
variable "availability_zone" {}
variable "env_prefix" {}
variable "route_table_id" {}
```

#### Security_Group module

I will extract all the `resources` SG, Ingress Rule, Egress Rule like this :

 - In Security Group module I don't `vpc resource` in the same context so I set it as a `variable`

```
resource "aws_security_group" "myapp-sg" {
  name = "myapp-sg"
  description = "Allow inbound traffic and all outbound traffic"
  vpc_id = var.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "myapp-sg-ingress-ssh-my-ip" {
  security_group_id = aws_security_group.myapp-sg.id 
  cidr_ipv4 = var.my_ip
  from_port = 22
  ip_protocol = "TCP"
  to_port = 22

  tags = {
    Name = "${var.env_prefix}-ingress-ssh"
  }
}

resource "aws_vpc_security_group_ingress_rule" "myapp-sg-ingress-ssh-jenkins" {
  security_group_id = aws_security_group.myapp-sg.id 
  cidr_ipv4 = var.jenkins_ip
  from_port = 22
  ip_protocol = "TCP"
  to_port = 22

  tags = {
    Name = "${var.env_prefix}-ingress-ssh"
  }
}

resource "aws_vpc_security_group_ingress_rule" "myapp-sg-ingress-8080" {
  security_group_id = aws_security_group.myapp-sg.id 
  cidr_ipv4 = "0.0.0.0/0"
  from_port = 8080
  ip_protocol = "TCP"
  to_port = 8080

  tags = {
    Name = "${var.env_prefix}-ingress-8080"
  }
}

resource "aws_vpc_security_group_egress_rule" "myapp-sg-egress" {
  security_group_id = aws_security_group.myapp-sg.id 
  cidr_ipv4 = "0.0.0.0/0"
  ip_protocol = "-1"

  tags = {
    Name = "${var.env_prefix}-egress"
  }
}
```

And set variable in `variables.tf`

```
variable "vpc_id" {}
variable "my_ip" {}
variable "env_prefix" {}
variable "jenkins_ip" {}
```

#### EC2 Module 

I will extract `data aws_ami` and `resources aws_instance` like this :

 - I don't have subnet in the same context so I will set it as a Variable

```
data "aws_ami" "amazon-linux-image" {

  owners = ["amazon"]
  most_recent = true 

  filter {
    name = "name"
    values =  ["al2023-ami-*-x86_64"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "myapp" {
  ami = data.aws_ami.amazon-linux-image.id
  instance_type = var.instance_type
  subnet_id = aws_subnet.myapp-subnet.id 
  vpc_security_group_ids = [aws_security_group.myapp-sg.id]
  availability_zone = var.availability_zone

  associate_public_ip_address = true

  key_name = "terraform"

  user_data = file("./entry_script.sh")

  user_data_replace_on_change = true
  tags = {
    Name = "${var.env_prefix}-myapp"
  }
}
```

And the I will set a variable in `variable.tf`

```
variable "subnet_id" {}
variable "instance_type" {}
variable "availability_zone" {}
variable "env_prefix" {}
```

### Use Modules 

#### For VPC Module 

The way to use that is in `root/main.tf` I use module "myapp-vpc" {} . Then I need a couple of Attribute

 - `source = "modules/subnet"` : Where this module actually living .

I have set 2 variables in my `vpc modules` so I have to set it and reference it also as a variables in my `root/main.tf` like this 

```
module "myapp-vpc" {
  source = "./modules/vpc"
  vpc_cidr_block = var.vpc_cidr_block
  env_prefix = var.env_prefix
}
```

The actual value will be in `root/terraform.tfvars`

#### For Subnet Module 

I need to access the resources that will be created by a module in another module

The first thing I need to do is `output` the VPC Object so that it can be used by other Modules the way I do that is in `modules/vpc/output.tf` . And I also need a rout_table_id from vpc module for route_table_association `resource`

```
output "vpc_object" {
  value = aws_vpc.myapp-vpc
}

output "rtb_object" {
  value = aws_route_table.myapp-route-table
}
```

Now I have a VPC object and Route_Table Object . I want to get a VPC id in my `root/main.tf` for my Subnet module I will do `vpc_id = module.myapp-vpc.vpc_object.id` and `route_table_id = module.myapp-vpc.rtb_object.id`

```
  module "myapp-subnet" {
  source = "./modules/subnet"
  vpc_id = module.myapp-vpc.vpc_object.id
  availability_zone = var.availability_zone
  subnet_cidr_block = var.subnet_cidr_block
  env_prefix = var.env_prefix
  route_table_id = module.myapp-vpc.rtb_object.id
  }
```

#### For Security Group Module 

The same for Subnet Module 

```
module "myapp_security_group" {
  source = "./modules/security_group"
  vpc_id = module.myapp-vpc.vpc_object.id
  my_ip = var.my_ip
  env_prefix = var.env_prefix
  jenkins_ip = var.jenkins_ip
}  
```

#### For EC2 Module 

This module need `subnet_id` and `security_group_id` from Subnet module 

The first thing I need to do is `output` the Subnet Object so that it can be used by other Modules the way I do that is in `modules/subnet/output.tf`

```
output "subnet_object" {
  value = aws_subnet.myapp-subnet
}
```

and in the `modules/security_group/output.tf`

```
output "security_group_object" {
  value = aws_security_group.myapp-sg
}
```

Now I have subnet object and security_group object I can reference it as `subnet_id = module.myapp-subnet.subnet_object.subnet_id` : 

```
module "myapp-ec2" {
  source = "./modules/ec2"
  subnet_id = module.myapp-subnet.subnet_object.id
  env_prefix = var.env_prefix
  availability_zone = var.availability_zone
  instance_type = var.instance_type
  security_group_id = module.myapp_security_group.security_group_object.id
}
```

#### In root main tf

My entire a code will look like this :

```
terraform {
 required_version = ">= 0.12"
 backend "s3" {
  bucket = "myapp-tf-s3-bucket-tim"
  key = "myapp/state.tfstate"
  region = "us-west-1"
 }
}

module "myapp-vpc" {
  source = "./modules/vpc"
  vpc_cidr_block = var.vpc_cidr_block
  env_prefix = var.env_prefix
}
module "myapp-subnet" {
  source = "./modules/subnet"
  vpc_id = module.myapp-vpc.vpc_object.id
  availability_zone = var.availability_zone
  subnet_cidr_block = var.subnet_cidr_block
  env_prefix = var.env_prefix
}

module "myapp_security_group" {
  source = "./modules/security_group"
  vpc_id = module.myapp-vpc.vpc_object.id
  my_ip = var.my_ip
  env_prefix = var.env_prefix
  jenkins_ip = var.jenkins_ip
}

module "myapp-ec2" {
  source = "./modules/ec2"
  subnet_id = module.myapp-subnet.subnet_object.id
  env_prefix = var.env_prefix
  availability_zone = var.availability_zone
  instance_type = var.instance_type
  security_group_id = module.myapp_security_group.security_group_object.id
}
```

With module now I have a cleaner `main.tf` file 


This is my `variable.tf`

```
variable "vpc_cidr_block" {
  default = "10.0.0.0/16"
}

variable "subnet_cidr_block" {
  default = "10.0.10.0/24"
}

variable "env_prefix" {
  default = "ci/cd"
}

variable "my_ip" {
  default = "157.131.152.31/32"
}

variable "availability_zone" {
  default = "us-west-1a"
}

variable "instance_type" {
  default = "t3.large"
}

variable "region" {
  default = "us-west-1"
}

variable "jenkins_ip" {
  default = "209.38.152.165/32"
}
```

Also I want to print out the `ec2_public_ip` . So I will set a ec2 object in `/modules/ec2/output.tf` : 

```
output "ec2_object" {
  value = aws_instance.myapp
}
```

then in my `root/output.tf`

```
output "ec2_public_ip" {
  value = module.myapp-ec2.ec2_object.public_ip
}
```






