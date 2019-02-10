##################################################################################
# VARIABLES
##################################################################################

variable "Custom-VPC_address_space" {
  default = "10.1.0.0/16"
}

##################################################################################
# RESOURCES
##################################################################################

# NETWORKING #
resource "aws_vpc" "Custom-VPC" {
  cidr_block = "${var.Custom-VPC_address_space}"
  enable_dns_support = true
  enable_dns_hostnames = true
  
  tags {
    Name        = "VPC-Custom"
  }
}

resource "aws_internet_gateway" "IGW-Custom-VPC" {
  vpc_id = "${aws_vpc.Custom-VPC.id}"

  tags {
    Name        = "IGW-VPC-Custom"
  }
}

resource "aws_eip" "Custom-VPC-nat_eip" {
  vpc      = true
  depends_on = ["aws_internet_gateway.IGW-Custom-VPC"]
  
  tags {
    Name = "VPC-NAT_EIP-Custom"
  }
}

resource "aws_nat_gateway" "NATGW-Custom-VPC" {
  allocation_id = "${aws_eip.Custom-VPC-nat_eip.id}"
  subnet_id     = "${aws_subnet.pub_subnet.id}"
  
  tags {
    Name = "NATGW-Custom-VPC"
  }
  
  depends_on = ["aws_internet_gateway.IGW-Custom-VPC"]
}

resource "aws_subnet" "pub_subnet" {
  cidr_block              = "${cidrsubnet(var.Custom-VPC_address_space, 8, count.index + 1)}"
  vpc_id                  = "${aws_vpc.Custom-VPC.id}"
  map_public_ip_on_launch = "true"

  tags {
    Name        = "pub_subnet-VPC-Custom"
  }
}

resource "aws_subnet" "priv_subnet" {
  cidr_block              = "${cidrsubnet(var.Custom-VPC_address_space, 8, count.index + 3)}"
  vpc_id                  = "${aws_vpc.Custom-VPC.id}"
  map_public_ip_on_launch = "false"

  tags {
    Name        = "priv_subnet-VPC-Custom"
  }
}

# ROUTING #
resource "aws_route_table" "Custom-VPC-pub-rt" {
  vpc_id = "${aws_vpc.Custom-VPC.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.IGW-Custom-VPC.id}"
  }
  
  tags {
    Name        = "pub-rt-VPC-Custom"
  }
}

resource "aws_route_table_association" "Custom-VPC-pub-rta" {
  subnet_id      = "${aws_subnet.pub_subnet.id}"
  route_table_id = "${aws_route_table.Custom-VPC-pub-rt.id}"
}

resource "aws_route_table" "Custom-VPC-priv-rt" {
  vpc_id = "${aws_vpc.Custom-VPC.id}"

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.NATGW-Custom-VPC.id}"
  }
  
  tags {
    Name = "priv-rt-VPC-Custom"
    }
}

resource "aws_route_table_association" "Custom-VPC-priv-rta" {
  subnet_id      = "${aws_subnet.priv_subnet.id}"
  route_table_id = "${aws_route_table.Custom-VPC-priv-rt.id}"
}
