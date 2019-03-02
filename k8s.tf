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
  depends_on                  = ["aws_instance.consul_server","aws_instance.MySQL_Master"]
  
  connection {
    user        = "ubuntu"
    private_key = "${file(var.aws_private_key_path)}"
  }
				 
  tags {
    Name = "k8s_master"
	"kubernetes.io/cluster/kubernetes" = "owned"
    }
	
  provisioner "file" {
    source     = "${path.module}/config/ansible/k8s/common"
    destination = "/tmp"
	
    connection {
        type = "ssh"   
        host = "${self.private_ip}" 
        user = "ubuntu"	  
        private_key = "${file(var.aws_private_key_path)}"
  	    timeout = "1m"
  	    agent = false
     
        bastion_host = "${aws_instance.bastion.public_ip}"
  	    bastion_port = 22
        bastion_user = "ubuntu"
        bastion_private_key = "${file(var.aws_private_key_path)}"
    }	
  } 

  provisioner "file" {
    source      = "${path.module}/config/ansible/k8s/k8s-master.yml"
    destination = "/tmp/k8s-master.yml"
	
    connection {
        type = "ssh"   
        host = "${self.private_ip}" 
        user = "ubuntu"	  
        private_key = "${file(var.aws_private_key_path)}"
  	    timeout = "1m"
  	    agent = false
     
        bastion_host = "${aws_instance.bastion.public_ip}"
  	    bastion_port = 22
        bastion_user = "ubuntu"
        bastion_private_key = "${file(var.aws_private_key_path)}"
    }	
  }

  provisioner "file" {
    source     = "${path.module}/config/k8s"
    destination = "/tmp"
	
    connection {
        type = "ssh"   
        host = "${self.private_ip}" 
        user = "ubuntu"	  
        private_key = "${file(var.aws_private_key_path)}"
  	    timeout = "1m"
  	    agent = false
     
        bastion_host = "${aws_instance.bastion.public_ip}"
  	    bastion_port = 22
        bastion_user = "ubuntu"
        bastion_private_key = "${file(var.aws_private_key_path)}"
    }	
  }

  provisioner "file" {
    content     = "${data.template_file.k8s-secret.rendered}"
    destination = "/tmp/secret.yaml"

    connection {
        type = "ssh"   
        host = "${self.private_ip}" 
        user = "ubuntu"	  
        private_key = "${file(var.aws_private_key_path)}"
  	    timeout = "1m"
  	    agent = false
     
        bastion_host = "${aws_instance.bastion.public_ip}"
  	    bastion_port = 22
        bastion_user = "ubuntu"
        bastion_private_key = "${file(var.aws_private_key_path)}"
    }
  }
  
provisioner "file" {
    content = <<EOF
---
kubeadm_token: "gqv3y0.91c3dhvt24c2s63h"
k8s_master_ip: "${aws_instance.k8s_master.private_ip}"
jenkins_public_ssh_key: "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDRf/6fsLlZVA1H1TxvLbDdq4DVuCvcRAwV6JbpWarYapF56JDcpHkazHWnIKz79rR8tYjS4UwhWB4K1JEV9mykJ8MXAhgHe8pd8ZoLh5DL998zkSmtUsIjQ822ACdJENL7KS9SYbVI1T6y2Dk5MI4/Ub1zixxGxukEjm4BzH1XTsOsFgAp53vi8q5cBEz15Z5FT+wSwVz+206SjZXeo3OnOkoMZrVCO8hPA2j7XYYqXhemWe2WNpX9mBvpvl9PrATJbfEFi+F6f6HaatfsEwe9NTnbFuUR75eiN3fMTIdJvCLcdTuxqj2DLA/yQrQfLEskT/+f/vuzfj40qXCVpcpx jenkins@jenkins_server"
                EOF
				
    destination = "/tmp/vars.yml"
	
    connection {
        type = "ssh"   
        host = "${self.private_ip}" 
        user = "ubuntu"	  
        private_key = "${file(var.aws_private_key_path)}"
  	    timeout = "1m"
  	    agent = false
     
        bastion_host = "${aws_instance.bastion.public_ip}"
  	    bastion_port = 22
        bastion_user = "ubuntu"
        bastion_private_key = "${file(var.aws_private_key_path)}"
    }	
}

