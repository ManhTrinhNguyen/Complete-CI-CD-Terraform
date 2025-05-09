output "vpc_object" {
  value = aws_vpc.myapp-vpc
}

output "rtb_object" {
  value = aws_route_table.myapp-route-table
}