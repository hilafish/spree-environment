# Spree-environment
Terraform & Ansible configurations that provision Spree app in K8S pod (via CI/CD process in Jenkins) with prometheus/kibana monitoring

How to use this repository and install a fully working environment with dummy exporter, grafana, kibana, etc?

1. git clone https://github.com/hilafish/spree-environment.git

2. cd spree-environment

3. terraform init (make sure you have terraform installed)

4. terraform plan -var 'aws_access_key=access_key_here' -var 'aws_secret_key=secret_key_here' -var 'aws_private_key_path=path_to_private_key_here' -var 'aws_key_name=key_pair_name_here'

(if you want to know what's going to be installed.. it's a good practice to run plan first)

*** region = "us-west-2". If you would like to use other region, change it in the ec2.tf file.

5. terraform apply -var 'aws_access_key=access_key_here' -var 'aws_secret_key=secret_key_here' -var 'aws_private_key_path=path_to_private_key_here' -var 'aws_key_name=key_pair_name_here' --auto-approve

*** Reminder: region = "us-west-2". If you would like to use other region, change it in the ec2.tf file.

6. Wait and watch the magic happen or go do some other stuff :)

7. Upon decision to remove the terraform managed resources created just now, run:

terraform destroy -var 'aws_access_key=access_key_here' -var 'aws_secret_key=secret_key_here' -var 'aws_private_key_path=path_to_private_key_here' -var 'aws_key_name=key_pair_name_here' --auto-approve

Once Terraform finished running, you should expect this output:

Apply complete! Resources: 25 added, 0 changed, 0 destroyed.

Outputs:
kibana_grafana_public_dns = ec2-3-84-131-190.compute-1.amazonaws.com (for example)

Copy the URL you got.

Grafana:
1. browse to http://the_copied_url:3000
2. login with user admin, password admin
3. you'll be prompt to change the password, please do so.
4. If you'll get "unauthorized!" message after login, just refresh the page and it'll get sorted out.
5. click on "Home" and then choose the "dummy_exporter_dashboard"
6. enjoy viewing the data :)

Kibana:
1. browse to http://the_copied_url:5601
2. wait a minute or so to allow data to be gathered.
3. go to "dashboard"
4. click on any of the dashboards
5. enjoy viewing the data :)
