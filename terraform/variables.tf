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
  default = "71.202.102.216/32"
}

variable "availability_zone" {
  default = "us-west-1a"
}

variable "instance_type" {
  default = "t3.medium"
}

variable "region" {
  default = "us-west-1"
}