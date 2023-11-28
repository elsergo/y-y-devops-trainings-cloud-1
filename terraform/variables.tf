variable "TF_VAR_FOLDER_ID" {
  type        = string
  description = "Yandex Cloud folder id"
}

variable "TF_VAR_SSH_PUB" {
  type        = string
  description = "Yandex Cloud VM ssh pubkey"
}

variable "TF_VAR_APP_IMAGE_TAG" {
  type = string
  description = "Docker tag for App image"
}