#-------------------------DISKS-------------------------
resource "yandex_compute_disk" "prometheus" {
  name     = "disk-prometheus"
  type     = "network-hdd"
  zone     = "ru-central1-a"
  image_id = "fd88m3uah9t47loeseir"
  size     = 50

  labels = {
    environment = "prometheus"
  }
}
resource "yandex_compute_disk" "grafana" {
  name     = "disk-grafana"
  type     = "network-hdd"
  zone     = "ru-central1-b"
  image_id = "fd88m3uah9t47loeseir"
  size     = 50

  labels = {
    environment = "grafana"
  }
}
resource "yandex_compute_disk" "elc" {
  name     = "disk-elc"
  type     = "network-hdd"
  zone     = "ru-central1-a"
  image_id = "fd88m3uah9t47loeseir"
  size     = 70

  labels = {
    environment = "elc"
  }
}
resource "yandex_compute_disk" "kibana" {
  name     = "disk-kibana"
  type     = "network-hdd"
  zone     = "ru-central1-a"
  image_id = "fd88m3uah9t47loeseir"
  size     = 50

  labels = {
    environment = "kibana"
  }
}
resource "yandex_compute_disk" "bastion-host" {
  name     = "disk-bastion-host"
  type     = "network-hdd"
  zone     = "ru-central1-b"
  image_id = "fd806u1okplml22f4pmo"
  size     = 50

  labels = {
    environment = "bastion-host"
  }
}

#--------------------SNAPSHOTS--------------------
resource "yandex_compute_snapshot" "snapshot_prometheus" {
  name           = "snapshot-prometheus"
  source_disk_id = yandex_compute_disk.prometheus.id
  depends_on     = [yandex_compute_instance.prometheus]
}
resource "yandex_compute_snapshot" "snapshot_grafana" {
  name           = "snapshot-grafana"
  source_disk_id = yandex_compute_disk.grafana.id
  depends_on     = [yandex_compute_instance.grafana]
}
resource "yandex_compute_snapshot" "snapshot_elc" {
  name           = "snapshot-elc"
  source_disk_id = yandex_compute_disk.elc.id
  depends_on     = [yandex_compute_instance.elc]
}
resource "yandex_compute_snapshot" "snapshot_kibana" {
  name           = "snapshot-kibana"
  source_disk_id = yandex_compute_disk.kibana.id
  depends_on     = [yandex_compute_instance.kibana]
}
resource "yandex_compute_snapshot" "snapshot_bastion_host" {
  name           = "snapshot-bastion-host"
  source_disk_id = yandex_compute_disk.bastion-host.id
  depends_on     = [yandex_compute_instance.bastion-host]
}
data "yandex_compute_instance" "nginx1" {
  instance_id = yandex_compute_instance_group.nginx.instances[0].instance_id
}
resource "yandex_compute_snapshot" "snapshot_nginx1" {
  name           = "snapshot-nginx1"
  source_disk_id = data.yandex_compute_instance.nginx1.boot_disk[0].disk_id
  depends_on     = [yandex_compute_instance_group.nginx]
}
data "yandex_compute_instance" "nginx2" {
  instance_id = yandex_compute_instance_group.nginx.instances[1].instance_id
}
resource "yandex_compute_snapshot" "snapshot_nginx2" {
  name           = "snapshot-nginx2"
  source_disk_id = data.yandex_compute_instance.nginx2.boot_disk[0].disk_id
  depends_on     = [yandex_compute_instance_group.nginx]
}
resource "yandex_compute_snapshot_schedule" "snapshot_week" {
  name = "snapshot-schedule"
  depends_on = [yandex_compute_snapshot.snapshot_bastion_host,
    yandex_compute_snapshot.snapshot_elc,
    yandex_compute_snapshot.snapshot_grafana,
    yandex_compute_snapshot.snapshot_kibana,
    yandex_compute_snapshot.snapshot_prometheus,
    yandex_compute_snapshot.snapshot_nginx1,
  yandex_compute_snapshot.snapshot_nginx2]
  schedule_policy {
    expression = "00 02 ? * *"
  }

  snapshot_count = 7

  snapshot_spec {
    description = "snapshot"
  }

  disk_ids = [yandex_compute_disk.prometheus.id,
    yandex_compute_disk.grafana.id,
    yandex_compute_disk.kibana.id,
    yandex_compute_disk.elc.id,
    yandex_compute_disk.bastion-host.id,
    data.yandex_compute_instance.nginx2.boot_disk[0].disk_id,
    data.yandex_compute_instance.nginx1.boot_disk[0].disk_id
  ]
}

