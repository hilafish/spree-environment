Spree-environment
========================

What is this repo about?
------------------------

Terraform & Ansible configurations that provision Spree app in K8S pods (via CI/CD process in Jenkins)
on AWS (Using it as the cloud provider) with prometheus/kibana monitoring

Deploying this repo will provision a fully working environment (almost :) need to manually run jenkins job once,
and re-register jobs hooks and then it'll ALL be automatic) that demonstrates a full life cycle of an application
including its entire supporting infrastructure and monitoring.


How to use this repository 
--------------------------

1. `git clone https://github.com/hilafish/spree-environment.git`

2. `cd spree-environment`

3. `terraform init` (make sure you have terraform installed)

4. `terraform plan -var 'aws_access_key=access_key_here' -var 'aws_secret_key=secret_key_here' -var 'aws_private_key_path=path_to_private_key_here' -var 'aws_key_name=key_pair_name_here' -var 'vault_pass=vault_pass'`

(if you want to know what's going to be installed.. it's a good practice to run plan first)

5. `terraform apply -var 'aws_access_key=access_key_here' -var 'aws_secret_key=secret_key_here' -var 'aws_private_key_path=path_to_private_key_here' -var 'aws_key_name=key_pair_name_here' -var 'vault_pass=vault_pass' --auto-approve`

***NOTE***: region = "us-west-2". If you would like to use other region, change it in the ec2.tf file.

6. Wait and watch the magic happen or go do some other stuff :)

7. Upon decision to remove the terraform managed resources created just now, run:

`terraform destroy -var 'aws_access_key=access_key_here' -var 'aws_secret_key=secret_key_here' -var 'aws_private_key_path=path_to_private_key_here' -var 'aws_key_name=key_pair_name_here' -var 'vault_pass=vault_pass' --auto-approve`

Once Terraform finished running, you should expect this output:

```
Apply complete! Resources: 25 added, 0 changed, 0 destroyed.

Outputs:
kibana_grafana_public_dns = ec2-3-84-131-190.compute-1.amazonaws.com (for example)
```

Copy the URL you got.

Grafana:
1. browse to http://the_copied_url:3000
2. login with user admin, password admin
3. you'll be prompt to change the password, please do so.
4. If you'll get "unauthorized!" message after login, just refresh the page and it'll get sorted out.
5. click on "Home" and then choose any of the available dashboards (MySQL, System, k8s)
6. enjoy viewing the data :)

Kibana:
1. browse to http://the_copied_url:5601
2. wait a minute or so to allow data to be gathered.
3. go to "dashboard"
4. click on any of the dashboards
5. enjoy viewing the data :)
