##################################################################################
# RESOURCES
##################################################################################

# INSTANCES #



resource "aws_instance" "MySQL_Master" {
  ami                         = "${data.aws_ami.ubuntu.id}"
  instance_type               = "t2.micro"
  vpc_security_group_ids      = ["${aws_security_group.MySQL-sg.id}"]
  private_ip                  = "172.31.17.9"
  associate_public_ip_address = true
  key_name                    = "${var.aws_key_name}"
  iam_instance_profile        = "${aws_iam_instance_profile.consul-server-instance-profile.name}" 
# subnet_id                   = "${aws_subnet.priv_subnet.id}"
  depends_on                  = ["aws_instance.consul_server", "aws_instance.bastion"]

  connection {
    user        = "ubuntu"
    private_key = "${file(var.aws_private_key_path)}"
  }

  tags {
    Name = "MySQL_Master"
  }
 
  provisioner "file" {
    source     = "${path.module}/config/mysql"
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
  
  provisioner "remote-exec" {
      script = "${path.module}/config/mysql/run_all_master.sh"
	
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
}



resource "aws_instance" "MySQL_Slave" {
  ami                         = "${data.aws_ami.ubuntu.id}"
  instance_type               = "t2.micro"
  vpc_security_group_ids      = ["${aws_security_group.MySQL-sg.id}"]
  private_ip                  = "172.31.17.10"
  associate_public_ip_address = true
  key_name                    = "${var.aws_key_name}"
  iam_instance_profile        = "${aws_iam_instance_profile.consul-server-instance-profile.name}" 
# subnet_id                   = "${aws_subnet.priv_subnet.id}"
  depends_on                  = ["aws_instance.consul_server", "aws_instance.bastion", "aws_instance.MySQL_Master"]

  connection {
    user        = "ubuntu"
    private_key = "${file(var.aws_private_key_path)}"
  }

  tags {
    Name = "MySQL_Slave"
  }
 
  provisioner "file" {
    source     = "${path.module}/config/mysql"
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
  
  provisioner "remote-exec" {
      script = "${path.module}/config/mysql/run_all_slave.sh"
	
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
}









##################################################################################
# OUTPUT
##################################################################################

output "MySQL_public_ip" {
  value = "${aws_instance.MySQL_Master.public_ip}"
}

