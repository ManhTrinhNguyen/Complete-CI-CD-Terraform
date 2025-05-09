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
  route_table_id = module.myapp-vpc.rtb_object.id
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