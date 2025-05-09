
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
  subnet_id = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  availability_zone = var.availability_zone

  associate_public_ip_address = true

  key_name = "terraform"

  user_data = file("./entry_script.sh")

  user_data_replace_on_change = true
  tags = {
    Name = "${var.env_prefix}-myapp"
  }
}