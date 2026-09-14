variable "cloud_id" {
  description = "ID of yaCloud"
  type        = string
  sensitive   = false
}

variable "folder_id" {
  description = "ID of the Learning folder"
  type = string
  sensitive = false
}


locals {
  vms = {
    managed1 = { cores = 2, memory = 2, zone = "ru-central1-a" }
    managed2 = { cores = 2, memory = 2, zone = "ru-central1-a" }
  }
}
