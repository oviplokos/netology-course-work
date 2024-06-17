output "internal_ip_address_nginx" {
  value = yandex_compute_instance_group.nginx.instances[*].network_interface.0.ip_address
}
output "nginx1_boot_id" {
  value = data.yandex_compute_instance.nginx1.boot_disk[0].disk_id
}
output "nginx2_boot_id" {
  value = data.yandex_compute_instance.nginx2.boot_disk[0].disk_id
}
output "internal_ip_address_lb" {
  value = yandex_alb_load_balancer.lb.listener.0.endpoint.0.address.0.external_ipv4_address.0.address
}

output "internal_ip_address_prometheus" {
  value = yandex_compute_instance.prometheus.network_interface.0.ip_address
}
output "external_ip_address_prometheus" {
  value = yandex_compute_instance.prometheus.network_interface.0.nat_ip_address
}
output "internal_ip_address_grafana" {
  value = yandex_compute_instance.grafana.network_interface.0.ip_address
}
output "external_ip_address_grafana" {
  value = yandex_compute_instance.grafana.network_interface.0.nat_ip_address
}
output "internal_ip_address_elc" {
  value = yandex_compute_instance.elc.network_interface.0.ip_address
}
output "external_ip_address_elc" {
  value = yandex_compute_instance.elc.network_interface.0.nat_ip_address
}
output "internal_ip_address_kibana" {
  value = yandex_compute_instance.kibana.network_interface.0.ip_address
}
output "external_ip_address_kibana" {
  value = yandex_compute_instance.kibana.network_interface.0.nat_ip_address
}
output "external_ip_address_bastion" {
  value = yandex_compute_instance.bastion-host.network_interface.0.nat_ip_address
}
