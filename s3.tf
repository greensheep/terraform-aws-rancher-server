# S3 bucket to hold rancher server api credentials
resource "aws_s3_bucket" "server_credentials_bucket" {

    bucket = "${var.server_name}-credentials"
    acl = "private"
    force_destroy = true

    tags {
        Name = "${var.server_name}"
    }

    lifecycle {
        create_before_destroy = true
    }

}
