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

- [Provison EKS](#Provison-EKS)

  - [Steps to Provision EKS ](#Steps-to-Provision-EKS)
 
  - [Create-VPC](#Create-VPC)
 
  - [Create EKS Cluster and Worker Nodes](#Create-EKS-Cluster-and-Worker-Nodes)

- [Complete CI/CD with Terraform CD Stage](#Complete-CI-CD-with-Terraform-CD-Stage)

  - [Overview Provsion Terraform in CI CD Pipelines](#Overview-Provsion-Terraform-in-CI-CD-Pipelines)
 
  - [Provision Stage In Jenkinsfile](#Provision-Stage-In-Jenkinsfile)
 
  - [Deploy Stage in Jenkinsfile](#Deploy-Stage-in-Jenkinsfile)
 
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


## Provison EKS

#### Steps to Provision EKS 

I need to create (EKS), the Control Plane that Managed by AWS

Once I have Control Plane Nodes I need to connect those Worker Nodes to the Control Planes Nodes in order to have a complete cluster so that I can start deploying my application . For that I need to create VPC where is my Worker Nodes will run 

So I create cluster always in a specific region my region has multiple availability zones (2 or 3) . I end up with a highly available Control Plane which is managed by AWS which is running somewhere else, And I have the Worker Nodes that I create myself and connect to the Control Plane that we also want to be highly available so we want to deploy them into all the available AZs of our region

#### Create VPC 

VPC for EKS cluster actually needs a very specific configuration of a VPC and the subnet inside as well as route tables and so on

I will use AWS VPC modules to create VPC for EKS (https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest)

In will create `touch vpc.tf` file :

```
variable "vpc_cidr_block" {}
variable "private_subnets_cidr_block" {}
variable "public_subnets_cidr_block" {}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  private_subnets = var.private_subnets_cidr_block
  public_subnets  = var.public_subnets_cidr_block
}
```

**Best practice**: Always use variable instead of hardcoding

**Specify the Cidr block of subnets**: Basically inside the module "vpc" the subnet resources are already define . So subnet will be created . We can decide how many subnet and which subnets and with which cidr blocks they will be created . And for EKS specifically there is actually kind of the best practice for how to configure VPC and its Subnets

**Best Practice** : Create one Private and one Public Subnet in each of the Availability Zones in the Region where I am creating my EKS . In my region there are 3 AZs so I need to create 1 Private and 1 Public key in each of those AZs so 6 in total

In `terraform.tfvars`

```
vpc_cidr_block = "10.0.0.0/16"

private_subnet_cidr_blocks = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]

public_subnet_cidr_blocks = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
```

I need to define that I want those subnets to be deployed in all the availability zones . So I want them to be distributed to these 3 AZs that I have in the Region and for that I have an attribute here called `azs` and I need to define a name of those AZs `azs = ["us-west-1a", "us-west-1b", "us-west-1c"]` .

 - But I want to dynamically set the Regions . By using `data` to query AWS to give me all the AZ for the region

 - I have to specify which Region I am querying the AZs from . Then it will give me AZs from the Region that is defined inside the AWS providers

```
provider "aws" {
  region = "us-west-1"
}

variable "vpc_cidr_block" {}
variable "private_subnets_cidr_block" {}
variable "public_subnets_cidr_block" {}

data "aws_availability_zones" "azs" {} # data belong to a provider so I have to specify the Provider .

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  private_subnets = var.private_subnets_cidr_block
  public_subnets  = var.public_subnets_cidr_block
  azs = data.aws_availability_zones.azs.names
}
```

Then I will enable the `enable_nat_gateway` . By default the nat gateway is enabled for the the subnets . However we are going to set it to true for transparency and Also I am going to enable single nat gateway which basically creates a shared common nat gateway for all the private Subnet so they can route their internet traffic through this shared nat Gateway

Then I want to `enable_dns_hostnames` inside our VPC . For example when EC2 instances gets created it will get assigned the Public IP address, and private IP address but it will also get assigned the public and private DNS names that resolve to this IP address

```
enable_nat_gateway = true
single_nat_gateway = true
enable_dns_hostnames = true 
```

I also want to add tags :

 - Why do I have this tags ? `"kubernetes.io/cluster/myapp-eks-cluster" = "shared"` . Basically I have used tag to lables our resources so that I know for example which environment they are belong to so we have a tag with environment prefix

 - Tags are also for referencing components from other components programmatically .
 
 - Basically in EKS Cluster when we create the Control Plane, one of the processes in the Control Plane is `Kubernetes Cloud Controller Manager`, and this `Cloud Controller Manager` actually that com from AWS is the one that Orchestrates connecting to the VPC, connecting to the Subnets, connecting with the Worker Nodes and all these configurations, it talking to the resources in our AWS Account and Creating some stuff . So Kubernetes Cloud Manager needs to know which resources in our account it should talk to, It needs to know which VPC should be used in a Cluster, Which Subnet should be use in the Cluster . Bcs We may have multiple VPC and multiple Subnets and we need to tell control Plane or AWS, use these VPCs and these subnet for this specific cluster . We may also have multiple VPCs for multiple EKS Clusters so it has to be specific label that Kubernetes Cloud Controller Manager can acutally detect and identify

 - These tag are basically there to help the Cloud Control Manager identify which VPC and subnet it should connect to , and that is why I have the Cluster Name here bcs obviously if I have multiple Cluster I can differentiate the VPCs and subnets or the lables using the cluster name

 - In public subnets all three of them, I will add another the tag called `kubernetes.io/role/elb`

 - And for Private Subnet I have `kubernetes.io/role/internalelb`

 - So public has elb which is elastic load balancer and private has internal elb . So basically when I create load balancer service in Kubernetes, Kubernetes will provision a cloud native load balancer for that service . However it will provision that cloud load balancer in the Public Subnet bcs the Load Balancer is actually an entry point to a Cluster and Load Balancer gets an external IP Address so that we can communicate to it from outside, like from browser request or from other clients . And since we have Public Subnet and Private Subnet in VPC the Public one is actually a subnet that allows communication with Internet . Private subnet closed to Internet . So If I deploy Load Balancer in Private one I can't access it bcs it blocked . So kubernetes need to know basically which one is a public subnet so that it can create and provision that load balancer in the public subnet So that the load balancer can be accessed from the Internet . And there are also internal Load Balancers in AWS which will be created for services and components inside the Private Subnets

 - So these tag are acutally for consumption by the `Kubernetes Cloud Controller Manager` and `AWS load balancer controller` that is responsible for creating load balancer for Load Balancer Service Type

 - !!! NOTE : Those tags are required

```
tags = {
  "kubernetes.io/cluster/myapp-eks-cluster" = "shared" # This will be a cluster name
}

public_subnet_tags = {
  "kubernetes.io/cluster/myapp-eks-cluster" = "shared"
  "kubernetes.io/role/elb" = 1
}

private_subnet_tags = {
  "kubernetes.io/cluster/myapp-eks-cluster" = "shared"
  "kubernetes.io/role/internal-elb" = 1
}
```

#### Create EKS Cluster and Worker Nodes

Now I have VPC already configured . I will create EKS Cluster

I will create `touch eks-cluster.tf` file 

I will use the EKS `module` . This will basically create all the resources needed in order to create cluster as well as any Worker Nodes that I configure for it and provision some of the part provision some of the part of Kubernetes (https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest)

First I add `cluster_name` and `cluster_version`

Then I need to set `subnet_ids` . This is a list of Subnet that I want the Worker Nodes to be started in . So I have created a VPC with 6 Subnets (3 Private and 3 Public) .

 - Private : Where I want my Workload to be scheduled .

 - Public : are for external resources like Load Balancer of AWS for external connectivity

 - I will reference private subnet for `subnets_id = module.myapp-vpc.private_subnets` . For Security reason bcs It is not exposed to Internet

Then I can set `tags` for EKS Cluster itself . I don't have to set some required text like I did in the vpc module

 - If I am running my Microservice Application in this Cluster then I can just pass in the name of my Microservice Application, just to know which Cluster is running in which Application

In addition to Subnet or the Private Subnets where workloads will run we also need to provide a VPC id . I can also reference it through module: `module.myapp-vpc.vpc_id`

Then I need to configure how I want my Worker Nodes to run or what kind of Worker Nodes I want to connect to this Cluster :

 - In this case I will use Nodegroup semi-managed by AWS `eks_managed_node_groups` . The Value of this Attribute is a map of EKS managed NodeGroup definitions .

NOTE : Also Now I have to create the Role for the Cluster and for the Node Group as well . This eks module acutally define those roles and how they should be created . So we don't have to configure them

My code will look like this  :

```
variable "instance_types" {}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.35.0"

  cluster_name = "myapp-eks"
  cluster_version = "1.32"

  cluster_endpoint_public_access = true

  enable_cluster_creator_admin_permissions = true

  subnet_ids = module.vpc.private_subnets
  vpc_id = module.vpc.vpc_id

  eks_managed_node_groups = {
    example = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = [var.instance_types]

      min_size     = 2
      max_size     = 5
      desired_size = 2
    }
  }

  tags = {
    evironment = "dev"
    application = "myapp"
  } 
}
```

## Complete CI/CD with Terraform CD Stage

#### Overview Provsion Terraform in CI CD Pipelines

In previous use case which built a docker Image in a pipeline and then deployed that Image on a remote Server by using Kubernetes, I will take that use case and integrate Terraform in order to provision that remote server as part of CI/CD process

I will create a new `stage("provision server")` in Jenkinsfile . And this will be a part where Terraform will provison create the new Server for me so that I can deploy my application on it, which lets me automate that part of creating a remote server also using CI/CD pipeline . In order to do that I have to do a couple of thing .

 - First I need to create a Key-pair an SSH key pair for the server . Whenever I create an Instance I need to assign an SSH key pair so that I can SSH into that Server .

 - Second : Install Terraform inside Jenkins Container . Bcs I want to execute Terraform Command in Jenkins

 - After that I will create Terraform file inside my Project so I can execute terraform apply inside the folder where I have defined Terraform config files

 - **Best Practice** To include everything that my application needs, including the Infrastructure automation, application configuration automation, all of this code inside the application itself

#### Create SSH key-pair

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

#### Provision Stage In Jenkinsfile

Inside `stage("provision server"){ steps { script {}}}` I will execute Terraform command

However Terraform configuration files are inside Terraform directory so I need execute `terraform init` and `terraform apply` from that directory . To do that I use `dir('terraform') {}` provide the folder name or relative path . Then I can execute Terraform command in that block

For `terraform apply` to work , Terraform and Jenkins Server basically needs to authenticate with AWS bcs I am creating resources inside AWS account, and obviously, AWS will need some kine of authentication to allow Terraform and Jenkins server to create those resources inside the AWS account in that Region

In the `provider "aws" {}` I can give `access_key` and `access_secret_key`. I can hardode it in the Provider but the Best Pratice is to set them as an ENV . So basically I need to set ENV in the stage for Terraform so that AWS provider can grab those ENV and connect to the AWS . Above `steps {}` I will provide `environment {}`

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

To reference the Attribute of Terraform resource from Jenkinsfile . And to get access to AWS instance Public IP . I can use `output {}` command in order to get a value . Right in the `stage ("provision server")` I will use `terraform output <name-of-output>` . However I need to save the result of the output command so I can use it in the next stage . I can do that by assigning the result of sh command to an `ENV` in Jenkins `EC2_PUBLIC_IP = sh "terraform output ec2_public_ip"` . However for that to work I need to add a parameter here inside the shell script execution and set `returnStdout: true` . What this does is basically it prints out the value to the standard output, so I can save it into a variable . I can also `trim()` that value if there are any spaces before or after

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
```


