# ============================================================================
# Compute Module — ALB + Auto Scaling Group + EC2 Launch Template
# ============================================================================

variable "project_name"          { type = string }
variable "environment"           { type = string }
variable "vpc_id"                { type = string }
variable "public_subnet_ids"     { type = list(string) }
variable "private_subnet_ids"    { type = list(string) }
variable "alb_security_group_id" { type = string }
variable "ec2_security_group_id" { type = string }
variable "instance_type"         { type = string }
variable "ami_id"                { type = string }
variable "key_name"              { type = string }
variable "min_size"              { type = number }
variable "max_size"              { type = number }
variable "desired_capacity"      { type = number }
variable "health_check_path"     { type = string }
variable "acm_certificate_arn"   { type = string }
variable "github_repo"           { type = string }
variable "github_token"          { 
    type = string 
    sensitive = true 
    }
variable "db_host"               { type = string }
variable "db_name"               { type = string }
variable "db_username"           { 
    type = string 
    sensitive = true 
    }
variable "db_password"           { 
    type = string 
    sensitive = true 
    }
variable "django_secret_key"     { 
    type = string 
    sensitive = true 
    }
variable "allowed_hosts"         { type = string }
# variable "reports_bucket_name"   { type = string }

# --- IAM Role for EC2 (access to S3 reports bucket + CloudWatch) ---
resource "aws_iam_role" "ec2" {
  name = "${var.project_name}-${var.environment}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

# resource "aws_iam_role_policy" "ec2_s3" {
#   name = "${var.project_name}-${var.environment}-ec2-s3-policy"
#   role = aws_iam_role.ec2.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect   = "Allow"
#         Action   = ["s3:GetObject", "s3:PutObject", "s3:ListBucket", "s3:DeleteObject"]
#         Resource = [
#           "arn:aws:s3:::${var.reports_bucket_name}",
#           "arn:aws:s3:::${var.reports_bucket_name}/*"
#         ]
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "ec2_cloudwatch" {
#   role       = aws_iam_role.ec2.name
#   policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
# }

resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project_name}-${var.environment}-ec2-profile"
  role = aws_iam_role.ec2.name
}

# --- Application Load Balancer ---
resource "aws_lb" "main" {
  name               = "${var.project_name}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false  # Set to true for production safety

  tags = { Name = "${var.project_name}-${var.environment}-alb" }
}

# --- Target Group ---
resource "aws_lb_target_group" "app" {
  name     = "${var.project_name}-${var.environment}-tg"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    path                = var.health_check_path
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 10
    interval            = 30
    matcher             = "200"
  }

  stickiness {
    type            = "lb_cookie"
    cookie_duration = 86400
    enabled         = false
  }

  tags = { Name = "${var.project_name}-${var.environment}-tg" }
}

# --- ALB Listener: HTTP (redirect to HTTPS if cert exists, otherwise serve) ---
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = var.acm_certificate_arn != "" ? "redirect" : "forward"

    # Forward when no HTTPS cert
    dynamic "forward" {
      for_each = var.acm_certificate_arn == "" ? [1] : []
      content {
        target_group {
          arn = aws_lb_target_group.app.arn
        }
      }
    }

    # Redirect to HTTPS when cert exists
    dynamic "redirect" {
      for_each = var.acm_certificate_arn != "" ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }
}

# --- ALB Listener: HTTPS (only created when ACM cert is provided) ---
resource "aws_lb_listener" "https" {
  count             = var.acm_certificate_arn != "" ? 1 : 0
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# --- EC2 Launch Template ---
resource "aws_launch_template" "app" {
  name_prefix   = "${var.project_name}-${var.environment}-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name != "" ? var.key_name : null

  iam_instance_profile {
    arn = aws_iam_instance_profile.ec2.arn
  }

  vpc_security_group_ids = [var.ec2_security_group_id]

  user_data = base64encode(templatefile("${path.module}/../../scripts/user_data.sh", {
    github_repo        = var.github_repo
    github_token       = var.github_token
    db_host            = var.db_host
    db_name            = var.db_name
    db_username        = var.db_username
    db_password        = var.db_password
    django_secret_key  = var.django_secret_key
    # allowed_hosts      = var.allowed_hosts
    allowed_hosts      = aws_lb.main.dns_name
    # reports_bucket     = var.reports_bucket_name
    environment        = var.environment
  }))

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size           = 30
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
    }
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-${var.environment}-app"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}


# --- Auto Scaling Group ---
resource "aws_autoscaling_group" "app" {
  name                = "${var.project_name}-${var.environment}-asg"
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_capacity
  vpc_zone_identifier = var.private_subnet_ids
  target_group_arns   = [aws_lb_target_group.app.arn]

  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-app"
    propagate_at_launch = true
  }
}

# --- Auto Scaling Policy: CPU Target Tracking ---
resource "aws_autoscaling_policy" "cpu" {
  name                   = "${var.project_name}-${var.environment}-cpu-scaling"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

# --- Auto Scaling Policy: Request Count Target Tracking ---
resource "aws_autoscaling_policy" "requests" {
  name                   = "${var.project_name}-${var.environment}-request-scaling"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = "${aws_lb.main.arn_suffix}/${aws_lb_target_group.app.arn_suffix}"
    }
    target_value = 500.0
  }
}

# --- Outputs ---
output "alb_dns_name"            { value = aws_lb.main.dns_name }
output "alb_zone_id"             { value = aws_lb.main.zone_id }
output "alb_arn_suffix"          { value = aws_lb.main.arn_suffix }
output "target_group_arn_suffix" { value = aws_lb_target_group.app.arn_suffix }
output "asg_name"                { value = aws_autoscaling_group.app.name }