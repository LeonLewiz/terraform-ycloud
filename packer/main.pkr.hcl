packer {
  required_plugins {
    yandex = {
      version = ">= 1.1.2"
      source = "github.com/hashicorp/yandex"
    }
    ansible = {
      version = "~> 1"
      source  = "github.com/hashicorp/ansible"
    }
  }
}

source "yandex" "yandex_source" {
  folder_id                 = "b1gvffio67prtqkt6klm"
  zone                      = "ru-central1-a"
  subnet_id                 = "e9be230s67bu17qirg62"
  source_image_family       = "ubuntu-2204-lts"
  ssh_username              = "ubuntu"
  use_ipv4_nat              = true
  service_account_key_file  = "key.json"
  image_family              = "leonlewiz-study-family"
  ssh_clear_authorized_keys = true
}

build {
  name    = "devops-study"
  sources = ["source.yandex.yandex_source"]

  provisioner "ansible" {
    playbook_file   = "/home/leonlewiz/ansible-lab/image.yml"
    user            = "ubuntu"
    groups          = ["managed"]
    use_proxy       = false
    extra_arguments = ["--vault-password-file=/home/leonlewiz/new_vault_pass"]
  }
  provisioner "shell" {
    inline = [
      "sudo cloud-init clean --logs --seed --machine-id",
    ]
  }
}
