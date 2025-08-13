# Bucket for Open WebUI backend
resource "aws_s3_bucket" "openwebui_bucket" {
  bucket = "openwebui-backend-bucket-${local.prefix}"
  force_destroy = true

  tags = {
    Name        = "Open WebUI bucket"
    Environment = "Dev"
  }
}