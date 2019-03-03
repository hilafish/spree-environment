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

data "aws_availability_zones" "available" {}

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


data "template_file" "k8s-secret" {
  template = "${file("${path.module}/config/k8s/my-secret.yaml.tpl")}"

  vars {
	K8S_SECRET                = "${var.k8s_secret}"
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
    CHECKPOINT_URL            = "https://checkpoint-api.hashicorp.com/v1/check"
    LOCAL_IPV4                = "$${LOCAL_IPV4}"
    CONSUL_VERSION            = "$${CONSUL_VERSION}"
    DATACENTER_NAME           = "OpsSchool"	
  }
}