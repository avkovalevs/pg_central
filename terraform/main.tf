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

resource "hcloud_network_subnet" "private-network" {
  network_id   = hcloud_network.network.id
  type         = "server"
  network_zone = "eu-central"
  ip_range     = "10.0.1.0/26"
  #vswitch_id   = 400
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
  firewall_ids = [hcloud_firewall.firewall_lab.id]
  network {
    network_id  = hcloud_network.network.id
  } 
  depends_on = [hcloud_network_subnet.private-network]
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

resource "hcloud_firewall" "firewall_lab" {
  name = "fw_lab"
  rule {
   direction = "in"
   protocol  = "tcp"
   port      = "22"
   source_ips = [
      "0.0.0.0/0",
      "::/0"
   ]
  }
  rule {
   direction = "in"
   protocol  = "tcp"
   port      = "5432"
   source_ips = [
      "65.21.0.0/16",
      "10.0.1.0/26"
   ]
  }

}

