// we are creating the role for the end user
resource "aws_iam_role" "cluster_access_role" {
  name = "eks-developer-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::529601496118:root"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}