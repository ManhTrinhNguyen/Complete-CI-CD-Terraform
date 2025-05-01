- [Deploy Mysql](#Deploy-Mysql)

- [Deploy Mysql for Production](#Deploy-Mysql-for-Production)

- [Deploy Java Application](#Deploy-Java-Application)

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
   
  - [CD Stage](#CD-Stage)
 
    - [Install kubectl inside Jenkins Container](#Install-kubectl-inside-Jenkins-Container)
   
    - [Install aws-iam-authenticator tool inside Jenkins Container](#Install-aws-iam-authenticator-tool-inside-Jenkins-Container)

    - [Create Kubeconfig file to connect to EKS Cluster](#Create-Kubeconfig-file-to-connect-to-EKS-Cluster)
   
    - [Create AWS Credentials](#Create-AWS-Credentials)

    - [Add AWS credentials on Jenkins for AWS account authentication](Add-AWS-credentials-on-Jenkins-for-AWS-account-authentication)
 
    - [Create Secret Component AWS ECR Credentials](#Create-Secret-Component-AWS-ECR-Credentials)
   
    - [Configure Kubernetes Deployment and Service Yaml files](#Configure-Kubernetes-Deployment-and-Service-Yaml-files)
   
    - [Create Deployment Stage in Jenkinsfile](#Create-Deployment-Stage-in-Jenkinsfile)

- [Configure Autoscaling for EKS Cluster](#Configure-Autoscaling-for-EKS-Cluster)

  - [Create custom Autoscaler Policy for my NodeGroup](#Create-custom-Autoscaler-Policy-for-my-NodeGroup)
 
  - [Create OIDC Provider](#Create-OIDC-Provider)
 
  - [Create an IAM role for your service accounts in the console](#Create-an-IAM-role-for-your-service-accounts-in-the-console)
 
  - [Configure Tags on Autoscaling Group . Automate created by AWS](#Configure-Tags-on-Autoscaling-Group-Automate-created-by-AWS)
 
  - [Deploy Cluster Autoscaler](#Deploy-Cluster-Autoscaler)
 
- [Complete CI/CD with Terraform](#Complete-CI/CD-with-Terraform)

  - [Steps to Provision EKS](#Steps-to-Provision-EKS)
 
  - [Create VPC](#Create-VPC)
 
  - [Create EKS Cluster and Worker Nodes](#Create-EKS-Cluster-and-Worker-Nodes)
 
  - [Overview-Provsion-Terraform-in-CI/CD-Pipelines](#Overview-Provsion-Terraform-in-CI/CD-Pipelines)
 
  - [Create SSH key-pair](#Create-SSH-key-pair)

  
# AWS-EKS 

## Create EKS Cluster . 

#### Connect kubectl locally with EKS Cluster

Eventhough I don't have Worker Nodes yet . I can still can talk to the API Server bcs Control Plane is running

They way to connect is create kubeconfig file for newly created EKS Cluster

Configure Kubectl to connect to EKS Cluster

Step 1: To see AWS configure detail : `aws configure list`

Step 2: To create kubeconfig file locally : `aws eks update-kubeconfig --name <cluster-name>`

-- --name : Connection info for Cluster . Which is the Cluster Name

 - After Created kubeconfig file my Local machine already connected to AWS K8 Cluster. The file will store in `.kube/config`

## Deploy Mysql and phpmyadmin 

#### Deploy Mysql 

To deploy Mysql I will use Helm to make the process more efficent  

Helm is a Package Manager of Kubernetes

Step 1 : Install helm `brew install helm` 

Step 2 : Bitnami is a provider Helm Charts . They also Provide and Maintain MySQL DB Helm chart . To get Bitnami Repo : helm repo add bitnami https://charts.bitnami.com/bitnami

!!! Note : When I execute Helm Command it will execute against the Cluster I connected to

Step 3 : To search for Bitnami Repo : `helm search repo binami/mysql`

Step 4 : Create Mysql values files . So I can override the value that I need for my MySQL 

```
architecture: replication
auth:
  rootPassword: secret-root-pass
  database: my-app-db
  username: my-user
  password: my-pass

# enable init container that changes the owner and group of the persistent volume mountpoint to runAsUser:fsGroup
volumePermissions:
  enabled: true

primary:
  persistence:
    enabled: false

secondary:
  # 1 primary and 2 secondary replicas
  replicaCount: 2
  persistence:
    enabled: false

    # Storage class for EKS volumes
    # storageClass: gp2
    # accessModes: ["ReadWriteOnce"]
```

Step 5: To install MySQL Helm Charts from Bitnami : `helm install <release-name> --values <mysql-helm-value-yaml-file> bitnami/mysql` 

Step 6 : After MySQL DB started . To debug if something wrong with the pods : kubectl logs <pods-name>

Step 7 : I Can also get inside the pod to see mysql pod ENV : kubectl exec -it <pod-name> -- bin/bash Or kubectl describe pod <pod-name>

#### Deploy Mysql for Production 

My values file : 

```
architecture: replication

auth:
  rootPassword: rootpassword  # ✅ use a Kubernetes Secret in real deployments
  database: my-app-db
  username: tim
  password: mypassword     # ✅ use a Kubernetes Secret in real deployments

volumePermissions:
  enabled: true  # ✅ Keep this enabled to ensure volume permissions are correct

primary:
  persistence:
    enabled: true
    storageClass: gp2                     # ✅ Use AWS EBS gp2 or gp3
    accessModes: ["ReadWriteOnce"]
    size: 20Gi                            # ✅ Adjust as per data needs

secondary:
  replicaCount: 2
  persistence:
    enabled: true
    storageClass: gp2
    accessModes: ["ReadWriteOnce"]
    size: 20Gi
```

EKS need certain Perrmission to allow Kubernetes to provision EBS Volumns dynamically when using `storgeClass: gp2 or gp3`

I need to install add-on EBS CSI Driver installed (Must be installed in my Cluster)

  - This driver actually talks to AWS EBS API to Create Volume, Attach them to Pod, Resize, delete them

EBS CSI Driver need an IAM Role with these Permission in AWS-managed policy `AmazonEBSCSIDriverPolicy`

Step 1 : Creates the IAM Role and links it to the Kubernetes service account via an OIDC provider.

```
eksctl create iamserviceaccount \
  --name ebs-csi-controller-sa \
  --namespace kube-system \
  --cluster $CLUSTER_NAME \
  --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
  --approve \
  --role-name AmazonEKS_EBS_CSI_DriverRole
```

  - Service Account is Application User . As the same way for human User I can link Service Account to Role or ClusterRole with RoleBinding or ClusterRoleBinding, And with binding service account or the Application that is behind that Service account will get Permission that are defined in the Role or Cluster Role

Step 2 : Install the EBS CSI driver as an EKS Add-on and attach the IRSA role

```
eksctl create addon \
  --name aws-ebs-csi-driver \
  --cluster $CLUSTER_NAME \
  --service-account-role-arn arn:aws:iam::<YOUR_AWS_ACCOUNT_ID>:role/AmazonEKS_EBS_CSI_DriverRole \
  --force
```

Step 3 : Confirm the EBS CSI driver is installed : `kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-ebs-csi-driver` 

  - I should see something like
    
  ```
  ebs-csi-controller-xxxx        Running
  ebs-csi-node-xxxxx             Running
  ```
**Wrap up**

Every application (pod) runs under a ServiceAccount. If I want it to do something — inside the cluster or outside (like AWS APIs) — I need to give that ServiceAccount the right permissions or attach a role

If I use **Terraform** I can use this : `enable_ebs_csi_driver = true`


## Deploy Java Application 

I have Java Image in my ECR Private Repo

To pull Image From ECR are I need to create Secret Component containe access token and crenditals to my ECR 
 
Configure Deployment to use that Secret using Attribute called `imagePullSecrets` 

#### To Create Secret Component 

```
kubectl create secret docker-registry <my-secrect-name> \
--docker-server=https://565393037799.dkr.ecr.us-west-1.amazonaws.com
--docker-username=AWS
--docker-password=aws ecr get-login-password --region us-west-1
```

#### ENV For Container to connect to DB 

I create Secret Component to store DB_USER, DB_NAME 

```
apiVersion: v1
kind: Secret
metadata: 
  name: java-secret
type: Opaque 
data: 
  DB_USER: dGlt
  DB_NAME: bXktYXBwLWRi
```

And I create Configmap to store DB_URL_SERVER

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: java-configmap
data: 
  database_server: "mysql-primary-0:mysql-primary-headless"
```

I have a `CrashLoopBackOff` means:

 - Your Pod starts → crashes → restarts → crashes again, and this keeps happening in a loop.

 - To know happen I use `kubectl logs <pod-name>`

 - Or I can use `kubectl describe pod <pod-name>` to see events of the pod generating

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

### CD Stage

I will setup automatic deployment in Kubernetes to the cluster in the pipeline 

I need to configure a couple of Steps in order for that to work : 

#### Install kubectl inside Jenkins Container

Connect to a Server : `ssh root@...`

Check running Container : `docker ps`

Go inside Jenkins container as a Root User bcs Jenkins doesn't admin permission : `docker exec -it -u 0 <container-id> bash`

Inside Jenkins container install kubectl, make it executable and move it to `/usr/local/bin/kubectl` : `curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl; chmod +x ./kubectl; mv ./kubectl /usr/local/bin/kubectl`

As I learned in Jenkins Moudule . Whenever I need some CLI tools execute commands with inside our Pipelines I can install them directly on a Jenkins Server or inside a Jenkins container and they will be available as Linux Command inside the Pipeline I can execute them pretty simply .

#### Install aws iam authenticator tool inside Jenkins Container

This is Specific to AWS . When I created EKS Cluster I got a Kubeconfig which contain for the Secret and all the certificate for authenticating and connecting, it also container the infomation to a Cluster on AWS specificly to EKS Cluster . So I will provide all the credentials, however I need kubectl and aws-iam-authenticator both to acctually connect to EKS cluster and authenticate to it from Jenkins

Install aws-iam-authentocator, make it executable and move it to /usr/local/bin :

```
curl -Lo aws-iam-authenticator https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/download/v0.6.11/aws-iam-authenticator_0.6.11_linux_amd64

chmod +x ./aws-iam-authenticator

mv ./aws-iam-authenticator /usr/local/bin
```

#### Create Kubeconfig file to connect to EKS Cluster

I don't have the editor inside the Jenkins Container bcs it is a lightweight container . I will create the file outside on the Host and I just simple copy the file into Jenkin Container

Basic config file content 

```
apiVersion: v1
kind: Config
clusters:
- cluster:
   certificate-authority-data: <certificate-data>
   server: <endpoint-url>
 name: kubernetes
contexts:
- context:
   cluster: kubernetes
   user: aws
 name: aws
current-context: aws
users:
- name: aws
 user:
   exec:
     apiVersion: client.authentication.k8s.io/v1beta1
     command: /usr/local/bin/aws-iam-authenticator
     args:
       - "token"
       - "-i"
       - <cluster-name>

```

I need to put in Cluster name

I need to put in Server API Endpoint : I can get this from EKS overview in Management Console

The other thing I need to chagne is `certificate-authority-data` : This is something that get generated in EKS Cluster when its gets created and I have that file available on local in `kube/config`

When I have the file ready I go inside Jenkins and create kube folder : `docker exec -it <container-id> bash` then I will go back to Jenkins home cd `~`, to see the path use pwd I should see `/var/jenkins_home` then I create .kube folder mkdir `.kube` to store kubeconfig file

Then copy config file from host to Jenkins : `docker cp config container-id:/var/jenkins_home/.kube/`

#### Create AWS Credentials

Need Credentials for AWS Users . Locally I have work with the Admin User which is AWS User with its own secret key ID and access key . I need to configure the same for Jenkins

NOTE : I don't have to use Admin User to execute command on Jenkins . Best practice would be Create AWS IAM Jenkins User for different Services that Jenkins connect to and needs to authenticate to including Docker Repos, AWS, Kubernetes and so on. And I can give that User Limited Permission for security Reason

Inside Jenkins UI . Inside mutiple Branches Pipeline -> Go to Credentials -> Add Credentials -> Choose Secret Text

 - I will create 2 Credentials : `access_key_id` and `secret_key_id`

 - Locally my Credentials live here : `.aws/credentials`

Configure `access_key_id` and `secret_key_id` in Jenkinsfile will look like this:

```
stage("Deploy with Kubernetes") {
  environment{
    AWS_ACCESS_KEY_ID = credentials('Aws_Access_Key_Id')
    AWS_SECRET_ACCESS_KEY = credentials('Aws_Secret_Access_Key')
  }
  steps {
    script {

    }
  }
}
```

Now I can execute kubectl bcs I have it installed inside my Jenkins Container . With `kubectl` execution `aws-iam-authenticator` also execute in the background

Before kubectl execute success I need to set or export ENV that will be use in that connection . I am setting those 2 ENV as a Context for the kubectl command to execute bcs in the background IAM will be executed an that command will need Access Credentials to connect to AWS . Bcs I don't have .aws/config so I have to config like this .

**Wrap up**: Kubectl get executed which will use kubeconfig files created in .kube/config and inside that config file it is configure that aws-IAM-authenticator need to be use in order to authenticate with AWS account . And when `aws-iam-authenticator` command get trigger in the background, it need `AWS_ACCESS_KEY` and `AWS_SECRET_ACCESS_KEY` (AWS Credentials)

NOTE : This part of authentication where I need the aws-iam-authenticator and setting AWS-crenditals in addition to Kubernetes Authentication it acctually specific to AWS . Other platform will have different way to authenticate

Now I can try to test by Deploy Nginx like this :

```
stage("Deploy with Kubernetes") {
  environment{
    AWS_ACCESS_KEY_ID = credentials('Aws_Access_Key_Id')
    AWS_SECRET_ACCESS_KEY = credentials('Aws_Secret_Access_Key')
  }
  steps {
    script {
      echo "Deploy Nginx ...."
      sh 'kubectl create deployment nginx-deployment --image=nginx'
    }
  }
}
```

Now I could see my Nginx running by using `kubectl get pods`

<img width="600" alt="Screenshot 2025-04-28 at 13 35 41" src="https://github.com/user-attachments/assets/02d3c324-9320-405f-958e-cfd6826c11a8" />

Next steps I will deploy my Java Application ....

#### Add AWS credentials on Jenkins for AWS account authentication

In this Deployment Stage I will pull Image from the ECR . In order to pull Image from ECR I need to login to ECR .

 - I need to create a AWS ECR credentials Secret Component for Kubernetes in able to fetch Image from ECR

 - I need to get AWS ECR Password : `aws ecr get-login-password --region us-west-1`

 - I need a AWS ECR Server endpoint: `https://565393037799.dkr.ecr.us-west-1.amazonaws.com`

 - Username would be : `AWS`

The command to create Secret component in Kubernetes is : 

```
kubectl create secret docker-registry <my-secrect-name> \
--docker-server=https://565393037799.dkr.ecr.us-west-1.amazonaws.com \
--docker-username=AWS \
--docker-password=<AWS-ECR-Password> \
```

#### Configure Kubernetes Deployment and Service Yaml files

Couple things that need for a Pipeline to deploy Image on Kubernetes : 

 - I need Kubernetes Configuration for my applications's deployment and service . Everytime I want to deploy a new version of my Application I need to create Deployment and Service

 - I am generating a new Image everytime Pipeline run. The image is actually dynamic . I need to set Image dynamically in K8s Configfile

   - To set image in Deployment file : `$IMAGE_NAME`. This is a ENV that I set in a Jenkinsfile.
  
   - Also set `imagePullPolicy : always` always set a new Image when the Pod start no matter that specific Image available in that Local

   - Also set Apps name bcs it repeat multiple times in the file : $APP_NAME .

   - In Jenkinsfile . I set `$IMAGE_NAME` as a ENV in the Version Incrementation Stage . Now I will also set `$APP_NAME` as a ENV in the Deploy Stage (can be in Global) by using `environment{}` blocks.

My Yaml file would look like this : 

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $APP_NAME
  labels:
    app: $APP_NAME
spec: 
  replicas: 2 
  selector:
    matchLabels:
      app: $APP_NAME 
  template:
    metadata:
      labels: 
        app: $APP_NAME
    spec: 
      imagePullSecrets: 
      - name: docker-ecr-authentication
      containers:
      - name: $APP-NAME
        image: $IMAGE_NAME
        imagePullPolicy: Always
        ports:
        - containerPort: 8080
        env: 
        - name: DB_USER
          valueFrom:
            secretKeyRef:
              name: java-secret
              key: DB_USER
        - name: DB_NAME 
          valueFrom: 
            secretKeyRef:
              name: java-secret
              key: DB_NAME
        - name: DB_SERVER
          valueFrom:
            configMapKeyRef:
              name: java-configmap
              key: database_server
        - name: DB_PWD
          valueFrom: 
            secretKeyRef:
              name: mysql
              key: mysql-password

---

apiVersion: v1
kind: Service
metadata: 
  name: java-app-service
spec:
  selector:
    app: $APP_NAME
  ports:
  - protocol: TCP
    port: 8080
    targetPort: 8080
```

#### Create Deployment Stage in Jenkinsfile

To pass value from Jenkinsfile to Yaml file: 

 - I use the command line tool call Environment Subsitute `envsubst`. This command actually used to substitute any variables define inside the file (in this case Yaml file) . And the syntax this command expect is `IMAGE_NAME`

 - This tool I need to install inside Jenkins Container:

   - SSH to Jenkins server : ssh root@
  
   - Get into Jenkins container : docker exec -it -u 0 <container-id> bash
  
   - Install gettext-base : apt-get install gettext-base
  
 - I pass a file to `envsubst` command `envsubst < config.yaml` . It will take that file and it will look for a syntax of `$` and name of Variable and it will try to match that name of the variable to any ENV defined in that context . Then it will create a temporary file with the values set and I will pipe that temporary file and pass it as a parameter like this : `envsubst < config.yaml | kubectl apply -f`

My Deployment Stage will look like this :

```
stage("Deploy with Kubernetes") {
  environment{
    AWS_ACCESS_KEY_ID = credentials('Aws_Access_Key_Id')
    AWS_SECRET_ACCESS_KEY = credentials('Aws_Secret_Access_Key')
    APP_NAME = "java-app"
  }
  steps {
    script {
      echo "Deploy Java Application ...."
      sh "envsubst < Kubernetes/java-app.yaml | kubectl apply -f -"
    }
  }
}
```

## Configure Autoscaling for EKS Cluster

Thing I need in order to create Auto Scaler 

 - I need Auto Scaling Group (Can change Min and Max anytime)

 - I need to Create Auto Scaler Policy

 - Then create Auto Scaler Role

 - Then I use OpenID Provider OIDC federated authentication allow my service to assume an IAM role and interact with AWS Service without have to store AWS_ACCESS_KEY and AWS_ACCESS_SECRET_KEY

 - This I will attach that to Service Account

This is my Auto Scaler Yaml files include : Service Account, Role, ClusterRoleBinding, RoleBinding and Deployment (https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml) 

#### Create custom Autoscaler Policy for my NodeGroup

In IAM -> go to Policy -> go to Create Policy -> Choose JSON then paste the custom list of Policy in there -> Then give it a name and create it

Custome list is the one that has a list of all the Permissions that we need to give NodeGroup IAM role for the autoscaling to work

After Policy created . Create OIDC for authentication

```
{
 "Version": "2012-10-17",
 "Statement": [
     {
         "Effect": "Allow",
         "Action": [
             "autoscaling:DescribeAutoScalingGroups",
             "autoscaling:DescribeAutoScalingInstances",
             "autoscaling:DescribeLaunchConfigurations",
             "autoscaling:DescribeScalingActivities",
             "ec2:DescribeImages",
             "ec2:DescribeInstanceTypes",
             "ec2:DescribeLaunchTemplateVersions",
             "ec2:GetInstanceTypesFromInstanceRequirements",
             "eks:DescribeNodegroup"
         ],
         "Resource": [
             "*"
         ]
     },
     {
         "Effect": "Allow",
         "Action": [
             "autoscaling:SetDesiredCapacity",
             "autoscaling:TerminateInstanceInAutoScalingGroup"
         ],
         "Resource": [
             "*"
         ]
     }
 ]
}
```

#### Create OIDC Provider

**Prerequisites:**

An Active EKS cluster (1.14 preferred since it is the latest) against which the user is able to run kubectl commands.

Cluster must consist of at least one worker node ASG.

**Create an IAM OIDC identity provider for your cluster with the AWS Management Console**

Open the Amazon EKS console.

In the left pane, select Clusters, and then select the name of your cluster on the Clusters page.

In the Details section on the Overview tab, note the value of the OpenID Connect provider URL.

Open the IAM console at `https://console.aws.amazon.com/iam/`.

In the left navigation pane, choose Identity Providers under Access management. If a Provider is listed that matches the URL for your cluster, then you already have a provider for your cluster. If a provider isn’t listed that matches the URL for your cluster, then you must create one.

To create a provider, choose Add provider.

For Provider type, select OpenID Connect.

For Provider URL, enter the OIDC provider URL for your cluster.

For Audience, enter sts.amazonaws.com.

(Optional) Add any tags, for example a tag to identify which cluster is for this provider.

Choose Add provider.

#### Create an IAM role for your service accounts in the console

Retrieve the OIDC issuer URL from the Amazon EKS console description of your cluster . It will look something identical to: 'https://oidc.eks.us-east-1.amazonaws.com/id/xxxxxxxxxx'

While creating a new IAM role, In the "Select type of trusted entity" section, choose "Web identity".

In the "Choose a web identity provider" section: For Identity provider, choose the URL for your cluster. For Audience, type sts.amazonaws.com.

In the "Attach Policy" section, select the policy to use for your service account, that you created in Section B above.

After the role is created, choose the role in the console to open it for editing.

Choose the "Trust relationships" tab, and then choose "Edit trust relationship". Edit the OIDC provider suffix and change it from :aud to :sub. Replace sts.amazonaws.com to your service account ID.

 - Service Account ID is : `system:serviceaccount:<namespace>:<service-account-name>`.

Update trust policy to finish.

#### Configure Tags on Autoscaling Group Automate created by AWS

Tags are also use in order for different Services or Component to Read and Detect some Information from each other . This is one of the case where we have Tags that auto scaler that we will deploy inside Kubernetes will require to auto Discover Autoscaling group in the AWS account . So the Cluster Autoscaler Component, which I gonna deploy inside Kubernetes Cluster, needs to communicate with auto scaling group . For this communication to happen the Cluster auto Scaler first needs to detect the auto scaling group from AWS . And it happen by using these 2 tags : k8s.io/cluster-autoscaler/eks-cluster-test, k8s.io/cluster-autoscaler/enable

#### Deploy Cluster Autoscaler

In that Yamlfile :

 - In the command part I have the Configuration where NodeGroup auto discover is configured using these tags : --node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/

 - In the Service Account section add the code below . This is how I attach Auto-scaler-role to Service Account .

  ```
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::565393037799:role/Auto-Scaler-Role
  ```

 - In the Deployment section add Region ENV :

  ```
  env:
  - name : AWS_REGION
    value : us-west-1
  ```

To check my Deployment : `kubectl get deployment -n kube-system cluster-autoscaler`

## Complete CI/CD with Terraform

### Provison EKS

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

#### Overview Provsion Terraform in CI/CD Pipelines

In previous use case which built a docker Image in a pipeline and then deployed that Image on a remote Server by using Kubernetes, I will take that use case and integrate Terraform in order to provision that remote server as part of CI/CD process

I will create a new `stage("provision server")` in Jenkinsfile . And this will be a part where Terraform will provison create the new Server for me so that I can deploy my application on it, which lets me automate that part of creating a remote server also using CI/CD pipeline . In order to do that I have to do a couple of thing .

 - First I need to create a Key-pair an SSH key pair for the server . Whenever I create an Instance I need to assign an SSH key pair so that I can SSH into that Server .

 - Second : Install Terraform inside Jenkins Container . Bcs I want to execute Terraform Command in Jenkins

 - After that I will create Terraform file inside my Project so I can execute terraform apply inside the folder where I have defined Terraform config files

 - **Best Practice** To include everything that my application needs, including the Infrastructure automation, application configuration automation, all of this code inside the application itself

#### Create SSH key-pair












