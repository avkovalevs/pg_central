# How to run a two-nodes PG cluster on Hetzner?

This project will describe steps needed to deploy at Hetzner Cloud a PG cluster using Terraform and Ansible code
## Software requirements
PostgreSQL 12, repmgr 5.2.1, Ansible 2.9.6, Terraform 1.0.2, Ubuntu 20.04 LTS 

## Pre-requisites
- Hetzner account
- Generated API Token (with read and write permissions)
- Generated Public key 
- Terraform and ansible installed
- .ansible_vault_pass

## Usage
### Deployment of infrastructure (provisioning) using terraform.
These steps will create 2 VM, network and subnetwork, 2 external storage drives for PostgreSQL data.  
All commands for terraform and ansible configuration must be run by the root user.
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

### PostgreSQL/Repmgr software deployment using Ansible (VM cluster)
These steps will cover installation and tuning steps for PG software, set up common steps for nodes, and so on.
Before the installation needs to install ansible software locally on the same node as the terraform codebase. This node will an ansible master.
Nodes created on previous steps are called managed nodes. 
1. Install ansible software on master node (once). Use these commands below for Ubuntu machine only.
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
5. Run the playbook to deploy software stack (any times).  Start the playbook inside the "ansible" directory.
~~~
cd ../ansible
ansible-playbook -v -i test master.yml --extra-vars "env_state=present" -t common --vault-password-file=.ansible_vault_pass
~~~
Ansible master will play only tasks which have the tag "common".  
List of available tags: 
-t common
-t pg
Parameter description:
- -v: Verbose mode enabled
- -i test: Show the inventory file using for playing
- master.yml: The main file with tasks and roles
- --extra-vars: Additional parameter like "env_state=present"
- -t common: Use tag "common"
- --vault-password-file: This file store the password used for encryption sensitive information like passwords, secrets and so on. This file usually added to .gitignore
To encrypt file with credentials use the command below:
~~~
ansible-vault encrypt ./group_vars/credentials --vault-password-file .ansible_vault_pass
~~~

To check/edit credentials use the following command:
~~~
ansible-vault edit ./group_vars/credentials --vault-password-file .ansible_vault_pass
~~~
To run all the roles don't use tags at all.

### Bitnami based software deployment using Ansible (docker cluster on separate VM)

The steps for the Docker cluster deployment are similar to the steps of PostgreSQL HA deployment on VM.
Don't apply steps 1-3 if they are already done. 

4. Setup inventory and check variables (each time after provisioning).
5. Run the playbook to deploy software stack (any times). 
Start the playbook inside the "pgdocker" directory.
~~~
cd ../pgdocker
ansible-playbook -v -i test master.yml --extra-vars "env_state=present" --vault-password-file=.ansible_vault_pass
~~~

List of available tags:  
- -t common, 
- -t bpg

Useful commands for Docker cluster:

- Check repmgr cluster status (bitnami).
~~~
docker exec -it root_pgnode-0_1 /opt/bitnami/scripts/postgresql-repmgr/entrypoint.sh repmgr -f /opt/bitnami/repmgr/conf/repmgr.conf cluster show
~~~

- PSQL connection to the PostgreSQL:
~~~
docker exec -it root_pgnode-0_1 psql -h pgnode-0 -U postgres 
~~~
- Scaling to 3 nodes cluster:
Add count "3" at main.tf and rows at output.tf. 
Add to inventory file ./test/hosts values from the output "terraform apply" ip addresses. 
Run the playbook (step 5).
Check the repmgr cluster status (useful commands) from the PG node.
