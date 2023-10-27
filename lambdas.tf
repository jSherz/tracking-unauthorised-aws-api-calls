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
    sid       = "AllowQueryingAthenaWorkGroup"
    effect    = "Allow"
    actions   = ["athena:StartQueryExecution", "athena:GetQueryExecution", "athena:GetQueryResults"]
    resources = [aws_athena_workgroup.main.arn]
  }

  statement {
    sid       = "AllowQueryingAthenaDataCatalog"
    effect    = "Allow"
    actions   = ["athena:GetDataCatalog"]
    resources = [aws_athena_data_catalog.main.arn]
  }

  statement {
    sid    = "AllowQueryingGlue"
    effect = "Allow"
    actions = [
      "glue:BatchGetTable",
      "glue:GetTable",
    ]
    resources = [
      aws_glue_catalog_database.main.arn,
      aws_glue_catalog_table.main.arn,
      "arn:aws:glue:${data.aws_region.this.name}:${data.aws_caller_identity.this.id}:catalog",
    ]
  }

  statement {
    sid       = "AllowSendingReport"
    effect    = "Allow"
    actions   = ["ses:SendEmail"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowWritingAthenaResults"
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject",
    ]
    resources = [
      module.athena_results.arn,
      "${module.athena_results.arn}/*",
    ]
  }

  statement {
    sid    = "AllowReadingCloudTrailData"
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::${var.cloudtrail_bucket}",
      "arn:aws:s3:::${var.cloudtrail_bucket}/*",
    ]
  }
}

module "report_lambda" {
  source = "./modules/lambda-function"

  name              = "tracking-unauthorised-aws-api-calls-report"
  description       = "Sends an e-mail report with unauthorised AWS API calls."
  entrypoint        = "src/lambdas/unauthorised-calls-report/index.ts"
  working_directory = ""
  iam_policy        = data.aws_iam_policy_document.report_lambda.json
  timeout           = 600
  memory_size       = 1024

  env_vars = {
    DATABASE                = aws_glue_catalog_database.main.name
    WORK_GROUP              = aws_athena_workgroup.main.name
    CATALOG                 = aws_athena_data_catalog.main.name
    ENABLED_REGIONS         = join(",", var.enabled_regions)
    EMAIL_SOURCE            = var.email_source
    EMAIL_DESTINATION       = var.email_destination
    POWERTOOLS_SERVICE_NAME = local.project_name
  }

  event_rule_arns = {
    trigger_report = aws_cloudwatch_event_rule.trigger_report.arn
  }
}

resource "aws_cloudwatch_event_rule" "trigger_report" {
  name = local.project_name

  schedule_expression = "cron(0 7 ? * 2 *)"
}
