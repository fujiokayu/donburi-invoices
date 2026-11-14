locals {
  name = "${var.project}-${var.environment}"

  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
    Purpose     = "incident-response-exercise"
  }

  use_custom_domain = var.domain_name != "" && var.acm_certificate_arn != ""

  # The public hostname browsers actually use. Rails must generate redirect URLs
  # with this (not the ALB's internal DNS name, which is reachable only through
  # CloudFront), so it feeds both APP_HOST and config.hosts.
  public_host = local.use_custom_domain ? var.domain_name : aws_cloudfront_distribution.main.domain_name

  azs = slice(data.aws_availability_zones.available.names, 0, 2)
}
