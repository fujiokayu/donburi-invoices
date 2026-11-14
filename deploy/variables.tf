variable "region" {
  description = "AWS region for the main stack."
  type        = string
  default     = "ap-northeast-1"
}

variable "exercise_account_role_arn" {
  description = "When set, the AWS providers assume this role so the whole stack deploys into a dedicated member account (e.g. arn:aws:iam::<ID>:role/OrganizationAccountAccessRole). Leave empty to deploy into the caller's own account."
  type        = string
  default     = ""
}

variable "project" {
  description = "Name prefix for resources."
  type        = string
  default     = "donburi"
}

variable "environment" {
  description = "Environment label."
  type        = string
  default     = "exercise"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.20.0.0/16"
}

variable "image_tag" {
  description = "Container image tag to deploy (pushed to the created ECR repo)."
  type        = string
  default     = "latest"
}

variable "container_port" {
  description = "Port the Rails app listens on inside the container."
  type        = number
  default     = 3000
}

variable "desired_count" {
  description = "Number of Fargate tasks."
  type        = number
  default     = 1
}

variable "task_cpu" {
  description = "Fargate task CPU units."
  type        = number
  default     = 512
}

variable "task_memory" {
  description = "Fargate task memory (MiB)."
  type        = number
  default     = 1024
}

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t4g.micro"
}

variable "db_allocated_storage" {
  description = "RDS allocated storage (GiB)."
  type        = number
  default     = 20
}

variable "db_engine_version" {
  description = "PostgreSQL engine version. Pin to a minor RDS currently offers (16.4 was retired); `aws rds describe-db-engine-versions --engine postgres` lists what is available."
  type        = string
  default     = "16.10"
}

variable "invite_code" {
  description = "Sign-up invite code for the exercise instance. Rotate per event."
  type        = string
  sensitive   = true
}

variable "exercise_banner" {
  description = "Non-removable training banner text."
  type        = string
  default     = "【訓練用】これはインシデント対応ハンズオンの演習環境です。実在のサービスではありません。"
}

variable "trusted_client_ips" {
  description = "Additional upstream proxy addresses to trust for X-Forwarded-For (comma/space separated). Set to the egress IP driving preparation traffic so request.remote_ip reflects the forwarded client."
  type        = string
  default     = ""
}

variable "participant_count" {
  description = "Number of read-only IAM users to pre-provision for the log-analysis role."
  type        = number
  default     = 8
}

variable "domain_name" {
  description = "Optional custom domain for CloudFront (e.g. donburi.example.com). Leave empty to use the default *.cloudfront.net domain."
  type        = string
  default     = ""
}

variable "acm_certificate_arn" {
  description = "ARN of an ACM certificate in us-east-1 covering domain_name. Required only when domain_name is set."
  type        = string
  default     = ""
}