#-------------------VM----------------------------
// Создание группы ВМ
resource "yandex_compute_instance_group" "nginx" {
  name               = "fixed-ig-with-balancer"
  folder_id          = var.yandex_folder_id
  service_account_id = var.yandex_account_id
  instance_template {
    name        = "nginx-{instance.index}"
    platform_id = "standard-v3"
    resources {
      core_fraction = 20
      memory        = 2
      cores         = 2
    }

    boot_disk {
      mode = "READ_WRITE"
      name = "nginx-{instance.index}"
      initialize_params {
        image_id = "fd8di2mid9ojikcm93en"

      }
    }
    network_interface {
      network_id         = yandex_vpc_network.internal-bastion-network.id
      subnet_ids         = [yandex_vpc_subnet.internal-bastion-segment-a.id, yandex_vpc_subnet.internal-bastion-segment-b.id]
      security_group_ids = [yandex_vpc_security_group.internal-bastion-sg.id, yandex_vpc_security_group.subnet-sg.id]
      nat                = false
    }

    //Передача ssh-ключа в ВМ
    metadata = {
      user-data = "${file("./meta.txt")}"
    }
  }

  // Настройка политики размещения ВМ в разных зонах
  allocation_policy {
    zones = ["ru-central1-a", "ru-central1-b"]
  }

  // Настройка масштабирования и развертывания
  scale_policy {
    fixed_scale {
      size = 2
    }
  }

  //Политика деплоя
  deploy_policy {
    max_unavailable = 1
    max_creating    = 2
    max_expansion   = 2
    max_deleting    = 2
  }

  application_load_balancer {
    target_group_name        = "target-group"
    target_group_description = "Целевая группа Network Load Balancer"
  }
}
resource "yandex_compute_instance" "prometheus" {
  name = "prometheus"
  zone = "ru-central1-a"
  resources {
    core_fraction = 20
    cores         = 2
    memory        = 2
  }

  boot_disk {

    disk_id = yandex_compute_disk.prometheus.id

  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.internal-bastion-segment-a.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.internal-bastion-sg.id, yandex_vpc_security_group.subnet-sg.id]
  }

  metadata = {
    user-data = "${file("./meta.txt")}"
  }
}
resource "yandex_compute_instance" "elc" {
  name = "elc"
  zone = "ru-central1-a"
  resources {
    core_fraction = 20
    cores         = 4
    memory        = 4
  }

  boot_disk {

    disk_id = yandex_compute_disk.elc.id

  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.internal-bastion-segment-a.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.internal-bastion-sg.id, yandex_vpc_security_group.subnet-sg.id]
  }

  metadata = {
    user-data = "${file("./meta.txt")}"
  }
}
resource "yandex_compute_instance" "grafana" {
  name = "grafana"
  zone = "ru-central1-b"
  resources {
    core_fraction = 20
    cores         = 2
    memory        = 2
  }

  boot_disk {

    disk_id = yandex_compute_disk.grafana.id

  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.internal-bastion-segment-b.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.internal-bastion-sg.id, yandex_vpc_security_group.subnet-sg.id, yandex_vpc_security_group.grafana-sg.id]
  }

  metadata = {
    user-data = "${file("./meta.txt")}"
  }
}
resource "yandex_compute_instance" "kibana" {
  name = "kibana"
  zone = "ru-central1-a"
  resources {
    core_fraction = 20
    cores         = 2
    memory        = 2
  }

  boot_disk {

    disk_id = yandex_compute_disk.kibana.id

  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.internal-bastion-segment-a.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.kibana-sg.id, yandex_vpc_security_group.subnet-sg.id, yandex_vpc_security_group.internal-bastion-sg.id]
  }

  metadata = {
    user-data = "${file("./meta.txt")}"
  }
}
resource "yandex_compute_instance" "bastion-host" {
  name                      = "bastion-host"
  zone                      = "ru-central1-b"
  allow_stopping_for_update = true
  resources {
    core_fraction = 20
    cores         = 2
    memory        = 2
  }

  boot_disk {

    disk_id = yandex_compute_disk.bastion-host.id

  }

  network_interface {
    subnet_id = yandex_vpc_subnet.bastion-external-segment.id
    nat       = true
  }
  network_interface {
    subnet_id          = yandex_vpc_subnet.internal-bastion-segment-b.id
    nat                = false
    ip_address         = "172.16.15.254"
    security_group_ids = [yandex_vpc_security_group.internal-bastion-sg.id]
  }

  metadata = {
    user-data = "${file("./meta bastion.txt")}"
  }
}


