resource "aws_instance" "jenkins" {
  ami                         = "${data.aws_ami.ubuntu.id}"
  instance_type               = "t2.micro"
  vpc_security_group_ids      = ["${aws_security_group.jenkins-sg.id}"]
  associate_public_ip_address = true
  key_name                    = "${var.aws_key_name}"
  iam_instance_profile        = "${aws_iam_instance_profile.consul-server-instance-profile.name}"
  
  connection {
    user        = "ubuntu"
    private_key = "${file(var.aws_private_key_path)}"
  }
				 
  tags {
    Name = "jenkins"
    }
	
  provisioner "file" {
    source      = "${path.module}/config/ansible/jenkins"
    destination = "/tmp"
  }

  provisioner "file" {
    source      = "${path.module}/config/mysql/spree_all.sql"
    destination = "/tmp/spree_all.sql"
  }
  
  provisioner "remote-exec" {
    inline = [
      "sleep 30",
      "sudo apt-get update",
      "sudo apt-get install -y python python-pip",
      "sudo pip install ansible",
      "sudo apt-get update",
      "sudo mkdir -p /etc/ansible/playbooks",
      "echo ${var.vault_pass} > /tmp/ansible_vault_pass",
      "chmod 400 /tmp/ansible_vault_pass",
      "sudo mv /tmp/jenkins /etc/ansible/playbooks/",
      "PUBLIC_IP=$(curl \"http://169.254.169.254/latest/meta-data/public-ipv4\")",
      "sudo sed -i \"s/127.0.0.1/$${PUBLIC_IP}/g\" /etc/ansible/playbooks/jenkins/jenkins-configs/github-plugin-configuration.xml",
      "ansible-playbook --connection=local --vault-password-file=/tmp/ansible_vault_pass --inventory 127.0.0.1 /etc/ansible/playbooks/jenkins/jenkins-deploy.yml",
      "sudo shred -v -n 25 -u -z /tmp/ansible_vault_pass"
    ]
  }

  user_data = "${data.template_file.jenkins-userdata.rendered}"  
}


###################################################################################
## OUTPUT
###################################################################################

output "Jenkins_public_ip" {
  value = "${aws_instance.jenkins.public_ip}"
}
