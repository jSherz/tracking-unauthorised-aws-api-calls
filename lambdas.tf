data "aws_iam_policy_document" "report_lambda" {
  statement {
    sid    = "AllowQueryingAccounts"
    effect = "Allow"

    actions = [
      "organizations:ListAccounts",
    ]

    resources = ["*"]
  }

  statement {
    sid       = "AllowQueryingAthena"
    effect    = "Allow"
    actions   = ["athena:StartQueryExecution", "athena:GetQueryExecution", "athena:GetQueryResults"]
    resources = [aws_athena_workgroup.main.arn]
  }

  statement {
    sid       = "AllowSendingReport"
    effect    = "Allow"
    actions   = ["ses:SendEmail"]
    resources = ["*"]
  }
}

module "report_lambda" {
  source = "./modules/lambda-function"

  name              = "tracking-unauthorised-aws-api-calls-report"
  description       = "Sends an e-mail report with unauthorised AWS API calls."
  entrypoint        = "src/lambdas/unauthorised-calls-report/index.ts"
  working_directory = ""
  iam_policy        = data.aws_iam_policy_document.report_lambda.json

  env_vars = {
    DATABASE          = aws_glue_catalog_database.main.name
    WORK_GROUP        = aws_athena_workgroup.main.name
    CATALOG           = aws_athena_data_catalog.main.name
    ENABLED_REGIONS   = join(",", var.enabled_regions)
    EMAIL_SOURCE      = var.email_source
    EMAIL_DESTINATION = var.email_destination
  }
}
