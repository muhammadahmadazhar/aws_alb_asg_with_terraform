# ============================================================================
# Database Module — RDS PostgreSQL
# ============================================================================

variable "project_name"       { type = string }
variable "environment"        { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "rds_security_group_id" { type = string }
variable "instance_class"     { type = string }
variable "allocated_storage"  { type = number }
variable "db_name"            { type = string }
variable "db_username"        { 
  type = string 
  sensitive = true 
  }
variable "db_password"        { 
  type = string 
  sensitive = true 
  }

# --- DB Subnet Group ---
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-db-subnet"
  subnet_ids = var.private_subnet_ids

  tags = { Name = "${var.project_name}-${var.environment}-db-subnet-group" }
}

# --- RDS PostgreSQL Instance ---
resource "aws_db_instance" "main" {
  identifier     = "${var.project_name}-${var.environment}-db"
  engine         = "postgres"
  engine_version = "14"
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.allocated_storage * 2  # Auto-scaling up to 2x
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.rds_security_group_id]

  multi_az               = false  # Single-AZ as per proposal (cost-optimised)
  publicly_accessible    = false
  skip_final_snapshot    = false
  final_snapshot_identifier = "${var.project_name}-${var.environment}-final-snapshot"

  backup_retention_period = 7
  backup_window           = "03:00-04:00"      # UTC
  maintenance_window      = "sun:04:30-sun:05:30"

  performance_insights_enabled = true
  monitoring_interval          = 60
  monitoring_role_arn          = aws_iam_role.rds_monitoring.arn

  deletion_protection = false  # Set to true after go-live

  tags = { Name = "${var.project_name}-${var.environment}-postgresql" }
}

# --- Enhanced Monitoring IAM Role ---
resource "aws_iam_role" "rds_monitoring" {
  name = "${var.project_name}-${var.environment}-rds-monitoring"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "monitoring.rds.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# --- Outputs ---
output "db_endpoint"    { value = aws_db_instance.main.address }
output "db_instance_id" { value = aws_db_instance.main.identifier }
output "db_port"        { value = aws_db_instance.main.port }