#------------------------NETWORKS----------------------------
resource "yandex_vpc_gateway" "nat_gateway" {
  folder_id = var.yandex_folder_id
  name      = "gateway"
  shared_egress_gateway {}
}
resource "yandex_vpc_route_table" "outdoor-a" {
  folder_id  = var.yandex_folder_id
  name       = "outdoor table segment a"
  network_id = yandex_vpc_network.internal-bastion-network.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway.id
  }

}
resource "yandex_vpc_route_table" "outdoor-b" {
  folder_id  = var.yandex_folder_id
  name       = "outdoor table segment b"
  network_id = yandex_vpc_network.internal-bastion-network.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway.id
  }
}

resource "yandex_vpc_network" "external-bastion-network" {
  name = "external-bastion-network"

}
resource "yandex_vpc_subnet" "bastion-external-segment" {
  name           = "bastion-external-segment"
  v4_cidr_blocks = ["172.16.17.0/28"]
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.external-bastion-network.id
}

resource "yandex_vpc_network" "internal-bastion-network" {
  name = "internal-bastion-network"

}
resource "yandex_vpc_subnet" "internal-bastion-segment-a" {
  name           = "internal-bastion-segment-a"
  v4_cidr_blocks = ["172.16.16.0/24"]
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.internal-bastion-network.id
  route_table_id = yandex_vpc_route_table.outdoor-a.id

}
resource "yandex_vpc_subnet" "internal-bastion-segment-b" {
  name           = "internal-bastion-segment-b"
  v4_cidr_blocks = ["172.16.15.0/24"]
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.internal-bastion-network.id
  route_table_id = yandex_vpc_route_table.outdoor-b.id

}
#---------------GROUPS-------------------

