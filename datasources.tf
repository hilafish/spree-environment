##################################################################################
# DATA
##################################################################################

data "aws_ami" "ubuntu16" {
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

data "aws_ami" "ubuntu14" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
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

