##################################################################################
# RESOURCES
##################################################################################


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


# INSTANCES #

resource "aws_instance" "k8s_master" {
  ami                         = "${data.aws_ami.ubuntu16.id}"
  instance_type               = "t2.medium"
  vpc_security_group_ids      = ["${aws_security_group.k8s-sg.id}"]
  associate_public_ip_address = true
  key_name                    = "${var.aws_key_name}"
  iam_instance_profile        = "${aws_iam_instance_profile.aws-iam-k8s-instance-profile.name}"
  
  connection {
    user        = "ubuntu"
    private_key = "${file(var.aws_private_key_path)}"
  }
				 
  tags {
    Name = "k8s_master"
	"kubernetes.io/cluster/kubernetes" = "owned"
    }
	
provisioner "file" {
    source      = "${path.module}/config/ansible/k8s/install-docker.yml"
    destination = "/tmp/install-docker.yml"
  }

provisioner "file" {
    source      = "${path.module}/config/ansible/k8s/k8s-common.yml"
    destination = "/tmp/k8s-common.yml"
  }

provisioner "file" {
    source      = "${path.module}/config/ansible/k8s/k8s-master.yml"
    destination = "/tmp/k8s-master.yml"
  }

provisioner "file" {
    source      = "${path.module}/config/k8s/pod.yaml"
    destination = "/tmp/pod.yaml"
  }

provisioner "file" {
    source      = "${path.module}/config/ansible/k8s/kubeadm.yaml.j2"
    destination = "/tmp/kubeadm.yaml.j2"
  }

provisioner "file" {
    source      = "${path.module}/config/ansible/k8s/20-cloud-provider.conf"
    destination = "/tmp/20-cloud-provider.conf"
  }
  
provisioner "file" {
    content = <<EOF
---
kubeadm_token: "gqv3y0.91c3dhvt24c2s63h"
k8s_master_ip: "${aws_instance.k8s_master.private_ip}"
                EOF
				
    destination = "/tmp/vars.yml"
}

provisioner "remote-exec" {
    inline = [
	  "sleep 30",
	  "sudo apt-get update",
      "sudo apt-get install -y python python-pip",
      "sudo pip install ansible",
      "sudo apt-get update",
      "sudo mkdir -p /etc/ansible/playbooks",
      "sudo mv /tmp/k8s-master.yml /tmp/k8s-common.yml /tmp/vars.yml /tmp/kubeadm.yaml.j2 /tmp/install-docker.yml /tmp/20-cloud-provider.conf /etc/ansible/playbooks/",
      "ansible-playbook --connection=local --inventory 127.0.0.1 /etc/ansible/playbooks/install-docker.yml",
      "ansible-playbook --connection=local --inventory 127.0.0.1 /etc/ansible/playbooks/k8s-common.yml",
      "ansible-playbook --connection=local --inventory 127.0.0.1 /etc/ansible/playbooks/k8s-master.yml",
	  "sudo mv /tmp/pod.yaml /etc/kubernetes",
	  "sleep 60",
	  "kubectl create -f /etc/kubernetes/pod.yaml"
    ]
  }  
}


resource "aws_instance" "k8s_minion" {
  count                       = 2
  ami                         = "${data.aws_ami.ubuntu16.id}"
  instance_type               = "t2.micro"
  vpc_security_group_ids      = ["${aws_security_group.k8s-sg.id}"]
  associate_public_ip_address = true
  key_name                    = "${var.aws_key_name}"
  iam_instance_profile        = "${aws_iam_instance_profile.aws-iam-k8s-instance-profile.name}"
  
  connection {
    user        = "ubuntu"
    private_key = "${file(var.aws_private_key_path)}"
  }
  
  tags {
    Name = "k8s_minion-${count.index + 1}"
	"kubernetes.io/cluster/kubernetes" = "owned"
    }
	
provisioner "file" {
    source      = "${path.module}/config/ansible/k8s/install-docker.yml"
    destination = "/tmp/install-docker.yml"
  }

provisioner "file" {
    source      = "${path.module}/config/ansible/k8s/k8s-common.yml"
    destination = "/tmp/k8s-common.yml"
  }

provisioner "file" {
    source      = "${path.module}/config/ansible/k8s/k8s-minion.yml"
    destination = "/tmp/k8s-minion.yml"
  }

provisioner "file" {
    source      = "${path.module}/config/ansible/k8s/20-cloud-provider.conf"
    destination = "/tmp/20-cloud-provider.conf"
  }
  
provisioner "file" {
    content = <<EOF
---
kubeadm_token: "gqv3y0.91c3dhvt24c2s63h"
k8s_master_ip: "${aws_instance.k8s_master.private_ip}"
EOF
				
    destination = "/tmp/vars.yml"

  }

provisioner "remote-exec" {
    inline = [
	  "sleep 30",
	  "sudo apt-get update",
      "sudo apt-get install -y python python-pip",
	  "sudo pip install ansible",
      "sudo apt-get update",
	  "sudo mkdir -p /etc/ansible/playbooks",
	  "sudo mv /tmp/vars.yml /tmp/k8s-minion.yml /tmp/k8s-common.yml /tmp/install-docker.yml /tmp/20-cloud-provider.conf /etc/ansible/playbooks/",
      "ansible-playbook --connection=local --inventory 127.0.0.1 /etc/ansible/playbooks/install-docker.yml",
	  "ansible-playbook --connection=local --inventory 127.0.0.1 /etc/ansible/playbooks/k8s-common.yml",
	  "ansible-playbook --connection=local --inventory 127.0.0.1 /etc/ansible/playbooks/k8s-minion.yml"

    ]
  }  
}

##################################################################################
# OUTPUT
##################################################################################


output "k8s_master_public_dns" {
    value = "${aws_instance.k8s_master.public_dns}"
}

output "minions_public_dns" {
    value = "${aws_instance.k8s_minion.*.public_dns}"
}