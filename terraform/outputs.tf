output "public_ip4_master" {
  value = "${hcloud_server.pg[0].ipv4_address}"
}

 
output "public_ip4_replica1" {
  value = "${hcloud_server.pg[1].ipv4_address}"
}