resource "yandex_alb_backend_group" "nginx-backend-group" {
  name = "nginx"
  session_affinity {
    connection {
      source_ip = true
    }
  }

  http_backend {
    name             = "nginx"
    weight           = 1
    port             = 80
    target_group_ids = ["${yandex_compute_instance_group.nginx.application_load_balancer.0.target_group_id}"]
    load_balancing_config {
      panic_threshold = 90
    }
    healthcheck {
      timeout             = "10s"
      interval            = "2s"
      healthy_threshold   = 10
      unhealthy_threshold = 15
      http_healthcheck {
        path = "/"
      }
    }
  }
}
resource "yandex_alb_http_router" "tf-router" {
  name = "nginx-router"
  labels = {
    tf-label    = "tf-label-value"
    empty-label = ""
  }
}
resource "yandex_alb_virtual_host" "http-router" {
  name           = "nginx"
  http_router_id = yandex_alb_http_router.tf-router.id
  route {
    name = "nginx-route"
    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.nginx-backend-group.id
        timeout          = "60s"
      }
    }
  }
  # route_options {
  #   security_profile_id = "<идентификатор_профиля_безопасности>"
  # }
}
resource "yandex_alb_load_balancer" "lb" {
  name = "load-balancer"

  network_id         = yandex_vpc_network.internal-bastion-network.id
  security_group_ids = [yandex_vpc_security_group.subnet-sg.id, yandex_vpc_security_group.load-balansing-sg.id]


  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.internal-bastion-segment-a.id
    }
  }

  listener {
    name = "my-listener"
    endpoint {
      address {
        external_ipv4_address {

        }
      }
      ports = [80]
    }
    http {
      handler {
        http_router_id = yandex_alb_http_router.tf-router.id
      }
    }
  }

  log_options {
    discard_rule {
      http_code_intervals = ["HTTP_2XX"]
      discard_percent     = 75
    }
  }
}
resource "yandex_vpc_security_group" "secure-bastion-sg" {
  name        = "secure bastion sg"
  description = "Description for security group"
  network_id  = yandex_vpc_network.external-bastion-network.id
  ingress {
    protocol       = "TCP"
    description    = "ingress ssh to bastion host"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }
}
resource "yandex_vpc_security_group" "internal-bastion-sg" {
  name        = "internal bastion sg"
  description = "Description for security group"
  network_id  = yandex_vpc_network.internal-bastion-network.id
  ingress {
    protocol       = "TCP"
    description    = "ingress ssh to bastion host"
    v4_cidr_blocks = ["172.16.15.254/32", "172.16.16.0/24"]
    port           = 22
  }
  egress {
    protocol       = "ANY"
    description    = "egress ssh to private hosts"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = -1
  }
}
resource "yandex_vpc_security_group" "load-balansing-sg" {
  name        = "load balansing sg"
  description = "Description for security group"
  network_id  = yandex_vpc_network.internal-bastion-network.id
  ingress {
    description    = "Allow HTTP protocol from local subnets"
    protocol       = "TCP"
    port           = "80"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "ingress check balansing hosts"
    v4_cidr_blocks = ["172.16.15.0/24", "172.16.16.0/24"]
    port           = "80"
  }

  ingress {
    description       = "Health checks from NLB"
    protocol          = "TCP"
    predefined_target = "loadbalancer_healthchecks"

  }

  egress {
    description    = "Permit ANY"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }



}
resource "yandex_vpc_security_group" "subnet-sg" {
  name        = "subnet sg"
  description = "Description for security group"
  network_id  = yandex_vpc_network.internal-bastion-network.id
  ingress {
    protocol          = "ANY"
    description       = "ingress private network to  hosts"
    predefined_target = "self_security_group"
  }
  egress {
    protocol          = "ANY"
    description       = "egress private network to hosts"
    predefined_target = "self_security_group"

  }
}
resource "yandex_vpc_security_group" "kibana-sg" {
  name        = "kibana sg"
  description = "Description for security group"
  network_id  = yandex_vpc_network.internal-bastion-network.id
  ingress {
    protocol       = "TCP"
    description    = "ingress check balansing hosts"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 5601
  }

  egress {
    protocol       = "ANY"
    description    = "egress ssh to private hosts"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = -1
  }
}
resource "yandex_vpc_security_group" "grafana-sg" {
  name        = "grafana sg"
  description = "Description for security group"
  network_id  = yandex_vpc_network.internal-bastion-network.id
  ingress {
    protocol       = "TCP"
    description    = "ingress check balansing hosts"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 3000
  }
  egress {
    protocol       = "ANY"
    description    = "egress ssh to private hosts"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = -1
  }
}


