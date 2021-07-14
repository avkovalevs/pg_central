# How to run a two-nodes PG cluster on Hetzner?

This project will describe steps needed to deploy at Hetzner Cloud a PG cluster using Terraform and Ansible code
## Software requirements
PostgreSQL 12, repmgr 5.2.1, Ansible 2.9.6, Terraform 1.0.2, Ubuntu 20.04 LTS 

## Pre-requisites
- Hetzner account
- Generated API Token (with read and write permissions)
- Generated Public key 
- Terraform and ansible installed

## Usage
### Deployment of infrastructure (provisioning) using terraform.
These steps will create 2 VM, network and subnetwork, 2 external storage drives for PostgreSQL data.  
All commands for terraform and ansible configuration must be run from the root user.
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
1. Install ansible software on master node (once). Use this commands below for Ubuntu machine only.
~~~
sudo apt-add-repository ppa:ansible/ansible
sudo apt install software-properties-common -y
sudo apt update
sudo apt install ansible -y
For Ubuntu 18, needs to install 2 packages for PostgreSQL and network.
sudo apt install python-psycopg2 -y
sudo apt install python-netaddr -y
For Ubuntu 20, need to install another packages for PostgreSQL and network:
sudo apt-get install build-essential -y
sudo apt-get install python3-pip -y
sudo apt-get install python3-dev libpq-dev -y
sudo pip3 install psycopg2 
sudo apt install python-netaddr -y
~~~
2. Check access from ansible master node to managed nodes (each time after provisioning)
~~~
ssh root@use_public_ip_from_terraform_output_here
~~~
3. Add public key to root user on master node using command below (once):
~~~
ssh-copy-id -i ~/.ssh/id_rsa.pub root@127.0.0.1
~~~
4. Setup inventory and check variables (each time after provisioning). For the inventory setup it is required to edit hosts file in the dev, test or prod catalogs depend on enviroment you will use.
5. Run the playbook to deploy software stack (any times)
~~~
ansible-playbook -v -i test master.yml --extra-vars "env_state=present" -t common
~~~
"-v" - verbose mode enabled,
"-i test" - show the inventory file using for playing,
"master.yml" - the main file with tasks and roles, 
"--extra-vars" - additional parameter like "env_state=present",  
"-t common" - use tag "common". 
Ansible master will play only tasks which has tags common. 
This is usefull parameter if no need to play all the roles, all the tasks each times. 
