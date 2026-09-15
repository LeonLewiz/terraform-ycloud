terraform {
  required_providers {
    yandex = {
      version = ">= 0.130.0"
      source = "yandex-cloud/yandex"
    }
    local = {
      source = "hashicorp/local"
    }
    time = {
      source = "hashicorp/time"
  }
  }
}
backend "s3" {
    endpoint = "https://storage.yandexcloud.net"
    region   = "ru-central1"
    bucket   = "ci-state-bucket"
    key      = "terraform.tfstate"

    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
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

resource "tls_private_key" "ssh_key" {
  algorithm = "ED25519"
}

resource "time_sleep" "wait_vms" {
  create_duration = "90s"
  depends_on      = [yandex_compute_instance.vm]
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
    security_group_ids = [var.sg_id]
  }

  metadata = {
    ssh-keys = "ubuntu:${tls_private_key.ssh_key.public_key_openssh}"
  }
}

variable "inventory_path" {
  type    = string
  default = "../ansible-lab/hosts.ini"
}

resource "local_file" "private_key" {
  content  = tls_private_key.ssh_key.private_key_openssh
  filename = "${path.module}/id_ed25519"
  file_permission = "0600"
}

resource "local_file" "inventory" {
  depends_on = [time_sleep.wait_vms]
  filename = var.inventory_path
  content = templatefile("inventory.tpl", {
    vms          = yandex_compute_instance.vm
    ssh_key_path = abspath("${path.module}/id_ed25519")
  })
}
