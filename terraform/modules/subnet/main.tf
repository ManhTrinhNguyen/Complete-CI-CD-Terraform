
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