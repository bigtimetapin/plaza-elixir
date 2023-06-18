####################################################################################
## landing page ####################################################################
####################################################################################
resource "aws_s3_bucket" "domain" {
  bucket        = var.domain_name
  force_destroy = true
}

resource "aws_s3_bucket_website_configuration" "domain" {
  bucket = aws_s3_bucket.domain.id
  index_document {
    suffix = "index.html"
  }
}


resource "aws_s3_bucket_public_access_block" "domain" {
  bucket                  = aws_s3_bucket.domain.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

##resource "aws_s3_bucket_acl" "domain" {
##  depends_on = [aws_s3_bucket_public_access_block.domain]
##  bucket     = aws_s3_bucket.domain.id
##  acl        = "public-read"
##}

resource "aws_s3_bucket_policy" "domain" {
  #depends_on = [aws_s3_bucket_acl.domain]
  depends_on = [aws_s3_bucket_public_access_block.domain]
  bucket     = aws_s3_bucket.domain.id
  policy     = data.aws_iam_policy_document.domain.json
}

data "aws_iam_policy_document" "domain" {
  statement {
    sid    = "PublicReadGetObject"
    effect = "Allow"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = [
      "s3:GetObject"
    ]
    resources = [
      "arn:aws:s3:::${var.domain_name}/*"
    ]
  }
}

######################################################################################
#### www redirect to landing page ####################################################
######################################################################################
##resource "aws_s3_bucket" "www" {
##  bucket        = "www.${var.domain_name}"
##  force_destroy = true
##}
##
##resource "aws_s3_bucket_website_configuration" "www" {
##  bucket = aws_s3_bucket.www.id
##  redirect_all_requests_to {
##    host_name = var.domain_name
##  }
##}
##
######################################################################################
#### static uploads ##################################################################
######################################################################################
##resource "aws_s3_bucket" "static-uploads-dev" {
##  bucket        = "plaza-static-dev"
##  force_destroy = true
##}
##
##resource "aws_s3_bucket_ownership_controls" "static-uploads-dev" {
##  bucket = aws_s3_bucket.static-uploads-dev.id
##  rule {
##    object_ownership = "BucketOwnerPreferred"
##  }
##}
##
##resource "aws_s3_bucket_public_access_block" "static-uploads-dev" {
##  bucket = aws_s3_bucket.static-uploads-dev.id
##
##  block_public_acls       = false
##  block_public_policy     = false
##  ignore_public_acls      = false
##  restrict_public_buckets = false
##}
##
##resource "aws_s3_bucket_acl" "static-uploads-dev" {
##  depends_on = [
##    aws_s3_bucket_ownership_controls.static-uploads-dev,
##    aws_s3_bucket_public_access_block.static-uploads-dev,
##  ]
##
##  bucket = aws_s3_bucket.static-uploads-dev.id
##  acl    = "public-read"
##}
##
##resource "aws_s3_bucket_policy" "static-uploads-dev" {
##  depends_on = [aws_s3_bucket_acl.static-uploads-dev]
##  bucket     = aws_s3_bucket.static-uploads-dev.id
##  policy     = data.aws_iam_policy_document.static-uploads-dev.json
##}
##
##data "aws_iam_policy_document" "static-uploads-dev" {
##  statement {
##    sid    = "AddPerm"
##    effect = "Allow"
##    principals {
##      type        = "AWS"
##      identifiers = ["*"]
##    }
##    actions = [
##      "s3:GetObject"
##    ]
##
##    resources = [
##      aws_s3_bucket.static-uploads-dev.arn,
##      "${aws_s3_bucket.static-uploads-dev.arn}/*",
##    ]
##  }
##}
