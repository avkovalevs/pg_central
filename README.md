# How to run a two-nodes PG cluster on Hetzner?

This project will describe steps needed to deploy at Hetzner Cloud a PG cluster using Terraform and Ansible code
## Software requirements
PostgreSQL 12, repmgr 5.2.1, Ansible 2.9.16, Terraform 1.0.2, Ubuntu 18.04 LTS 

## Pre-requisites
- Hetzner account
- Generated API Token (with read and write permissions)
- Generated Public key 
- Terraform and ansible installed

## Usage
### Deployment of infrastructure (provisioning) using terraform.
These steps will create 2 VM, network and subnetwork, 2 external storage drives for PostgreSQL data.  
1. Clone this repository and change the directory to terraform:
~~~
git clone https://github.com/avkovalevs/pg_central.git
cd terraform
~~~

2. Set the following Terraform configuration variables appropriately to setup the Hetzner API Token:
~~~
export HCLOUD_TOKEN="insert api token here"
~~~

3. Add public key to variables.tf. These variables must be changed on your values: ssh_key_name and ssh_public_key 
4. Run the terraform commands below to initialize and check the configuration:
~~~
terraform init
terraform plan
~~~
5. Apply the configuration using command below:
~~~
terraform apply
~~~
6. If the deployment process is finished successfully the output will show the public addresses of PG nodes.
In another case, there a way to fix the errors and recreate infrastructure again using the following commands:
~~~
terraform destroy
terraform apply
~~~

### Software deployment using Ansible
These steps will cover installation and tuning steps for PG software, set up common steps for nodes, and so on.
Before the installation needs to install ansible software locally on the same node as the terraform. This node will an ansible master.
Nodes created on previous steps are called managed nodes. 
1. Install ansiible software on master node (once)
2. Check access from master to managed nodes (each time after provisioning)
3. Setup inventory and check variables (each time after provisioning)
4. Run playbook to deploy software stack (any times)
