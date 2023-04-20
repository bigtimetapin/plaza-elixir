resource "aws_s3_bucket" "static-uploads-dev" {
  bucket        = "plaza-static-dev"
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "static-uploads-dev" {
  bucket = aws_s3_bucket.static-uploads-dev.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "static-uploads-dev" {
  bucket = aws_s3_bucket.static-uploads-dev.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "static-uploads-dev" {
  depends_on = [
    aws_s3_bucket_ownership_controls.static-uploads-dev,
    aws_s3_bucket_public_access_block.static-uploads-dev,
  ]

  bucket = aws_s3_bucket.static-uploads-dev.id
  acl    = "public-read"
}

resource "aws_s3_bucket_policy" "static-uploads-dev" {
  bucket = aws_s3_bucket.static-uploads-dev.id
  policy = data.aws_iam_policy_document.static-uploads-dev.json
}

data "aws_iam_policy_document" "static-uploads-dev" {
  statement {
    sid    = "AddPerm"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "s3:GetObject"
    ]

    resources = [
      aws_s3_bucket.static-uploads-dev.arn,
      "${aws_s3_bucket.static-uploads-dev.arn}/*",
    ]
  }
}
