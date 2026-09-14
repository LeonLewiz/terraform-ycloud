output "vm_external_ips" {
  description = "External IP"
  value = {
    for k, v in yandex_compute_instance.vm :
    k => v.network_interface[0].nat_ip_address
  }
}
