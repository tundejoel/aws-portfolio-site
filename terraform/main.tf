   terraform {
     required_version = ">= 1.5"
     required_providers {
       aws = {
         source  = "hashicorp/aws"
         version = "~> 5.0"
       }
     }
   }

   provider "aws" {
     region = "us-east-1"
   }

   data "aws_caller_identity" "current" {}

   output "account_id" {
     value = data.aws_caller_identity.current.account_id
   }
   resource "aws_s3_bucket" "site" {
  bucket = "adedayoafolabi.com"
}
resource "aws_s3_bucket_versioning" "site" {
  bucket = aws_s3_bucket.site.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "site" {
  bucket                  = aws_s3_bucket.site.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id
  policy = jsonencode({
    Version = "2008-10-17"
    Id      = "PolicyForCloudFrontPrivateContent"
    Statement = [{
      Sid       = "AllowCloudFrontServicePrincipal"
      Effect    = "Allow"
      Principal = { Service = "cloudfront.amazonaws.com" }
      Action    = "s3:GetObject"
      Resource  = "arn:aws:s3:::adedayoafolabi.com/*"
      Condition = {
        ArnLike = { "AWS:SourceArn" = "arn:aws:cloudfront::303927185686:distribution/E32SHNM34F2D1F" }
      }
    }]
  })
}
data "aws_route53_zone" "site" {
  name = "adedayoafolabi.com"
}

resource "aws_route53_record" "apex_a" {
  zone_id = data.aws_route53_zone.site.zone_id
  name    = "adedayoafolabi.com"
  type    = "A"
  alias {
    name                   = "d38ip0nianpbq1.cloudfront.net"
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "apex_aaaa" {
  zone_id = data.aws_route53_zone.site.zone_id
  name    = "adedayoafolabi.com"
  type    = "AAAA"
  alias {
    name                   = "d38ip0nianpbq1.cloudfront.net"
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www_a" {
  zone_id = data.aws_route53_zone.site.zone_id
  name    = "www.adedayoafolabi.com"
  type    = "A"
  alias {
    name                   = "d38ip0nianpbq1.cloudfront.net"
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www_aaaa" {
  zone_id = data.aws_route53_zone.site.zone_id
  name    = "www.adedayoafolabi.com"
  type    = "AAAA"
  alias {
    name                   = "d38ip0nianpbq1.cloudfront.net"
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
}
resource "aws_acm_certificate" "site" {
  domain_name               = "adedayoafolabi.com"
  subject_alternative_names = ["www.adedayoafolabi.com"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation_apex" {
  zone_id = data.aws_route53_zone.site.zone_id
  name    = "_dc83fca58752bd9c23995188e554510e.adedayoafolabi.com"
  type    = "CNAME"
  ttl     = 300
  records = ["_137cc5019085ffc24fa2e4ed9ad01699.jkddzztszm.acm-validations.aws."]
}

resource "aws_route53_record" "cert_validation_www" {
  zone_id = data.aws_route53_zone.site.zone_id
  name    = "_75d92160e081624b8d32d8a5d18aa762.www.adedayoafolabi.com"
  type    = "CNAME"
  ttl     = 300
  records = ["_3ae809afe0f9cdff86141eecc4a722e5.jkddzztszm.acm-validations.aws."]
}
resource "aws_cloudfront_origin_access_control" "site" {
  name                              = "oac-adedayoafolabi.com.s3.us-east-1.amazonaws.com-mt4vwdpv1qz"
  description                       = "Created by CloudFront"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}
resource "aws_cloudfront_distribution" "site" {
  enabled             = true
  is_ipv6_enabled     = true
  http_version        = "http2"
  default_root_object = "index.html"
  price_class         = "PriceClass_All"
  aliases             = ["adedayoafolabi.com", "www.adedayoafolabi.com"]
  tags = {
    Name    = "portfolio-site"
    Project = "portfolio-site"
  }

  origin {
    origin_id                = "adedayoafolabi.com.s3.us-east-1.amazonaws.com-mt4vpcitdyg"
    domain_name              = "adedayoafolabi.com.s3.us-east-1.amazonaws.com"
    origin_access_control_id = aws_cloudfront_origin_access_control.site.id
  }

  default_cache_behavior {
    target_origin_id       = "adedayoafolabi.com.s3.us-east-1.amazonaws.com-mt4vpcitdyg"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.site.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["ab9d0263244dd0326eb67015705a667e79cfe998"]
}

resource "aws_iam_role" "github_actions" {
  name                 = "github-actions-portfolio-deploy"
  max_session_duration = 3600

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
            "token.actions.githubusercontent.com:sub" = "repo:tundejoel@85370284/aws-portfolio-site@1343272802:ref:refs/heads/main"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "portfolio_deploy" {
  name = "portfolio-deploy-policy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = aws_s3_bucket.site.arn
      },
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:DeleteObject"]
        Resource = "${aws_s3_bucket.site.arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["cloudfront:CreateInvalidation"]
        Resource = aws_cloudfront_distribution.site.arn
      }
    ]
  })
}

resource "aws_route53_record" "mx" {
  zone_id = data.aws_route53_zone.site.zone_id
  name    = data.aws_route53_zone.site.name
  type    = "MX"
  ttl     = 300
  records = [
    "10 mx1.improvmx.com",
    "20 mx2.improvmx.com",
  ]
}

resource "aws_route53_record" "spf" {
  zone_id = data.aws_route53_zone.site.zone_id
  name    = data.aws_route53_zone.site.name
  type    = "TXT"
  ttl     = 300
  records = ["v=spf1 include:spf.improvmx.com ~all"]
}