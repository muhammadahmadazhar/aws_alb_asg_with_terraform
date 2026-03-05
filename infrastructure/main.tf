# ============================================================================
# Igen Tax Engine — AWS Infrastructure (ASG + ALB + EC2 + RDS)
# ============================================================================
# This Terraform configuration provisions the production environment as
# approved in the Implementation Proposal:
#   - VPC with public/private subnets across 2 AZs
#   - EC2 (t3.medium) in Auto Scaling Group behind an ALB
#   - RDS PostgreSQL 14 (db.t3.small, Single-AZ)
#   - S3 + CloudFront for Vue.js frontend
#   - S3 for reports/uploads
#   - CloudWatch alarms and monitoring
# ============================================================================


terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

    # Uncomment after creating the S3 bucket and DynamoDB table for state management.
  # See README for bootstrap instructions.
  # backend "s3" {
  #   bucket         = "igen-terraform-state"
  #   key            = "production/terraform.tfstate"
  #   region         = "us-east-2"
  #   dynamodb_table = "igen-terraform-locks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# CloudFront requires ACM certificates in us-east-1
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}


module "networking" {
  source = "./modules/networking"

  project_name      = var.project_name
  environment       = var.environment
  vpc_cidr          = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
}

# -----------------------------------------------------------------------------
# Compute (ALB + ASG + EC2)
# -----------------------------------------------------------------------------
module "compute" {
  source = "./modules/compute"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.networking.vpc_id
  public_subnet_ids  = module.networking.public_subnet_ids
  private_subnet_ids = module.networking.private_subnet_ids
  alb_security_group_id = module.networking.alb_security_group_id
  ec2_security_group_id = module.networking.ec2_security_group_id

  instance_type      = var.ec2_instance_type
  ami_id             = var.ec2_ami_id
  key_name           = var.ec2_key_name
  min_size           = var.asg_min_size
  max_size           = var.asg_max_size
  desired_capacity   = var.asg_desired_capacity
  health_check_path  = var.health_check_path
  acm_certificate_arn = var.acm_certificate_arn

  github_repo        = var.github_repo
  github_token       = var.github_token
  db_host            = module.database.db_endpoint
  db_name            = var.db_name
  db_username        = var.db_username
  db_password        = var.db_password
  django_secret_key  = var.django_secret_key
  allowed_hosts      = var.django_allowed_hosts

#   reports_bucket_name = module.storage.reports_bucket_name
}

# -----------------------------------------------------------------------------
# Database (RDS PostgreSQL)
# -----------------------------------------------------------------------------
module "database" {
  source = "./modules/database"

  project_name       = var.project_name
  environment        = var.environment
  private_subnet_ids = module.networking.private_subnet_ids
  rds_security_group_id = module.networking.rds_security_group_id

  instance_class     = var.db_instance_class
  allocated_storage  = var.db_allocated_storage
  db_name            = var.db_name
  db_username        = var.db_username
  db_password        = var.db_password
}

# # -----------------------------------------------------------------------------
# # Monitoring (CloudWatch)
# # -----------------------------------------------------------------------------
# module "monitoring" {
#   source = "./modules/monitoring"

#   project_name         = var.project_name
#   environment          = var.environment
#   asg_name             = module.compute.asg_name
#   alb_arn_suffix       = module.compute.alb_arn_suffix
#   target_group_arn_suffix = module.compute.target_group_arn_suffix
#   db_instance_id       = module.database.db_instance_id
#   alert_email          = var.alert_email
# }

