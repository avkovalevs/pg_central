# Deploy two nodes PG cluster on Hetzner

This project will describes steps needed deploy at Hetzner Cloud a PG cluster using Terraform and Ansible code
## Software requirements
PostgreSQL 12, repmgr 5.2.1, Ansible 2.9.16, Terraform 1.0.2, Ubuntu 18.04 LTS 

## Pre-requisites
- Hetzner account
- Generated API Token
- Generated Public key 

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

3. Add public key to variable.tf. These variables must be changed: ssh_key_name and ssh_public_key 
4. Run the terraform commands below to initialize the configuration:
~~~
terraform init
terraform plan
~~~
5. Apply the configuration using command below:
~~~
terraform apply
~~~

### Software deployment using Ansible
These steps will cover installation and tuning PG software, setup common steps for nodes.
