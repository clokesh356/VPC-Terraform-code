resource "aws_security_group" "alb" {
  name        = "allow_enduser"
  description = "Allow enduser "
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "TLS enduser from admin"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name      = "stage-alb-sg"
    Terraform = "true"
  }
}
