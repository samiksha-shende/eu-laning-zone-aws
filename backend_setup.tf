resource "aws_s3_bucket" "terraform_state" {
  bucket = "sovereign-state-storage-266859253671"
  

  # checkov:skip=CKV_AWS_144: Cross-region replication is too expensive for this lab
  # checkov:skip=CKV2_AWS_62: Event notifications not required for state files
  
  lifecycle {
    prevent_destroy = true
  }
}

# CKV2_AWS_6: Block all public access
resource "aws_s3_bucket_public_access_block" "state_lock" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CKV_AWS_145: Encrypt with KMS
resource "aws_s3_bucket_server_side_encryption_configuration" "state_encryption" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.eu_data_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# CKV2_AWS_61: Add Lifecycle Configuration (Move old state to cheaper storage)
resource "aws_s3_bucket_lifecycle_configuration" "state_lifecycle" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    id     = "archive_old_state"
    status = "Enabled"
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
}

# CKV_AWS_18: Enable Access Logging
# Note: Usually you'd send these to your 'log-archive' bucket
resource "aws_s3_bucket_logging" "state_logging" {
  bucket = aws_s3_bucket.terraform_state.id
  target_bucket = "eu-sovereign-logs-266859253671" # Your existing log bucket
  target_prefix = "tf-state-logs/"
}

resource "aws_s3_bucket_versioning" "state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# DynamoDB table for "State Locking" 
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-state-locking"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  # CKV_AWS_28: Enable Point-in-time recovery (Backups)
  point_in_time_recovery {
    enabled = true
  }

  # CKV_AWS_119: Encrypt with Customer Managed KMS Key
  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.eu_data_key.arn
  }
}
