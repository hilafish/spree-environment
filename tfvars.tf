##################################################################################
# VARIABLES
##################################################################################

variable "aws_access_key" {
    default = "<your_aws_access_key>"
}

variable "aws_secret_key" {
    default = "<your_aws_secret_key>"
} 


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

##################################################################################
# PROVIDERS
##################################################################################

provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}
