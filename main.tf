terraform {
  required_providers {
    yandex = {
      version = ">= 0.130.0"
      source = "yandex-cloud/yandex"
    }
    local = {
      source = "hashicorp/local"
    }
  }
}

provider "yandex" {
  service_account_key_file     = "key.json"

  cloud_id                     = var.cloud_id

  folder_id                    = var.folder_id

  zone                         = "ru-cetral1-a"
}

data "yandex_vpc_subnet" "default_a" {
  name = "default-ru-central1-a"
}

data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2204-lts"
}

resource "yandex_compute_instance" "vm" {
  for_each = local.vms

  name        = "devops-study-${each.key}"
  platform_id = "standard-v3"
  zone        = each.value.zone

  resources {
    cores         = each.value.cores
    memory        = each.value.memory
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 15
      type     = "network-ssd"
    }
  }

  network_interface {
    subnet_id = data.yandex_vpc_subnet.default_a.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file(pathexpand("~/.ssh/id_ed25519.pub"))}"
  }
}

resource"local_file" "inventory" {
  filename = "../ansible-lab/hosts.ini"
  content = templatefile("inventory.tpl", {
    m2_ip      = yandex_compute_instance.vm["managed2"].network_interface[0].nat_ip_address
    m1_ip      = yandex_compute_instance.vm["managed1"].network_interface[0].nat_ip_address
  })
}
