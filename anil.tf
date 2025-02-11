# provider "aws" {
#     region = "us-east-1"
# }

# resource "aws_vpc" "myvpc" {
#     cidr_block = "172.25.0.0/20"
#     tags = {
#         Name = "myterraformvpc"
#     }
# }

# resource "aws_subnet" "pub_sub" {
#     vpc_id = aws_vpc.myvpc.id
#     cidr_block = "172.25.0.0/24"
#     map_public_ip_on_launch = true
# }

# resource "aws_subnet" "priva_sub" {
#     vpc_id = aws_vpc.myvpc.id
#     cidr_block = "172.25.1.0/24"
#     map_public_ip_on_launch = false
# }

# resource "aws_internet_gateway" "igw" {
#     vpc_id = aws_vpc.myvpc.id
# }

# resource "aws_route_table" "myroute" {
#     vpc_id = aws_vpc.myvpc.id
#     route {
#         cidr_block = "0.0.0.0/0"
#         gateway_id = aws_internet_gateway.igw.id
#     }
# }

# resource "aws_route_table_association" "myrouteassociation" {
#     subnet_id = aws_subnet.pub_sub.id
#     route_table_id = aws_route_table.myroute.id
# }