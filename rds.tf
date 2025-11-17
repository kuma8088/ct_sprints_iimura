# DBパラメータグループ
resource "aws_db_parameter_group" "sprints_db_parameter_group" {
  name   = "sprints-db-parameter-group"
  family = "mysql5.7"

  parameter {
    name  = "character_set_database"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }
}

# DBオプショングループ
resource "aws_db_option_group" "sprints_db_option_group" {
  name                 = "sprints-db-option-group"
  engine_name          = "mysql"
  major_engine_version = "5.7"

  option {
    option_name = "MARIADB_AUDIT_PLUGIN"
  }
}

# DBインスタンス
resource "aws_db_instance" "sprints_db_instance" {
  identifier                 = "sprints-db-instance"
  engine                     = "mysql"
  engine_version             = "5.7.44"
  instance_class             = "db.t3.small"
  allocated_storage          = 20
  max_allocated_storage      = 100
  storage_type               = "gp3"
  storage_encrypted          = true
  username                   = var.db_user
  password                   = var.db_password
  multi_az                   = true
  publicly_accessible        = false
  backup_window              = "09:10=09:40"
  backup_retention_period    = 30
  maintenance_window         = "mon:10:10-mon:10:40"
  auto_minor_version_upgrade = false
  deletion_protection        = false
  skip_final_snapshot        = false
  port                       = 3306
  apply_immediately          = false
  vpc_security_group_ids     = [aws_security_group.sprints_db_server_sg.id]
  parameter_group_name       = aws_db_parameter_group.sprints_db_parameter_group.name
  option_group_name          = aws_db_option_group.sprints_db_option_group.name
  db_subnet_group_name       = aws_db_subnet_group.sprints_db_subnet_group.name

  lifecycle {
    ignore_changes = [password]
  }
}
