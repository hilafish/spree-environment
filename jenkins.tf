resource "aws_instance" "jenkins" {
  ami                         = "${data.aws_ami.ubuntu.id}"
  instance_type               = "t2.medium"
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

provisioner "remote-exec" {
    inline = [
	  "sleep 30",
	  "sudo apt-get update",
      "sudo apt-get install -y python python-pip",
      "sudo pip install ansible",
      "sudo apt-get update",
      "sudo mkdir -p /etc/ansible/playbooks",
      "sudo mv /tmp/jenkins /etc/ansible/playbooks/",
#	  "PUBLIC_IP=$(curl "http://169.254.169.254/latest/meta-data/public-ipv4")",
#	  "sudo sed -i 's/jenkins_url: http://127.0.0.1:8080/jenkins_url: http://${PUBLIC_IP}:8080/g' /etc/ansible/playbooks/jenkins/jenkins-deploy.yml",
      "ansible-playbook --connection=local --inventory 127.0.0.1 /etc/ansible/playbooks/jenkins/jenkins-deploy.yml"
    ]
  }  
}