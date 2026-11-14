output "ecr_repository_url" {
  description = "Push the container image here."
  value       = aws_ecr_repository.app.repository_url
}

output "alb_dns_name" {
  description = "Internal ALB hostname (reachable only via CloudFront)."
  value       = aws_lb.main.dns_name
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain."
  value       = aws_cloudfront_distribution.main.domain_name
}

output "app_url" {
  description = "Public URL of the exercise instance."
  value       = local.use_custom_domain ? "https://${var.domain_name}" : "https://${aws_cloudfront_distribution.main.domain_name}"
}

output "rds_endpoint" {
  description = "RDS endpoint (private)."
  value       = aws_db_instance.main.address
}

output "participant_console_url" {
  description = "AWS console sign-in URL for the pre-provisioned analyst users."
  value       = "https://${data.aws_caller_identity.current.account_id}.signin.aws.amazon.com/console"
}

output "participant_logins" {
  description = "Usernames and generated passwords for the analyst users (verify at rehearsal)."
  sensitive   = true
  value = {
    for i, u in aws_iam_user.participant :
    u.name => aws_iam_user_login_profile.participant[i].password
  }
}
