variable "db_user" {
  type        = string
  description = "DB接続に使うユーザ名"
}
variable "db_password" {
  type        = string
  description = "DB接続に使うパスワード"
  sensitive   = true
}

variable "region" {
  type        = string
  description = "リージョン"
}

variable "account_id" {
  type        = string
  description = "アカウントID"
}
