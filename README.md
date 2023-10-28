# tracking-unauthorised-aws-api-calls

This project accompanies [a blog post on jSherz.com] that details how we can
review unauthorised AWS API calls to form platform improvements.

[a blog post on jSherz.com]: https://jsherz.com/aws/athena/glue/cloudtrail/2023/10/28/tracking-unauthorised-aws-api-calls.html

## Getting started

```bash
# 1. Install Terraform v1.5

# 2. Setup AWS credentials in an organization management account

# 3. Configure remote state, if applicable

# 4. Initialise Terraform
terraform init

# 5. Run and review a plan
terraform plan -out plan

# 6. If you're happy with the changes, apply the plan
terraform apply plan
```

## Technologies

This project is an example of NodeJS Lambda functions being collocated in a
Terraform codebase. The [jSherz/node-lambda-packager Terraform provider]
bundles all dependencies together into a single JavaScript file, and then zips
it up ready for Lambda to use.

[jSherz/node-lambda-packager Terraform provider]: https://registry.terraform.io/providers/jSherz/node-lambda-packager
