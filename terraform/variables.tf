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