provisioner "remote-exec" {
    inline = [
	  "sleep 30",
	  "sudo apt-get update",
      "sudo apt-get install -y python python-pip",
      "sudo pip install ansible",
      "sudo apt-get update",
      "sudo mkdir -p /etc/ansible/playbooks",
      "sudo mv /tmp/k8s-master.yml /tmp/common/* /tmp/vars.yml /etc/ansible/playbooks/",
      "ansible-playbook --connection=local --inventory 127.0.0.1 /etc/ansible/playbooks/install-docker.yml",
      "ansible-playbook --connection=local --inventory 127.0.0.1 /etc/ansible/playbooks/k8s-common.yml",
      "ansible-playbook --connection=local --inventory 127.0.0.1 /etc/ansible/playbooks/k8s-master.yml",
	  "sleep 60",
	  "kubectl create -f /tmp/secret.yaml",	  
	  "kubectl create -f /tmp/k8s/deploy.yaml",
	  "sleep 30",
	  "kubectl create -f /tmp/k8s/service.yaml",
	  "shred -v -n 25 -u -z /tmp/secret.yaml"
    ]

    connection {
        type = "ssh"   
        host = "${self.private_ip}" 
        user = "ubuntu"	  
        private_key = "${file(var.aws_private_key_path)}"
  	    timeout = "1m"
  	    agent = false
     
        bastion_host = "${aws_instance.bastion.public_ip}"
  	    bastion_port = 22
        bastion_user = "ubuntu"
        bastion_private_key = "${file(var.aws_private_key_path)}"
      } 	
  } 

  user_data = "${data.template_file.k8s-master-userdata.rendered}"  
}


resource "aws_instance" "k8s_minion" {
  count                       = 2
  ami                         = "${data.aws_ami.ubuntu.id}"
  instance_type               = "t2.medium"
  vpc_security_group_ids      = ["${aws_security_group.k8s-sg.id}"]
  associate_public_ip_address = true
  key_name                    = "${var.aws_key_name}"
  iam_instance_profile        = "${aws_iam_instance_profile.aws-iam-k8s-instance-profile.name}"
  depends_on                  = ["aws_instance.consul_server","aws_instance.MySQL_Master"]
  
  connection {
    user        = "ubuntu"
    private_key = "${file(var.aws_private_key_path)}"
  }
  
  tags {
    Name = "k8s_minion-${count.index + 1}"
	"kubernetes.io/cluster/kubernetes" = "owned"
    }
	
  provisioner "file" {
    source     = "${path.module}/config/ansible/k8s/common"
    destination = "/tmp"
	
    connection {
        type = "ssh"   
        host = "${self.private_ip}" 
        user = "ubuntu"	  
        private_key = "${file(var.aws_private_key_path)}"
  	    timeout = "1m"
  	    agent = false
     
        bastion_host = "${aws_instance.bastion.public_ip}"
  	    bastion_port = 22
        bastion_user = "ubuntu"
        bastion_private_key = "${file(var.aws_private_key_path)}"
    }	
  } 


  provisioner "file" {
      source      = "${path.module}/config/ansible/k8s/k8s-minion.yml"
      destination = "/tmp/k8s-minion.yml"
	  
    connection {
        type = "ssh"   
        host = "${self.private_ip}" 
        user = "ubuntu"	  
        private_key = "${file(var.aws_private_key_path)}"
  	    timeout = "1m"
  	    agent = false
     
        bastion_host = "${aws_instance.bastion.public_ip}"
  	    bastion_port = 22
        bastion_user = "ubuntu"
        bastion_private_key = "${file(var.aws_private_key_path)}"
    }		  
  }  
  
  provisioner "file" {
      content = <<EOF
---
kubeadm_token: "gqv3y0.91c3dhvt24c2s63h"
k8s_master_ip: "${aws_instance.k8s_master.private_ip}"
                  EOF
				
    destination = "/tmp/vars.yml"
	
    connection {
        type = "ssh"   
        host = "${self.private_ip}" 
        user = "ubuntu"	  
        private_key = "${file(var.aws_private_key_path)}"
  	    timeout = "1m"
  	    agent = false
     
        bastion_host = "${aws_instance.bastion.public_ip}"
  	    bastion_port = 22
        bastion_user = "ubuntu"
        bastion_private_key = "${file(var.aws_private_key_path)}"
    }		
 }

provisioner "remote-exec" {
    inline = [
	  "sleep 30",
	  "sudo apt-get update",
      "sudo apt-get install -y python python-pip",
	  "sudo pip install ansible",
      "sudo apt-get update",
	  "sudo mkdir -p /etc/ansible/playbooks",
	  "sudo mv /tmp/k8s-minion.yml /tmp/common/* /tmp/vars.yml /etc/ansible/playbooks/",
      "ansible-playbook --connection=local --inventory 127.0.0.1 /etc/ansible/playbooks/install-docker.yml",
	  "ansible-playbook --connection=local --inventory 127.0.0.1 /etc/ansible/playbooks/k8s-common.yml",
	  "ansible-playbook --connection=local --inventory 127.0.0.1 /etc/ansible/playbooks/k8s-minion.yml"
    ]
	
    connection {
        type = "ssh"   
        host = "${self.private_ip}" 
        user = "ubuntu"	  
        private_key = "${file(var.aws_private_key_path)}"
  	    timeout = "1m"
  	    agent = false
     
        bastion_host = "${aws_instance.bastion.public_ip}"
  	    bastion_port = 22
        bastion_user = "ubuntu"
        bastion_private_key = "${file(var.aws_private_key_path)}"
      } 	
  } 
  
  user_data = "${data.template_file.k8s-minion-userdata.rendered}"    
}
