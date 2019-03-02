##################################################################################
# VARIABLES
##################################################################################

variable "aws_access_key" {
    default = "<your_aws_access_key>"
}

variable "aws_secret_key" {
    default = "<your_aws_secret_key>"
} 

variable "prom_scraping_ec2_access_key" {}

variable "prom_scraping_ec2_secret_key" {}

variable "aws_private_key_path" {
    default = "<your_aws_private_key_path>"
}

variable "aws_key_name" {
    default = "<your_aws_key_name>"
}

variable "aws_region" {
    default = "us-west-2"
}

variable "vault_pass" {}

variable "k8s_secret" {}

variable "bastion_key_name" {
  description = "bastion key name"
  default = "bastion_key"
}

resource "tls_private_key" "bastion_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "bastion_gen_key" {
  key_name   = "${var.bastion_key_name}"
  public_key = "${tls_private_key.bastion_key.public_key_openssh}"
}

##################################################################################
# PROVIDERS
##################################################################################

provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}
