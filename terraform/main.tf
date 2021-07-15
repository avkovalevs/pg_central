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
  depends_on = [hcloud_network.network]
}

resource "hcloud_server" "pg" {
  count       = "2"
  name        = "pgnode-${count.index}"
  server_type = "cx11"
  image       = "ubuntu-18.04"
  location    = "hel1"
  keep_disk   = true
  ssh_keys    = ["${hcloud_ssh_key.avkovalevs.id}"]
  network {
    network_id  = hcloud_network.network.id
  } 
  depends_on = [hcloud_network_subnet.public-network]
}

resource "hcloud_volume" "pgdatavol0" {
  count     = "2"
  name      = "pgdata-${count.index}"
  size      = 10
  location    = "hel1"
}

resource "hcloud_volume_attachment" "main" {
  count     = "2"
  volume_id = "${hcloud_volume.pgdatavol0[count.index].id}"
  server_id = "${hcloud_server.pg[count.index].id}"
  automount = true
}

