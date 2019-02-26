# SECURITY GROUPS #

# Kubernetes security group 
resource "aws_security_group" "k8s-sg" {
  name        = "k8s_sg"

  # access from anywhere
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9100
    to_port     = 9100
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
  
  tags {
    Name = "k8s_sg"
	"kubernetes.io/cluster/kubernetes" = "owned"
    }
}


# ELB security group
#resource "aws_security_group" "k8s-svc-elb-sg" {
#  name        = "k8s_svc_elb_sg"
#  vpc_id      = "${aws_vpc.Oregon-VPC.id}"
#
#  #Allow HTTP from anywhere
#  ingress {
#    from_port   = 3000
#    to_port     = 3000
#    protocol    = "tcp"
#    cidr_blocks = ["0.0.0.0/0"]
#  }
#
#  #allow all outbound
#  egress {
#    from_port   = 0
#    to_port     = 0
#    protocol    = "-1"
#    cidr_blocks = ["0.0.0.0/0"]
#  }
#}


resource "aws_security_group" "MySQL-sg" {
  name   = "MySQL_sg"
# vpc_id = "${aws_vpc.Custom-VPC.id}"

  # access from anywhere

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["37.142.210.45/32"]
  }  

  ingress {
    from_port   = 9100
    to_port     = 9100
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

resource "aws_security_group" "consul-sg" {
  name   = "consul_sg"
# vpc_id = "${aws_vpc.Custom-VPC.id}"

  # access from anywhere

  ingress {
    from_port   = 8300
    to_port     = 8600
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["37.142.210.45/32"]
  }  

  ingress {
    from_port   = 9100
    to_port     = 9100
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

resource "aws_security_group" "elastic-search-sg" {
  name   = "elastic_search_sg"
# vpc_id = "${aws_vpc.Custom-VPC.id}"

  # access from anywhere
  ingress {
    from_port   = 9200
    to_port     = 9200
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["37.142.210.45/32"]
  }  
  
  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "jenkins-sg" {
  name   = "jenkins_sg"
# vpc_id = "${aws_vpc.Custom-VPC.id}"

  # access from Git for Webhooks
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["192.30.252.0/22"]
  }
  # access from Git #2 for Webhooks
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["185.199.108.0/22"]
  }
  # access from Git #3 for Webhooks
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["140.82.112.0/20"]
  }  

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["37.142.210.45/32"]
  }  

  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["37.142.210.45/32"]
  }  
  
  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
