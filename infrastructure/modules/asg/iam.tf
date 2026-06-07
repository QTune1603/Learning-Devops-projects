# 1. IAM Role for Tomcat EC2 instances
resource "aws_iam_role" "tomcat_role" {
  name_prefix = "${var.environment}-tomcat-role-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.environment}-tomcat-iam-role"
    Environment = var.environment
  }
}

# 2. IAM Policy to allow reading artifacts from S3 bucket
resource "aws_iam_policy" "s3_read_policy" {
  name_prefix = "${var.environment}-s3-read-policy-"
  description = "Allows Tomcat instances to download artifacts from S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = "${var.s3_bucket_arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = var.s3_bucket_arn
      }
    ]
  })
}

# 3. Attach Policy to IAM Role
resource "aws_iam_role_policy_attachment" "tomcat_s3_attachment" {
  role       = aws_iam_role.tomcat_role.name
  policy_arn = aws_iam_policy.s3_read_policy.arn
}

resource "aws_iam_role_policy_attachment" "tomcat_ssm" {
  role       = aws_iam_role.tomcat_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


# 4. Create IAM Instance Profile for EC2 Launch Template to reference
resource "aws_iam_instance_profile" "tomcat_profile" {
  name_prefix = "${var.environment}-tomcat-profile-"
  role        = aws_iam_role.tomcat_role.name
}
