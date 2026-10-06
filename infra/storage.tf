resource "aws_efs_file_system" "media" {
  encrypted = true

  tags = {
    Name = "${var.project_name}-${var.environment}-media"
  }
}

resource "aws_efs_mount_target" "media" {
  count = 2

  file_system_id  = aws_efs_file_system.media.id
  subnet_id       = aws_subnet.db[count.index].id
  security_groups = [aws_security_group.efs.id]
}

resource "aws_efs_access_point" "media" {
  file_system_id = aws_efs_file_system.media.id

  posix_user {
    uid = 1000
    gid = 1000
  }

  root_directory {
    path = "/media"

    creation_info {
      owner_uid   = 1000
      owner_gid   = 1000
      permissions = "0755"
    }
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-media"
  }
}

resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-${var.environment}-db"

  engine         = "postgres"
  engine_version = "17.11"
  instance_class = "db.t4g.small"

  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = "inventree"
  username = "releaselock_admin"
  port     = 5432

  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  publicly_accessible = false
  multi_az            = false

  backup_retention_period = 1

  auto_minor_version_upgrade = true
  apply_immediately          = true

  performance_insights_enabled = false
  deletion_protection          = false
  skip_final_snapshot          = true
  copy_tags_to_snapshot        = true

  tags = {
    Name = "${var.project_name}-${var.environment}-db"
  }
}
