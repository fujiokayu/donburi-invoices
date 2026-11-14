resource "random_password" "secret_key_base" {
  length  = 128
  special = false
}

locals {
  database_url = "postgres://${aws_db_instance.main.username}:${random_password.db.result}@${aws_db_instance.main.address}:5432/${aws_db_instance.main.db_name}"
}

resource "aws_secretsmanager_secret" "database_url" {
  name                    = "${local.name}/DATABASE_URL"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "database_url" {
  secret_id     = aws_secretsmanager_secret.database_url.id
  secret_string = local.database_url
}

resource "aws_secretsmanager_secret" "secret_key_base" {
  name                    = "${local.name}/SECRET_KEY_BASE"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "secret_key_base" {
  secret_id     = aws_secretsmanager_secret.secret_key_base.id
  secret_string = random_password.secret_key_base.result
}

resource "aws_secretsmanager_secret" "invite_code" {
  name                    = "${local.name}/INVITE_CODE"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "invite_code" {
  secret_id     = aws_secretsmanager_secret.invite_code.id
  secret_string = var.invite_code
}
