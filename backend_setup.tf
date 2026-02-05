resource "aws_s3_bucket" "terraform_state" {
  bucket = "sovereign-state-storage-${data.aws_caller_identity.current.account_id}"
  
  # Prevent accidental deletion of the state file
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# DynamoDB table for "State Locking" 
# This prevents two people/pipelines from running terraform at the same time
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-state-locking"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
