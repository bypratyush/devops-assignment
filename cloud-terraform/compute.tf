# AMI: the latest Amazon Linux 2023, resolved through the public SSM parameter
# AWS publishes for it. Works in every region (AMI IDs differ per region), and
# LocalStack serves the same parameter path. Set var.ami_id to pin one instead.
data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

locals {
  ami_id = coalesce(var.ami_id, nonsensitive(data.aws_ssm_parameter.al2023.value))
}

resource "aws_instance" "web" {
  ami                    = local.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]
  iam_instance_profile   = aws_iam_instance_profile.web.name
  key_name               = var.key_name

  # Boot script: install nginx, serve a page, ship the boot log to S3.
  user_data = templatefile("${path.module}/templates/user_data.sh.tftpl", {
    project = var.project_name
    owner   = var.owner
    roll_no = var.roll_no
    bucket  = aws_s3_bucket.artifacts.bucket
  })
  user_data_replace_on_change = true

  # IMDSv2 only: blocks the classic SSRF trick of reading role credentials
  # from http://169.254.169.254 with a plain GET.
  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = 8
    encrypted   = true
  }

  tags = { Name = "${var.project_name}-web" }

  # EXPLICIT dependency. Nothing above references the route table, so from
  # the references alone Terraform would happily launch this instance in
  # parallel with the route table. The user_data runs `dnf install` on first
  # boot and needs the 0.0.0.0/0 -> IGW route to already exist, otherwise the
  # install fails once and is never retried. depends_on encodes that hidden,
  # behavioural dependency that Terraform cannot see in the code.
  depends_on = [aws_route_table_association.public]
}
