terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.0"
    }
  }
}

provider "hcloud" {
  token = "${var.hcloud_token}"
}

resource "hcloud_ssh_key" "avkovalevs" {
  name       = "${var.ssh_key_name}"
  public_key = "${file(var.ssh_public_key)}"
}

resource "hcloud_network" "network" {
  name     = "network"
  ip_range = "10.0.1.0/24"
}

resource "hcloud_network_subnet" "public-network" {
  network_id   = hcloud_network.network.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = "10.0.1.0/26"
}

resource "hcloud_server" "pg" {
  count       = "2"
  name        = "pgnode-${count.index}"
  server_type = "cx11"
  image       = "ubuntu-18.04"
  location    = "hel1"
  ssh_keys    = ["${hcloud_ssh_key.avkovalevs.id}"]
  network {
    network_id  = hcloud_network.network.id
  } 
}

