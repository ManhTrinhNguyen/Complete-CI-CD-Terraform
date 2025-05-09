
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
