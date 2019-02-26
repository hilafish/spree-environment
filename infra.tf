##################################################################################
# RESOURCES
##################################################################################

# INSTANCES #

resource "aws_instance" "consul_server" {
  count                  = 3
  ami                    = "${data.aws_ami.ubuntu.id}"
  instance_type          = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.consul-sg.id}"]
  key_name               = "${var.aws_key_name}"
# subnet_id              = "${aws_subnet.priv_subnet.id}"
  iam_instance_profile   = "${aws_iam_instance_profile.consul-server-instance-profile.name}"
# depends_on             = ["aws_nat_gateway.NATGW-Custom-VPC"]

  connection {
    user        = "ubuntu"
    private_key = "${file(var.aws_private_key_path)}"
  }

  tags {
    Name = "consul-server"
  }

  user_data = "${file("${path.module}/config/user-data/consul-server-userdata.sh")}"
   
}


resource "aws_instance" "elastic_search" {
  ami                    = "${data.aws_ami.ubuntu.id}"
  instance_type          = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.elastic-search-sg.id}"]
# subnet_id              = "${aws_subnet.priv_subnet.id}"
  key_name               = "${var.aws_key_name}"
  iam_instance_profile   = "${aws_iam_instance_profile.consul-server-instance-profile.name}"  
# depends_on             = ["aws_nat_gateway.NATGW-Custom-VPC"]
  depends_on             = ["aws_instance.consul_server"]

  connection {
    user        = "ubuntu"
    private_key = "${file(var.aws_private_key_path)}"
  }

  tags {
    Name = "elastic_search"
  }
  
  user_data     = "${data.template_file.elasticsearch-userdata.rendered}"
} 


resource "aws_instance" "MySQL_Master" {
  ami                         = "${data.aws_ami.ubuntu.id}"
  instance_type               = "t2.micro"
  vpc_security_group_ids      = ["${aws_security_group.MySQL-sg.id}"]
  private_ip                  = "172.31.17.9"
  associate_public_ip_address = true
  key_name                    = "${var.aws_key_name}"
  iam_instance_profile        = "${aws_iam_instance_profile.consul-server-instance-profile.name}" 
# subnet_id                   = "${aws_subnet.priv_subnet.id}"
  depends_on                  = ["aws_instance.consul_server"]

  connection {
    user        = "ubuntu"
    private_key = "${file(var.aws_private_key_path)}"
  }

  tags {
    Name = "MySQL_Master"
  }

  user_data = "${file("${path.module}/config/user-data/mysql-master-userdata.sh")}"
  
}



##################################################################################
# OUTPUT
##################################################################################

output "MySQL_public_ip" {
  value = "${aws_instance.MySQL_Master.public_ip}"
}

output "k8s_master_public_dns" {
    value = "${aws_instance.k8s_master.public_dns}"
}

output "minions_public_dns" {
    value = "${aws_instance.k8s_minion.*.public_dns}"
}

output "elastic_public_ip" {
  value = "${aws_instance.elastic_search.public_ip}"
}