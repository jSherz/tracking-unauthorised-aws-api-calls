resource "aws_athena_data_catalog" "main" {
  name        = local.project_name
  description = "Used to monitor AWS API calls which have been denied across the AWS organization."
  parameters = {
    "catalog-id" = aws_glue_catalog_database.main.catalog_id
  }
  type = "GLUE"
}

module "athena_results" {
  source = "./modules/s3-bucket"

  name = "${local.project_name}-${data.aws_caller_identity.this.account_id}-${data.aws_region.this.name}"
}

resource "aws_athena_workgroup" "main" {
  name        = local.project_name
  description = "Used to monitor AWS API calls which have been denied across the AWS organization."

  configuration {
    result_configuration {
      output_location = "s3://${module.athena_results.name}"

      acl_configuration {
        s3_acl_option = "BUCKET_OWNER_FULL_CONTROL"
      }
    }
  }
}
