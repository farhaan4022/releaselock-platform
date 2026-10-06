output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "db_subnet_ids" {
  value = aws_subnet.db[*].id
}

output "availability_zones" {
  value = local.azs
}

output "security_group_ids" {
  value = {
    alb    = aws_security_group.alb.id
    web    = aws_security_group.web.id
    worker = aws_security_group.worker.id
    rds    = aws_security_group.rds.id
    efs    = aws_security_group.efs.id
  }
}

output "db_subnet_group_name" {
  value = aws_db_subnet_group.main.name
}

output "rds_endpoint" {
  value = aws_db_instance.main.endpoint
}

output "rds_master_secret_arn" {
  value = aws_db_instance.main.master_user_secret[0].secret_arn
}

output "efs_file_system_id" {
  value = aws_efs_file_system.media.id
}

output "efs_access_point_id" {
  value = aws_efs_access_point.media.id
}

output "secret_arns" {
  value = {
    schema_owner = aws_secretsmanager_secret.schema_owner.arn
    runtime_db   = aws_secretsmanager_secret.runtime_db.arn
    app          = aws_secretsmanager_secret.app.arn
  }
}

output "ecr_repositories" {
  value = {
    app   = aws_ecr_repository.app.repository_url
    proxy = aws_ecr_repository.proxy.repository_url
  }
}

output "runtime_roles" {
  value = {
    execution   = aws_iam_role.ecs_execution.arn
    app_task    = aws_iam_role.app_task.arn
    maintenance = aws_iam_role.maintenance_execution.arn
  }
}
