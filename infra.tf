##################################################################################
# RESOURCES
##################################################################################

# INSTANCES #


resource "aws_instance" "bastion" {
  ami                         = "${data.aws_ami.ubuntu.id}"
  instance_type               = "t2.micro"
#  subnet_id                   = "${aws_subnet.pub_subnet.id}"
  vpc_security_group_ids      = ["${aws_security_group.bastion-sg.id}"]
  associate_public_ip_address = true
  key_name                    = "${var.aws_key_name}"
  
  connection {
    user        = "ubuntu"
    private_key = "${file(var.aws_private_key_path)}"
  }
  
  tags {
    Name = "bastion"
    }
}

resource "aws_instance" "consul_server" {
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


resource "aws_instance" "prometheus" {
  ami                    = "${data.aws_ami.ubuntu.id}"
  instance_type          = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.prometheus-sg.id}"]
  key_name               = "${var.aws_key_name}"
  iam_instance_profile   = "${aws_iam_instance_profile.consul-server-instance-profile.name}"    
#  subnet_id              = "${aws_subnet.priv_subnet.id}"
  depends_on             = ["aws_instance.consul_server"]
# also depends on "aws_nat_gateway.NATGW-Custom-VPC"

  connection {
    user        = "ubuntu"
    private_key = "${file(var.aws_private_key_path)}"
  }

  tags {
    Name = "prometheus"
  }

  user_data = "${data.template_file.prometheus-userdata.rendered}"

}


resource "aws_instance" "kibana_grafana" {
  ami                         = "${data.aws_ami.ubuntu.id}"
  instance_type               = "t2.micro"
  vpc_security_group_ids      = ["${aws_security_group.kibana-grafana-sg.id}"]
  associate_public_ip_address = true
  key_name                    = "${var.aws_key_name}"
  iam_instance_profile   = "${aws_iam_instance_profile.consul-server-instance-profile.name}"    
#  subnet_id                   = "${aws_subnet.pub_subnet.id}"
  depends_on                  = ["aws_instance.consul_server", "aws_instance.elastic_search", "aws_instance.prometheus", "aws_instance.kibana_grafana"]

  connection {
    user        = "ubuntu"
    private_key = "${file(var.aws_private_key_path)}"
  }

  tags {
    Name = "kibana_grafana"
  }

  provisioner "file" {
    source     = "${path.module}/config/kibana/kibana.yml"
    destination = "/tmp/kibana.yml"
  }

  provisioner "file" {
    source      = "${path.module}/config/kibana/kibana_dashboard.json"
    destination = "/tmp/kibana_dashboard.json"
  }

  provisioner "file" {
    source     = "${path.module}/config/grafana/prometheus_datasource.yaml"
    destination = "/tmp/prometheus_datasource.yaml"
  }

  provisioner "file" {
    source      = "${path.module}/config/grafana/prometheus_dashboards.yaml"
    destination = "/tmp/prometheus_dashboards.yaml"
  }

  provisioner "file" {
    source      = "${path.module}/config/grafana/grafana_system_dashboard.json"
    destination = "/tmp/grafana_system_dashboard.json"
  }

  user_data = "${data.template_file.kibana_grafana-userdata.rendered}"
}


##################################################################################
# OUTPUT
##################################################################################

output "bastion_public_ip" {
  value = "${aws_instance.bastion.public_ip}"
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

output "kibana_grafana_public_ip" {
  value = "${aws_instance.kibana_grafana.public_ip}"
}

output "prometheus_public_ip" {
  value = "${aws_instance.prometheus.public_ip}"
}
