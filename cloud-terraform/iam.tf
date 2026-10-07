# Least privilege for the instance: it may read and write objects in ONE
# bucket and nothing else. No access keys anywhere - the instance gets
# short-lived credentials from the role through the instance metadata service.

data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "web" {
  name               = "${var.project_name}-web-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

data "aws_iam_policy_document" "artifacts_rw" {
  statement {
    sid       = "ListTheOneBucket"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.artifacts.arn]
  }

  statement {
    sid       = "ReadWriteObjectsInIt"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["${aws_s3_bucket.artifacts.arn}/*"]
  }
}

resource "aws_iam_role_policy" "artifacts_rw" {
  name   = "artifacts-bucket-rw"
  role   = aws_iam_role.web.id
  policy = data.aws_iam_policy_document.artifacts_rw.json
}

# EC2 cannot take a role directly; it takes an instance profile wrapping one.
resource "aws_iam_instance_profile" "web" {
  name = "${var.project_name}-web-profile"
  role = aws_iam_role.web.name
}
