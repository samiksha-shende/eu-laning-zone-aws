# --- 1. SOVEREIGN KEY (KMS) ---
data "aws_caller_identity" "current" {}

resource "aws_kms_key" "eu_data_key" {
  description             = "GDPR Sovereign Key"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })
}

# --- 2. THE VAULT (S3 BUCKET) ---
resource "aws_s3_bucket" "log_archive" {
  bucket = "eu-sovereign-logs-${data.aws_caller_identity.current.account_id}"
  
  # checkov:skip=CKV_AWS_144: Data must remain within the EU Sovereign boundary.
}

# --- 3. SECURITY LAYERS ---

# Versioning (CKV_AWS_21)
resource "aws_s3_bucket_versioning" "log_versioning" {
  bucket = aws_s3_bucket.log_archive.id
  versioning_configuration { status = "Enabled" }
}

# Encryption (CKV_AWS_145)
resource "aws_s3_bucket_server_side_encryption_configuration" "log_encryption" {
  bucket = aws_s3_bucket.log_archive.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.eu_data_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# Logging (CKV_AWS_18)
resource "aws_s3_bucket_logging" "log_settings" {
  bucket        = aws_s3_bucket.log_archive.id
  target_bucket = aws_s3_bucket.log_archive.id
  target_prefix = "log/"
}

# Lifecycle & Multipart Cleanup (BC_AWS_300 / BC_AWS_2-61)
resource "aws_s3_bucket_lifecycle_configuration" "log_lifecycle" {
  bucket = aws_s3_bucket.log_archive.id
  rule {
    id     = "cleanup-and-archive"
    status = "Enabled"
    abort_incomplete_multipart_upload { days_after_initiation = 7 }
    expiration { days = 365 }
  }
}

# Public Access Block
resource "aws_s3_bucket_public_access_block" "log_archive_block" {
  bucket                  = aws_s3_bucket.log_archive.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Policy to allow CloudTrail Logging
resource "aws_s3_bucket_policy" "log_archive_policy" {
  bucket = aws_s3_bucket.log_archive.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.log_archive.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# Enable Event Notifications via EventBridge
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket      = aws_s3_bucket.log_archive.id
  eventbridge = true
}
