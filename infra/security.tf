resource "aws_security_group" "alb" {
  name        = "${var.project_name}-${var.environment}-alb"
  description = "Load balancer access"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-alb"
  }
}

resource "aws_security_group" "web" {
  name        = "${var.project_name}-${var.environment}-web"
  description = "InvenTree web tasks"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-web"
  }
}

resource "aws_security_group" "worker" {
  name        = "${var.project_name}-${var.environment}-worker"
  description = "InvenTree worker and maintenance tasks"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-worker"
  }
}

resource "aws_security_group" "rds" {
  name        = "${var.project_name}-${var.environment}-rds"
  description = "PostgreSQL access"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-rds"
  }
}

resource "aws_security_group" "efs" {
  name        = "${var.project_name}-${var.environment}-efs"
  description = "EFS mount access"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-efs"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id

  cidr_ipv4   = var.allowed_cidr
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"

  description = "HTTP access"
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id

  cidr_ipv4   = var.allowed_cidr
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"

  description = "HTTPS access"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_web" {
  security_group_id = aws_security_group.alb.id

  referenced_security_group_id = aws_security_group.web.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"

  description = "ALB to web tasks"
}

resource "aws_vpc_security_group_ingress_rule" "web_from_alb" {
  security_group_id = aws_security_group.web.id

  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"

  description = "Traffic from ALB"
}

resource "aws_vpc_security_group_egress_rule" "web_outbound" {
  security_group_id = aws_security_group.web.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"

  description = "Web outbound access"
}

resource "aws_vpc_security_group_egress_rule" "worker_outbound" {
  security_group_id = aws_security_group.worker.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"

  description = "Worker outbound access"
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_web" {
  security_group_id = aws_security_group.rds.id

  referenced_security_group_id = aws_security_group.web.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"

  description = "PostgreSQL from web"
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_worker" {
  security_group_id = aws_security_group.rds.id

  referenced_security_group_id = aws_security_group.worker.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"

  description = "PostgreSQL from worker"
}

resource "aws_vpc_security_group_ingress_rule" "efs_from_web" {
  security_group_id = aws_security_group.efs.id

  referenced_security_group_id = aws_security_group.web.id
  from_port                    = 2049
  to_port                      = 2049
  ip_protocol                  = "tcp"

  description = "NFS from web"
}

resource "aws_vpc_security_group_ingress_rule" "efs_from_worker" {
  security_group_id = aws_security_group.efs.id

  referenced_security_group_id = aws_security_group.worker.id
  from_port                    = 2049
  to_port                      = 2049
  ip_protocol                  = "tcp"

  description = "NFS from worker"
}
