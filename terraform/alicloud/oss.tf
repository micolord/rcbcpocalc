resource "alicloud_oss_bucket" "bucket" {
  bucket = "${var.env_name}-${var.project}-app-bucket"
}

resource "alicloud_oss_bucket_acl" "bucket-acl" {
  bucket = alicloud_oss_bucket.bucket.bucket
  acl    = "public-read-write"
}