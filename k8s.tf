data "yandex_vpc_network" "default" {
  name = "default"
}

resource "yandex_vpc_security_group" "k8s" {
  name       = "k8s-sg"
  network_id = data.yandex_vpc_network.default.id

  ingress {
    description    = "kubectl-api"
    protocol       = "TCP"
    port           = 443
    v4_cidr_blocks = var.my_ip
  }

  ingress {
    description    = "kubectl-direct"
    protocol       = "TCP"
    port           = 6443
    v4_cidr_blocks = var.my_ip
  }

  ingress {
    description       = "selfin"
    protocol          = "ANY"
    predefined_target = "self_security_group"
    from_port         = 0
    to_port           = 65535
  }

  egress {
    description    = "internet"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description       = "selfout"
    protocol          = "ANY"
    predefined_target = "self_security_group"
    from_port         = 0
    to_port           = 65535
  }
}

resource "yandex_iam_service_account" "k8s" {
  name = "k8s-cluster-sa"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_agent" {
  folder_id = var.folder_id
  role      = "k8s.clusters.agent"
  member    = "serviceAccount:${yandex_iam_service_account.k8s.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_vpc" {
  folder_id = var.folder_id
  role      = "vpc.publicAdmin"
  member    = "serviceAccount:${yandex_iam_service_account.k8s.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_lb" {
  folder_id = var.folder_id
  role      = "load-balancer.admin"
  member    = "serviceAccount:${yandex_iam_service_account.k8s.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_tunnel" {
  folder_id = var.folder_id
  role      = "k8s.tunnelClusters.agent"
  member    = "serviceAccount:${yandex_iam_service_account.k8s.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_puller" {
  folder_id = var.folder_id
  role      = "container-registry.images.puller"
  member    = "serviceAccount:${yandex_iam_service_account.k8s.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_encrypterdecrypter" {
  folder_id = var.folder_id
  role      = "kms.keys.encrypterDecrypter"
  member    = "serviceAccount:${yandex_iam_service_account.k8s.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_logging" {
  folder_id = var.folder_id
  role      = "logging.writer"
  member    = "serviceAccount:${yandex_iam_service_account.k8s.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_monitoring" {
  folder_id = var.folder_id
  role      = "monitoring.editor"
  member    = "serviceAccount:${yandex_iam_service_account.k8s.id}"
}

resource "yandex_kubernetes_cluster" "k8s" {
  name       = "k8s-cluster"
  network_id = data.yandex_vpc_network.default.id

  master {
    zonal {
      zone      = var.zone
      subnet_id = data.yandex_vpc_subnet.default_a.id
    }
    public_ip          = true
    security_group_ids = [yandex_vpc_security_group.k8s.id]
  }

  service_account_id      = yandex_iam_service_account.k8s.id
  node_service_account_id = yandex_iam_service_account.k8s.id

  release_channel         = "STABLE"
  network_policy_provider = "CALICO"

  kms_provider {
    key_id = var.kms_key_id
  }

  depends_on = [
    yandex_resourcemanager_folder_iam_member.k8s_agent,
    yandex_resourcemanager_folder_iam_member.k8s_puller,
    yandex_resourcemanager_folder_iam_member.k8s_vpc,
    yandex_resourcemanager_folder_iam_member.k8s_lb,
    yandex_resourcemanager_folder_iam_member.k8s_tunnel,
    yandex_resourcemanager_folder_iam_member.k8s_encrypterdecrypter,
    yandex_resourcemanager_folder_iam_member.k8s_logging,
    yandex_resourcemanager_folder_iam_member.k8s_monitoring
  ]
}

resource "yandex_kubernetes_node_group" "worker" {
  cluster_id = yandex_kubernetes_cluster.k8s.id
  name       = "k8sworker"

  instance_template {
    platform_id = "standard-v3"

    resources {
      cores         = 2
      memory        = 4
      core_fraction = 20
    }

    boot_disk {
      type = "network-hdd"
      size = 64
    }

    network_interface {
      subnet_ids         = [data.yandex_vpc_subnet.default_a.id]
      nat                = true
      security_group_ids = [yandex_vpc_security_group.k8s.id]
    }

    container_runtime {
      type = "containerd"
    }
  }

  scale_policy {
    fixed_scale {
      size = 1
    }
  }

  allocation_policy {
    location {
      zone = var.zone
    }
  }

  maintenance_policy {
    auto_upgrade = false
    auto_repair  = true
  }

  depends_on = [
    yandex_resourcemanager_folder_iam_member.k8s_agent,
    yandex_resourcemanager_folder_iam_member.k8s_puller,
    yandex_resourcemanager_folder_iam_member.k8s_vpc,
    yandex_resourcemanager_folder_iam_member.k8s_lb,
    yandex_resourcemanager_folder_iam_member.k8s_tunnel,
    yandex_resourcemanager_folder_iam_member.k8s_encrypterdecrypter,
    yandex_resourcemanager_folder_iam_member.k8s_logging,
    yandex_resourcemanager_folder_iam_member.k8s_monitoring
  ]
}
