#
# This Terraform script assumes you have an existing Route 53 zone. After providing a subdomain
# (for example: foo) and a zone name (for example: bar.com), this script will create AWS components
# needed for hosting a static website at foo.bar.com:
#
# - S3 bucket
# - CloudFront distribution
# - SSL certificate

variable "subdomain" {
  description = "Subdomain to use for website and S3 bucket"
}

variable "zone" {
  description = "Route 53 zone name"
}

# ACM certificate has to be in us-east-1, but S3 buckets are in us-west-2
provider "aws" {
  region = "us-east-1"
}

# Hosted zone in Route53
data "aws_route53_zone" "zone" {
  name = "${var.zone}."
}

# Route 53 DNS record
resource "aws_route53_record" "subdomain" {
  zone_id = "${data.aws_route53_zone.zone.zone_id}"
  name    = "${var.subdomain}.${var.zone}"
  type    = "A"

  alias {
    name                   = "${aws_cloudfront_distribution.subdomain.domain_name}"
    zone_id                = "${aws_cloudfront_distribution.subdomain.hosted_zone_id}"
    evaluate_target_health = false
  }
}

# CloudFront distribution
resource "aws_cloudfront_distribution" "subdomain" {
  default_root_object = "index.html"
  enabled             = true
  price_class         = "PriceClass_100"

  origin {
    domain_name = "${aws_s3_bucket.subdomain.website_endpoint}"
    origin_id   = "S3-${var.subdomain}.${var.zone}"

    custom_origin_config {
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = "${aws_acm_certificate.cert.arn}"
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2018"
  }

  default_cache_behavior {
    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400

    viewer_protocol_policy = "redirect-to-https"
    target_origin_id       = "S3-${var.subdomain}.${var.zone}"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  tags {
    Name = "${var.subdomain}.${var.zone}"
  }
}

# S3 bucket for hosting static website
resource "aws_s3_bucket" "subdomain" {
  bucket = "${var.subdomain}.${var.zone}"

  website {
    index_document = "index.html"
  }
}

# Sample HTML file
resource "aws_s3_bucket_object" "index_html" {
  bucket       = "${aws_s3_bucket.subdomain.id}"
  key          = "index.html"
  content      = "Hello, ${var.subdomain}.${var.zone}"
  acl          = "public-read"
  content_type = "text/html"
}

# SSL certificate
resource "aws_acm_certificate" "cert" {
  domain_name       = "${var.subdomain}.${var.zone}"
  validation_method = "DNS"

  tags {
    Name = "${var.subdomain}.${var.zone}"
  }
}

# Domain validation record
resource "aws_route53_record" "domain_validation" {
  zone_id = "${data.aws_route53_zone.zone.zone_id}"
  name    = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_name}"
  type    = "CNAME"
  ttl     = "60"
  records = ["${aws_acm_certificate.cert.domain_validation_options.0.resource_record_value}"]
}

# Wait for domain validation to complete
resource "aws_acm_certificate_validation" "cert" {
  certificate_arn = "${aws_acm_certificate.cert.arn}"

  validation_record_fqdns = [
    "${aws_route53_record.domain_validation.fqdn}",
  ]
}
