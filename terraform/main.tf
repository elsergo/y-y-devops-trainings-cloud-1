locals {
  app                   = "catgpt"
  vm-user               = "ubuntu"
  folder_id             = var.TF_VAR_FOLDER_ID
  service-account       = "${local.app}-sa"
  service-account-roles = toset([
    "editor",
    "container-registry.images.puller",
    "monitoring.editor",
  ])
}

# Create VPC Network
resource "yandex_vpc_network" "foo" {
  name        = "yandexcloud"
  description = "VPC Yandex Cloud"
}

# Create VPC Subnet
resource "yandex_vpc_subnet" "foo" {
  name           = "subnet-zone-a1"
  description    = "VPC Yandex Cloud Subnet zone a1"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.foo.id
  v4_cidr_blocks = ["10.5.0.0/24"]
}

# Create SA
resource "yandex_iam_service_account" "foo" {
  name = "${local.folder_id}-${local.service-account}"
}

# Create SA Roles
resource "yandex_resourcemanager_folder_iam_member" "roles" {
  for_each   = local.service-account-roles
  folder_id  = local.folder_id
  member     = "serviceAccount:${yandex_iam_service_account.foo.id}"
  role       = each.key
  depends_on = [yandex_iam_service_account.foo]
}

# Create Instance Group
resource "yandex_compute_instance_group" "test1" {
  name                         = "test1"
  description                  = ""
  folder_id                    = local.folder_id
  service_account_id           = yandex_iam_service_account.foo.id
  deletion_protection          = false
  max_checking_health_duration = 0
  depends_on                   = [
    yandex_vpc_network.foo,
    yandex_vpc_subnet.foo,
    yandex_iam_service_account.foo,
    yandex_resourcemanager_folder_iam_member.roles
  ]

  instance_template {
    name               = ""
    description        = ""
    hostname           = ""
    labels             = {}
    service_account_id = yandex_iam_service_account.foo.id
    platform_id        = "standard-v2"

    boot_disk {
      mode = "READ_WRITE"
      initialize_params {
        description = ""
        image_id    = data.yandex_compute_image.coi.id
        size        = 32
        snapshot_id = ""
        type        = "network-hdd"
      }
    }

    network_interface {
      ip_address         = ""
      ipv4               = true
      ipv6               = false
      ipv6_address       = ""
      nat                = true
      nat_ip_address     = ""
      network_id         = yandex_vpc_network.foo.id
      subnet_ids         = [yandex_vpc_subnet.foo.id]
      security_group_ids = []
    }

    resources {
      core_fraction = 5
      cores         = 2
      gpus          = 0
      memory        = 1
    }

    metadata = {
      docker-compose = templatefile("docker-compose.yaml.tpl", {
        app-image-tag = var.TF_VAR_APP_IMAGE_TAG
      })
      install-unified-agent = 1
      serial-port-enable    = 0
      ssh-keys              = "${local.vm-user}:${var.TF_VAR_SSH_PUB}"
      user-data             = templatefile("cloud-config.yml.tpl", {
        vm-user            = local.vm-user
        vm-user-ssh-pubkey = var.TF_VAR_SSH_PUB
        ua-config          = filebase64("./unified-agent-app-config.yml")
      })
    }

    scheduling_policy {
      preemptible = true
    }
  }

  deploy_policy {
    max_creating     = 0
    max_deleting     = 0
    max_expansion    = 0
    max_unavailable  = 1
    startup_duration = 0
    strategy         = "proactive"
  }

  scale_policy {
    fixed_scale {
      size = 2
    }
  }

  allocation_policy {
    zones = [
      "ru-central1-a"
    ]
  }

  health_check {
    http_options {
      path = "/ping"
      port = 8080
    }
    interval            = 10
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  load_balancer {
    target_group_name        = "${local.app}-tg"
    target_group_description = "${local.app} target group"
  }
}

# Create NLB
resource "yandex_lb_network_load_balancer" "foo" {
  name = "${local.app}-balancer"
  type = "external"

  listener {
    name        = "http"
    port        = 80
    target_port = 8080
  }

  attached_target_group {
    target_group_id = yandex_compute_instance_group.test1.load_balancer[0].target_group_id
    healthcheck {
      name = "healthcheck"
      http_options {
        port = 8080
        path = "/ping"
      }
    }
  }
}
