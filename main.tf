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
    tls = {
      source = "hashicorp/tls"
}
  }
  backend "s3" {
    endpoint        = "https://storage.yandexcloud.net"
    region          = "ru-central1"
    bucket          = "ci-state-bucket"
    key             = "terraform.tfstate"

    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
  }
}
provider "yandex" {
  service_account_key_file     = "key.json"

  cloud_id                     = var.cloud_id

  folder_id                    = var.folder_id

  zone                         = "ru-central1-a"
}

data "yandex_vpc_subnet" "default_a" {
  name = "default-ru-central1-a"
}

