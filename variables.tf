variable "cloud_id" {
  description = "ID of yaCloud"
  type        = string
  sensitive   = false
}

variable "folder_id" {
  description = "ID of the Learning folder"
  type        = string
  sensitive   = false
}

variable "kms_key_id" {
  description = "KMS ID"
  type        = string
  sensitive   = false
}

variable "zone" {
  description = "Zone"
  type        = string
  sensitive   = false
}

variable "my_ip" {
  description = "My public IP"
  type        = list(string)
}

variable "node_group_enabled" {
  type    = bool
  default = true
}

locals {
  vms = {
    managed1 = { cores = 2, memory = 2, zone = "ru-central1-a" }
    managed2 = { cores = 2, memory = 2, zone = "ru-central1-a" }
  }
}
