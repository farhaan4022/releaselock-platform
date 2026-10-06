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
