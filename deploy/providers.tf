provider "aws" {
  region = var.region

  # When exercise_account_role_arn is set, assume it so the whole stack deploys
  # into the dedicated member account instead of the caller's own account.
  dynamic "assume_role" {
    for_each = var.exercise_account_role_arn == "" ? [] : [1]
    content {
      role_arn     = var.exercise_account_role_arn
      session_name = "donburi-exercise-deploy"
    }
  }

  default_tags {
    tags = local.tags
  }
}

# CloudFront custom-domain certificates must live in us-east-1.
provider "aws" {
  alias  = "use1"
  region = "us-east-1"

  dynamic "assume_role" {
    for_each = var.exercise_account_role_arn == "" ? [] : [1]
    content {
      role_arn     = var.exercise_account_role_arn
      session_name = "donburi-exercise-deploy"
    }
  }

  default_tags {
    tags = local.tags
  }
}
