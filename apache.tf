# data "http" "myip" {
#   url = "http://ipv4.icanhazip.com"
#}
# data "aws_vpc" "stage" {
#      filter {
#     name = "tag:Name"
#     values = ["stage-vpc"]
#   }
# }
#apache security group
#apache ec2
resource "aws_security_group" "apache" {
  name        = "allow_http"
  description = "Allow enduser"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description     = "allow for alb"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }
  ingress {
    description     = "ssh for admin"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name      = "stage-apache-sg"
    Terraform = "true"
  }
}
resource "aws_instance" "apache" {
  ami           = "ami-0b89f7b3f054b957e"
  instance_type = "t2.micro"
  #   vpc_id =aws_vpc.vpc.id
  subnet_id              = aws_subnet.private[0].id
  vpc_security_group_ids = [aws_security_group.apache.id]

  tags = {
    Name = "stage-apache"
  }
}