terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
    ansible = {
      # version = "~> 1.3.0"
      source = "ansible/ansible"
    }
  }
}

provider "yandex" {
  token     = var.yandex_cloud_token #секретные данные должны быть в сохранности!! Никогда не выкладывайте токен в публичный доступ.
  folder_id = "b1gngfs82v779s82s5lh"
  zone      = "ru-central1-a"
  alias     = "web"
}

