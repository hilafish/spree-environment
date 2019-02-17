##################################################################################
# RESOURCES
##################################################################################

# INSTANCES #

resource "aws_instance" "k8s_master" {
  ami                         = "${data.aws_ami.ubuntu.id}"
  instance_type               = "t2.medium"
  vpc_security_group_ids      = ["${aws_security_group.k8s-sg.id}"]
  associate_public_ip_address = true
  key_name                    = "${var.aws_key_name}"
  iam_instance_profile        = "${aws_iam_instance_profile.aws-iam-k8s-instance-profile.name}"
  depends_on                  = ["aws_instance.MySQL_Master"]
  
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
    source      = "${path.module}/config/k8s/service.yaml"
    destination = "/tmp/service.yaml"
  }

provisioner "file" {
    source      = "${path.module}/config/k8s/deploy.yaml"
    destination = "/tmp/deploy.yaml"
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
    source      = "${path.module}/config/ansible/k8s/kubelet"
    destination = "/tmp/kubelet"
  }

provisioner "file" {
    source      = "${path.module}/config/k8s/my-secret.yaml"
    destination = "/tmp/my-secret.yaml"
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
      "sudo mv /tmp/k8s-master.yml /tmp/k8s-common.yml /tmp/vars.yml /tmp/kubeadm.yaml.j2 /tmp/install-docker.yml /tmp/20-cloud-provider.conf /tmp/kubelet /etc/ansible/playbooks/",
      "ansible-playbook --connection=local --inventory 127.0.0.1 /etc/ansible/playbooks/install-docker.yml",
      "ansible-playbook --connection=local --inventory 127.0.0.1 /etc/ansible/playbooks/k8s-common.yml",
      "ansible-playbook --connection=local --inventory 127.0.0.1 /etc/ansible/playbooks/k8s-master.yml",
	  "sudo mv /tmp/deploy.yaml /tmp/service.yaml /etc/kubernetes",
	  "sleep 60",
	  "kubectl create -f /etc/kubernetes/deploy.yaml",
	  "kubectl create -f /etc/kubernetes/service.yaml",
	  "kubectl create -f /tmp/my-secret.yaml",
	  "shred -v -n 25 -u -z /tmp/my-secret.yaml"
    ]
  }  
}


resource "aws_instance" "k8s_minion" {
  count                       = 2
  ami                         = "${data.aws_ami.ubuntu.id}"
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
    source      = "${path.module}/config/ansible/k8s/kubelet"
    destination = "/tmp/kubelet"
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
	  "sudo mv /tmp/k8s-minion.yml /tmp/k8s-common.yml /tmp/vars.yml /tmp/install-docker.yml /tmp/20-cloud-provider.conf /tmp/kubelet /etc/ansible/playbooks/",
      "ansible-playbook --connection=local --inventory 127.0.0.1 /etc/ansible/playbooks/install-docker.yml",
	  "ansible-playbook --connection=local --inventory 127.0.0.1 /etc/ansible/playbooks/k8s-common.yml",
	  "ansible-playbook --connection=local --inventory 127.0.0.1 /etc/ansible/playbooks/k8s-minion.yml"
    ]
  }  
}
