# Pre-provisioned read-only IAM users for the log-analysis role.
#
# Scoped to the exercise CloudWatch log group only (plus the account-wide
# Describe/Insights actions the console needs). Hand these out and verify login
# during the rehearsal; a login failure on the day must never block the
# exercise, which is why the raw logs are also exported to a file.

data "aws_iam_policy_document" "participant_logs_read" {
  # Reading the exercise log group's events and running Logs Insights queries.
  statement {
    sid = "ReadExerciseLogGroup"
    actions = [
      "logs:GetLogEvents",
      "logs:FilterLogEvents",
      "logs:GetLogRecord",
      "logs:DescribeLogStreams",
      "logs:StartQuery",
    ]
    resources = [
      aws_cloudwatch_log_group.app.arn,
      "${aws_cloudwatch_log_group.app.arn}:*",
    ]
  }

  # These Logs Insights / console actions do not support resource-level scoping.
  statement {
    sid = "InsightsAndConsole"
    actions = [
      "logs:DescribeLogGroups",
      "logs:StopQuery",
      "logs:GetQueryResults",
      "logs:DescribeQueries",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "participant_logs_read" {
  name        = "${local.name}-analyst-readonly"
  description = "Read-only access to the exercise CloudWatch log group"
  policy      = data.aws_iam_policy_document.participant_logs_read.json
}

resource "aws_iam_user" "participant" {
  count         = var.participant_count
  name          = "${local.name}-analyst-${count.index + 1}"
  force_destroy = true
}

resource "aws_iam_user_login_profile" "participant" {
  count                   = var.participant_count
  user                    = aws_iam_user.participant[count.index].name
  password_length         = 20
  password_reset_required = false
}

resource "aws_iam_user_policy_attachment" "participant" {
  count      = var.participant_count
  user       = aws_iam_user.participant[count.index].name
  policy_arn = aws_iam_policy.participant_logs_read.arn
}
