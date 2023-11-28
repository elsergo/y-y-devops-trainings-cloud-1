terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"

  backend "s3" {
    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }
    region                      = "ru-central1"
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_credentials_validation = true
    skip_s3_checksum            = true
  }
}

provider "yandex" {
  service_account_key_file = "./sa-key.json"
  folder_id                = local.folder_id
  zone                     = "ru-central1-a"
}
