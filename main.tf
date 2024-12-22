terraform {
    required_providers {
      aws = {
        source = "hashicorp/aws"
        version = "~> 3.27"
      }
    }
}

provider "aws" {
  profile = "subbu-coding-videos"
  region = "us-east-1"
}

resource "aws_s3_bucket" "testing_bucket_Subbu" {
    bucket = "subbu-bucket-testtera"
}


# cloudfront origin access identity
resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "subbu origin access identity"
}

# setting up s3 bucket permission using IAM Policy Document
data "aws_iam_policy_document" "read_subbu_bucket" {
  statement {
    actions = [ "s3:GetObject" ]
    resources = [ "${aws_s3_bucket.testing_bucket_Subbu.arn}/*"]
    principals {
      type = "AWS"
      identifiers = [ aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn ]
    }
  }
  
}

resource "aws_s3_bucket_policy" "allow_subbu_bucket" {
  bucket = aws_s3_bucket.testing_bucket_Subbu.id
  policy = data.aws_iam_policy_document.read_subbu_bucket.json
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.testing_bucket_Subbu.bucket_domain_name
    origin_id   = aws_s3_bucket.testing_bucket_Subbu.bucket
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }
  
  enabled = true

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  default_cache_behavior {
    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.testing_bucket_Subbu.bucket
    viewer_protocol_policy = "redirect-to-https"
    min_ttl = 0
    default_ttl = 300
    max_ttl = 3600

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

  }
  viewer_certificate {
    cloudfront_default_certificate = true
  }
  price_class = "PriceClass_200"

  tags = {
    resource= "cloudfrontOnS3"
    env= "dev"
    creator= "subbu using terraform"
  }
}

output "cloudfront_url" {
  value = "https://${aws_cloudfront_distribution.s3_distribution.domain_name}"
}

