resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}"
  subnet_ids = aws_subnet.db[*].id

  tags = {
    Name = "${var.project_name}-${var.environment}"
  }
}
