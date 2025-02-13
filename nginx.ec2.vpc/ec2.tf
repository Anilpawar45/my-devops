
# EC2 instance For Nginx setup
resource "aws_instance" "nginxserver" {
  ami                         = "ami-00bb6a80f01f03502"
  instance_type               = "t3.nano"
  key_name                    = "anil"
  subnet_id                   = aws_subnet.public-subnet.id
  vpc_security_group_ids      = [aws_security_group.nginx-sg.id]
  associate_public_ip_address = true

  user_data = file("userdata.sh")

  tags = {
    Name = "NginxServer"
  }
}