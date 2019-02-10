# SECURITY GROUPS #

resource "aws_security_group" "MySQL" {
  name   = "MySQL_sg"
#  vpc_id = "${aws_vpc.Custom-VPC.id}"

  # access from anywhere

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
