# The IAM Role GitHub Actions will assume
resource "aws_iam_role" "github_actions_role" {
  name = "github-actions-terraform-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::266859253671:oidc-provider/token.actions.githubusercontent.com"
        }
        Condition = {
          StringLike = {
            # ONLY allow your specific repo and branch to use this role
            "token.actions.githubusercontent.com:sub": "repo:github.com/samiksha-shende/eu-laning-zone-aws.git"
          }
          StringEquals = {
            "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}
