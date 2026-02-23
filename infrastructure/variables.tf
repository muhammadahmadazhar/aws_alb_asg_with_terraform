# ============================================================================
# Variables
# ============================================================================

# --- General ---
variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "my-terraform-1"
}

variable "environment" {
  description = "Deployment environment (production, staging)"
  type        = string
  default     = "test"
}

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-2"
}

# --- Networking ---
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (ALB)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (EC2, RDS)"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}

variable "availability_zones" {
  description = "Availability zones for multi-AZ deployment"
  type        = list(string)
  default     = ["us-east-2a", "us-east-2b"]
}

# --- Compute ---
variable "ec2_instance_type" {
  description = "EC2 instance type for the Tax Engine"
  type        = string
  default     = "t3.micro"
}

variable "ec2_ami_id" {
  description = "AMI ID for EC2 instances (Ubuntu 22.04 LTS). Find latest with: aws ec2 describe-images --owners 099720109477 --filters 'Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*' --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId'"
  type        = string
}

variable "ec2_key_name" {
  description = "Name of the EC2 key pair for SSH access"
  type        = string
  default     = ""
}

variable "asg_min_size" {
  description = "Minimum number of instances in the ASG"
  type        = number
  default     = 1
}

variable "asg_max_size" {
  description = "Maximum number of instances in the ASG"
  type        = number
  default     = 3
}

variable "asg_desired_capacity" {
  description = "Desired number of instances in the ASG"
  type        = number
  default     = 1
}

variable "health_check_path" {
  description = "ALB health check path"
  type        = string
  default     = "/api/health/"
}

variable "acm_certificate_arn" {
  description = "ARN of ACM certificate for ALB HTTPS listener (must be in the same region). Leave empty to use HTTP only."
  type        = string
  default     = ""
}

# --- Database ---
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t4g.micro"
}

variable "db_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "igen_db"
}

variable "db_username" {
  description = "PostgreSQL master username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "PostgreSQL master password"
  type        = string
  sensitive   = true
}

# --- Django ---
variable "django_secret_key" {
  description = "Django SECRET_KEY for the application"
  type        = string
  sensitive   = true
}

variable "django_allowed_hosts" {
  description = "Comma-separated list of allowed hosts for Django"
  type        = string
  default     = "*"
}

# --- Storage / Frontend ---
variable "frontend_domain_name" {
  description = "Custom domain for the frontend CloudFront distribution (e.g., app.igen.com). Leave empty to use CloudFront default domain."
  type        = string
  default     = ""
}

variable "acm_certificate_arn_cloudfront" {
  description = "ARN of ACM certificate for CloudFront (must be in us-east-1). Leave empty to skip custom domain."
  type        = string
  default     = ""
}

# --- Monitoring ---
variable "alert_email" {
  description = "Email address for CloudWatch alarm notifications"
  type        = string
}

variable "github_repo" {
  type = string
}

variable "github_token" {
  type      = string
  sensitive = true
}