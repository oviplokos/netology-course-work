variable "yandex_cloud_token" {
  type        = string
  description = "Данная переменная потребует ввести секретный токен в консоли при запуске terraform plan/apply"
  sensitive   = true
}
variable "secret_key" {
  type        = string
  description = "YaCloud secret-key"

}
variable "key_identify" {
  type        = string
  description = "YaCloud secret-key identify"
}
variable "public_key_path" {
  type        = string
  description = "ssh key public path"
}
variable "yandex_folder_id" {
  type        = string
  description = "yandex folder id"
}
variable "yandex_account_id" {
  type        = string
  description = "yandex account id"
}
