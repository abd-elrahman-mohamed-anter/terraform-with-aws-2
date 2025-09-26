terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# ----------------------------
# S3 Bucket (Private)
# ----------------------------
resource "aws_s3_bucket" "bucket" {
  bucket = "my-tf-s3-with-cicd"
  tags = {
    Name = "My Website Bucket"
  }
}

resource "aws_s3_bucket_ownership_controls" "bucket" {
  bucket = aws_s3_bucket.bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "bucket" {
  bucket = aws_s3_bucket.bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ----------------------------
# Upload website files
# ----------------------------
locals {
  website_files = fileset("${path.module}/website", "**/*")
}

resource "aws_s3_object" "website_files" {
  for_each = toset(local.website_files)
  bucket   = aws_s3_bucket.bucket.id
  key      = each.value
  source   = "${path.module}/website/${each.value}"
  acl      = "private"

  content_type = lookup(
    {
      "html" = "text/html"
      "css"  = "text/css"
      "js"   = "application/javascript"
      "png"  = "image/png"
      "jpg"  = "image/jpeg"
      "jpeg" = "image/jpeg"
      "gif"  = "image/gif"
      "svg"  = "image/svg+xml"
    },
    split(".", each.value)[length(split(".", each.value)) - 1],
    "application/octet-stream"
  )
}

# ----------------------------
# CloudFront Origin Access Control
# ----------------------------
resource "aws_cloudfront_origin_access_control" "default" {
  name                              = "default-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# ----------------------------
# CloudFront Distribution
# ----------------------------
resource "aws_cloudfront_distribution" "cdn" {
  origin {
    domain_name              = aws_s3_bucket.bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.default.id
    origin_id                = "myS3Origin"
  }

  enabled             = true
  default_root_object = "index.html"
  is_ipv6_enabled     = true

  default_cache_behavior {
    target_origin_id       = "myS3Origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  # Error Pages
  custom_error_response {
    error_code          = 404
    response_page_path  = "/error.html"
    response_code       = 404
    error_caching_min_ttl = 0
  }

  custom_error_response {
    error_code          = 403
    response_page_path  = "/error.html"
    response_code       = 403
    error_caching_min_ttl = 0
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

# ----------------------------
# Bucket Policy for CloudFront OAC
# ----------------------------
data "aws_iam_policy_document" "cloudfront_access" {
  statement {
    sid     = "AllowCloudFrontDistributionRead"
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.bucket.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.cdn.arn]  # Distribution ARN
    }
  }
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.bucket.id
  policy = data.aws_iam_policy_document.cloudfront_access.json
}

# ----------------------------
# Outputs
# ----------------------------
output "cloudfront_url" {
  value = aws_cloudfront_distribution.cdn.domain_name
}

output "s3_bucket_website_url" {
  value = aws_s3_bucket.bucket.website_endpoint
}
