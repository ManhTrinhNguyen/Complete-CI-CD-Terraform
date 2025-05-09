output "ec2_public_ip" {
  value = module.myapp-ec2.ec2_object.public_ip
}