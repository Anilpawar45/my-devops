provider "aws" {
  region = "us-east-1" 
}

# Create a VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# Create a public subnet
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}

# Create an Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

# Create a route table for the public subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

# Associate the route table with the public subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Group for HTTPD instances
resource "aws_security_group" "httpd_sg" {
  name        = "httpd_sg"
  description = "Allow HTTP and SSH traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Launch Template for HTTPD instances
resource "aws_launch_template" "httpd_lt" {
  name_prefix   = "httpd-lt-"
  image_id      = "ami-04b4f1a9cf54c11d0" 
  instance_type = "t2.micro"
  key_name      = "anil" 

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.httpd_sg.id]
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Hello from $(hostname -f)</h1>" > /var/www/html/index.html
              EOF
  )

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "httpd-instance"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "httpd_asg" {
  name                = "httpd-asg"
  min_size            = 2
  max_size            = 4
  desired_capacity    = 2
  vpc_zone_identifier = [aws_subnet.public.id]

  launch_template {
    id      = aws_launch_template.httpd_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "httpd-instance"
    propagate_at_launch = true
  }
}

# Load Balancer
resource "aws_lb" "httpd_lb" {
  name               = "httpd-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.httpd_sg.id]
  subnets            = [aws_subnet.public.id]
}

# Target Group for Load Balancer
resource "aws_lb_target_group" "httpd_tg" {
  name     = "httpd-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
  }
}

# Attach Auto Scaling Group to Target Group
resource "aws_autoscaling_attachment" "httpd_asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.httpd_asg.name
  lb_target_group_arn   = aws_lb_target_group.httpd_tg.arn
}

# Load Balancer Listener
resource "aws_lb_listener" "httpd_listener" {
  load_balancer_arn = aws_lb.httpd_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.httpd_tg.arn
  }
}

# Output the Load Balancer DNS Name
output "load_balancer_dns" {
  value = aws_lb.httpd_lb.dns_name
}