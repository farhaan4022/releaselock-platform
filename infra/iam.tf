data "aws_iam_policy_document" "ecs_trust" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# Normal ECS execution role.
# Pulls images, sends logs and loads runtime secrets.

resource "aws_iam_role" "ecs_execution" {
  name               = "${var.project_name}-${var.environment}-ecs-exec"
  assume_role_policy = data.aws_iam_policy_document.ecs_trust.json

  tags = {
    Name = "${var.project_name}-${var.environment}-ecs-exec"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "runtime_secrets" {
  statement {
    actions = [
      "secretsmanager:GetSecretValue"
    ]

    resources = [
      aws_secretsmanager_secret.runtime_db.arn,
      aws_secretsmanager_secret.app.arn
    ]
  }
}

resource "aws_iam_role_policy" "runtime_secrets" {
  name   = "runtime-secrets"
  role   = aws_iam_role.ecs_execution.id
  policy = data.aws_iam_policy_document.runtime_secrets.json
}

# Application task role.
# Application code receives this identity at runtime.

resource "aws_iam_role" "app_task" {
  name               = "${var.project_name}-${var.environment}-app-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_trust.json

  tags = {
    Name = "${var.project_name}-${var.environment}-app-task"
  }
}

data "aws_iam_policy_document" "app_efs" {
  statement {
    actions = [
      "elasticfilesystem:ClientMount",
      "elasticfilesystem:ClientWrite"
    ]

    resources = [
      aws_efs_file_system.media.arn
    ]

    condition {
      test     = "StringEquals"
      variable = "elasticfilesystem:AccessPointArn"
      values   = [aws_efs_access_point.media.arn]
    }

    condition {
      test     = "Bool"
      variable = "elasticfilesystem:AccessedViaMountTarget"
      values   = ["true"]
    }
  }
}

resource "aws_iam_role_policy" "app_efs" {
  name   = "media-access"
  role   = aws_iam_role.app_task.id
  policy = data.aws_iam_policy_document.app_efs.json
}

# Trusted maintenance execution role.
# This is separate from the normal application execution role.

resource "aws_iam_role" "maintenance_execution" {
  name               = "${var.project_name}-${var.environment}-maintenance-exec"
  assume_role_policy = data.aws_iam_policy_document.ecs_trust.json

  tags = {
    Name = "${var.project_name}-${var.environment}-maintenance-exec"
  }
}

resource "aws_iam_role_policy_attachment" "maintenance_execution" {
  role       = aws_iam_role.maintenance_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "maintenance_secrets" {
  statement {
    actions = [
      "secretsmanager:GetSecretValue"
    ]

    resources = [
      aws_secretsmanager_secret.schema_owner.arn,
      aws_secretsmanager_secret.app.arn
    ]
  }
}

resource "aws_iam_role_policy" "maintenance_secrets" {
  name   = "maintenance-secrets"
  role   = aws_iam_role.maintenance_execution.id
  policy = data.aws_iam_policy_document.maintenance_secrets.json
}