resource "local_file" "inventory" {
  content = templatefile("inventory.ini.j2",
    {
      # bastion_ip    = yandex_compute_instance.bastion-host.network_interface.0.nat_ip_address,
      nginx_ip      = yandex_compute_instance_group.nginx.instances[*].network_interface.0.ip_address,
      elc_ip        = yandex_compute_instance.elc.network_interface.0.ip_address,
      grafana_ip    = yandex_compute_instance.grafana.network_interface.0.ip_address,
      kibana_ip     = yandex_compute_instance.kibana.network_interface.0.ip_address,
      prometheus_ip = yandex_compute_instance.prometheus.network_interface.0.ip_address,

    }
  )
  filename = "./inventory.ini"
}
#-----------------------DNS ZONE-----------------------------
resource "yandex_dns_zone" "public-zone" {
  name        = "my-public-zone"
  description = "public-zone-onets"

  labels = {
    label1 = "public_zone_donets"
  }

  zone             = "public.donets."
  public           = true
  private_networks = [yandex_vpc_network.internal-bastion-network.id]

  deletion_protection = false
}
resource "yandex_dns_zone" "private-zone" {
  name        = "my-private-zone"
  description = "private-zone-donets"

  labels = {
    label1 = "private_zone_donets"
  }

  zone             = "private.donets."
  public           = false
  private_networks = [yandex_vpc_network.internal-bastion-network.id]

  deletion_protection = false
}

#-----------------------DNS PUBLIC RECORDSET-----------------------------
resource "yandex_dns_recordset" "lb-nginx" {
  zone_id = yandex_dns_zone.public-zone.id
  name    = "nginx.public.donets."
  type    = "A"
  ttl     = 200
  data    = ["${yandex_alb_load_balancer.lb.listener.0.endpoint.0.address.0.external_ipv4_address.0.address}"]

}
resource "yandex_dns_recordset" "grafana" {
  zone_id = yandex_dns_zone.public-zone.id
  name    = "grafana.public.donets."
  type    = "A"
  ttl     = 200
  data    = ["${yandex_compute_instance.grafana.network_interface.0.nat_ip_address}"]

}
resource "yandex_dns_recordset" "kibana" {
  zone_id = yandex_dns_zone.public-zone.id
  name    = "kibana.public.donets."
  type    = "A"
  ttl     = 200
  data    = ["${yandex_compute_instance.kibana.network_interface.0.nat_ip_address}"]

}
resource "yandex_dns_recordset" "bastion" {
  zone_id = yandex_dns_zone.public-zone.id
  name    = "bastion.public.donets."
  type    = "A"
  ttl     = 200
  data    = ["${yandex_compute_instance.bastion-host.network_interface.0.nat_ip_address}"]

}
#----------------------------DNS PRIVATE RECORDSET---------------------------
resource "yandex_dns_recordset" "nginx1-private" {
  zone_id = yandex_dns_zone.private-zone.id
  name    = "nginx1.private.donets."
  type    = "A"
  ttl     = 200
  data    = ["${yandex_compute_instance_group.nginx.instances[0].network_interface.0.ip_address}"]
}
resource "yandex_dns_recordset" "nginx2-private" {
  zone_id = yandex_dns_zone.private-zone.id
  name    = "nginx2.private.donets."
  type    = "A"
  ttl     = 200
  data    = ["${yandex_compute_instance_group.nginx.instances[1].network_interface.0.ip_address}"]
}
resource "yandex_dns_recordset" "grafana-private" {
  zone_id = yandex_dns_zone.private-zone.id
  name    = "grafana.private.donets."
  type    = "A"
  ttl     = 200
  data    = ["${yandex_compute_instance.grafana.network_interface.0.ip_address}"]
}
resource "yandex_dns_recordset" "prometheus-private" {
  zone_id = yandex_dns_zone.private-zone.id
  name    = "prometheus.private.donets."
  type    = "A"
  ttl     = 200
  data    = ["${yandex_compute_instance.prometheus.network_interface.0.ip_address}"]
}
resource "yandex_dns_recordset" "elc-private" {
  zone_id = yandex_dns_zone.private-zone.id
  name    = "elc.private.donets."
  type    = "A"
  ttl     = 200
  data    = ["${yandex_compute_instance.elc.network_interface.0.ip_address}"]
}
resource "yandex_dns_recordset" "kibana-private" {
  zone_id = yandex_dns_zone.private-zone.id
  name    = "kibana.private.donets."
  type    = "A"
  ttl     = 200
  data    = ["${yandex_compute_instance.kibana.network_interface.0.ip_address}"]
}
