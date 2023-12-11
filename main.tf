#Create s3 bucket
resource "aws_s3_bucket" "s3_ppt" {
  bucket = "www.hamrotech.com.np"
}

#Making the bucket owner the owner of the every file uploaded in the bucket
resource "aws_s3_bucket_ownership_controls" "s3_ppt_own" {
  bucket = aws_s3_bucket.s3_ppt.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

#to allow public access
resource "aws_s3_bucket_public_access_block" "s3_ppt_pab" {
  bucket = aws_s3_bucket.s3_ppt.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_object" "index_html" {
  bucket = aws_s3_bucket.s3_ppt.bucket
  key    = "index.html"
  acl    = "public-read"
  content_type = "text/html"
  source = "/home/binay/Hamropatro/s3/static_site_hosting_form_s3_using_terraform/index.html"
}

#allowing everyone to acces the file through the internet
resource "aws_s3_bucket_acl" "s3_ppt_acl" {
  depends_on = [ aws_s3_bucket_ownership_controls.s3_ppt_own,aws_s3_bucket_public_access_block.s3_ppt_pab ]
  bucket = aws_s3_bucket.s3_ppt.id

  acl    = "public-read"
}


#Enabling static website feature
resource "aws_s3_bucket_website_configuration" "s3_ppt_conf" {
  bucket = aws_s3_bucket.s3_ppt.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

#This is the policy to grant public read access to the files inside bucket
data "aws_iam_policy_document" "website_policy" {
  statement {
    sid    = "PublicReadGetObject"
    effect = "Allow"
    principals {
      identifiers =  [ "*" ]
      type = "AWS"
    }
    actions = [
      "s3:GetObject"
    ]
    resources = [
      "arn:aws:s3:::www.hamrotech.com.np/*",
    ]
  }
}



##################################################################################
##########################  CLoud Front  ########################################
##################################################################################


resource "aws_cloudfront_distribution" "static_website" {
 origin {
  domain_name = "www.hamrotech.com.np.s3-website.us-east-2.amazonaws.com"
  origin_id = "S3Origin"

  custom_origin_config {
    http_port            = 80
    https_port           = 443
    origin_protocol_policy = "http-only"
    origin_ssl_protocols = ["TLSv1", "TLSv1.1", "TLSv1.2"]
  }
 }

 enabled           = true
 is_ipv6_enabled   = true
 default_root_object = "index.html"

 default_cache_behavior {
  allowed_methods = ["GET", "HEAD"]
  cached_methods = ["GET", "HEAD"]
  target_origin_id = "S3Origin"

  forwarded_values {
    query_string = false

    cookies {
      forward = "none"
    }
  }

  viewer_protocol_policy = "allow-all"
  min_ttl              = 0
  default_ttl          = 3600
  max_ttl              = 86400
 }

 viewer_certificate {
  cloudfront_default_certificate = true
 }

 restrictions {
  geo_restriction {
    restriction_type = "none"
  }
 }

 tags = {
  Environment = "production"
 }
}
