resource "aws_s3_bucket" "this" {
  bucket = var.name
}

resource "aws_s3_bucket_acl" "this" {
  for_each = var.enable_log_delivery ? { configured : true } : {}

  bucket = aws_s3_bucket.this.bucket

  access_control_policy {
    grant {
      grantee {
        id   = data.aws_canonical_user_id.this.id
        type = "CanonicalUser"
      }

      permission = "FULL_CONTROL"
    }

    grant {
      grantee {
        type = "CanonicalUser"
        id   = "c4c1ede66af53448b93c283ce9448c4ba468c9432aa01d700d3878632f77d2d0" # awslogsdelivery
      }

      permission = "FULL_CONTROL"
    }

    owner {
      id = data.aws_canonical_user_id.this.id
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.bucket

  rule {
    object_ownership = var.enable_log_delivery ? "BucketOwnerPreferred" : "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "this" {
  for_each = var.versioning ? { configured : true } : {}

  bucket = aws_s3_bucket.this.bucket

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  for_each = var.apply_policy ? { configured : true } : {}

  bucket = aws_s3_bucket.this.bucket

  policy = var.policy
}
