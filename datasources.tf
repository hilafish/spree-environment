##################################################################################
# DATA
##################################################################################

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


data "template_file" "elasticsearch-userdata" {
  template = "${file("${path.module}/config/user-data/elasticsearch-userdata.sh.tpl")}"

  vars {
    CHECKPOINT_URL            = "https://checkpoint-api.hashicorp.com/v1/check"
    LOCAL_IPV4                = "$${LOCAL_IPV4}"
    CONSUL_VERSION            = "$${CONSUL_VERSION}"
    DATACENTER_NAME           = "OpsSchool"
  }
}

data "template_file" "jenkins-userdata" {
  template = "${file("${path.module}/config/user-data/jenkins-userdata.sh.tpl")}"

  vars {
    CHECKPOINT_URL            = "https://checkpoint-api.hashicorp.com/v1/check"
    LOCAL_IPV4                = "$${LOCAL_IPV4}"
    CONSUL_VERSION            = "$${CONSUL_VERSION}"
    DATACENTER_NAME           = "OpsSchool"
  }
}


data "template_file" "k8s-master-userdata" {
  template = "${file("${path.module}/config/user-data/k8s-master-userdata.sh.tpl")}"

  vars {
    CHECKPOINT_URL            = "https://checkpoint-api.hashicorp.com/v1/check"
    LOCAL_IPV4                = "$${LOCAL_IPV4}"
    CONSUL_VERSION            = "$${CONSUL_VERSION}"
    DATACENTER_NAME           = "OpsSchool"
  }
}


data "template_file" "k8s-minion-userdata" {
  template = "${file("${path.module}/config/user-data/k8s-minion-userdata.sh.tpl")}"

  vars {
    CHECKPOINT_URL            = "https://checkpoint-api.hashicorp.com/v1/check"
    LOCAL_IPV4                = "$${LOCAL_IPV4}"
    CONSUL_VERSION            = "$${CONSUL_VERSION}"
    DATACENTER_NAME           = "OpsSchool"
  }
}


data "template_file" "prometheus-userdata" {
  template = "${file("${path.module}/config/user-data/prometheus-userdata.sh.tpl")}"

  vars {
    CHECKPOINT_URL            = "https://checkpoint-api.hashicorp.com/v1/check"
    LOCAL_IPV4                = "$${LOCAL_IPV4}"
    CONSUL_VERSION            = "$${CONSUL_VERSION}"
    DATACENTER_NAME           = "OpsSchool"
	EC2_ACCESS_KEY            = "${var.prom_scraping_ec2_access_key}"
	EC2_SECRET_KEY            = "${var.prom_scraping_ec2_secret_key}"
	}
}


data "template_file" "kibana_grafana-userdata" {
  template = "${file("${path.module}/config/user-data/kibana_grafana-userdata.sh.tpl")}"

  vars {
    LOCAL_IPV4 = "$${LOCAL_IPV4}"
    elastic_search_private_ip = "${aws_instance.elastic_search.private_ip}"
    CHECKPOINT_URL            = "https://checkpoint-api.hashicorp.com/v1/check"
    LOCAL_IPV4                = "$${LOCAL_IPV4}"
    CONSUL_VERSION            = "$${CONSUL_VERSION}"
    DATACENTER_NAME           = "OpsSchool"	
  }
}

#data "template_file" "base-server-userdata" {
#  template = "${file("${path.module}/config/user-data/base-server-userdata.sh.tpl")}"
#
#  vars {
#    CHECKPOINT_URL            = "https://checkpoint-api.hashicorp.com/v1/check"
#    LOCAL_IPV4                = "$${LOCAL_IPV4}"
#    CONSUL_VERSION            = "$${CONSUL_VERSION}"
#    DATACENTER_NAME           = "OpsSchool"
#  }
#}

#data "template_cloudinit_config" "elasticsearch" {
#  gzip          = true
#  base64_encode = true
#  
#  # get first user_data
#  part {
#    content_type = "text/cloud-config"
#    content      = "${data.template_file.base-server-userdata.rendered}"
#  }
#
#  # get second user_data - works without vars
#  part {
#    content_type = "text/x-shellscript"
#    content      = "${data.template_file.elasticsearch-userdata.rendered}"
#  }
#}
