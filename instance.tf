#############################
## Rancher server instance ##
#############################

# Import the keypair
resource "aws_key_pair" "keypair" {

    key_name   = "${var.server_name}-key"
    public_key = "${file("${var.server_key}")}"

    lifecycle {
        create_before_destroy = true
    }

}

# Nginx proxy config
resource "template_file" "nginx_config" {

    template = "${file("${path.module}/files/nginx.template")}"

    vars {
        server_hostname = "${var.server_hostname}"
    }

    lifecycle {
        create_before_destroy = true
    }

}

# User-data template
resource "template_file" "user_data" {

    template = "${file("${path.module}/files/userdata.template")}"

    vars {

        # VPC config
        vpc_region = "${var.vpc_region}"

        # Server config
        server_version            = "${var.server_version}"
        server_credentials_bucket = "${aws_s3_bucket.server_credentials_bucket.id}"

        # SSL certificate
        ssl_certificate_body = "${file("${var.ssl_certificate_body}")}"
        ssl_private_key      = "${file("${var.ssl_private_key}")}"

        # Nginx config file
        nginx_config   = "${template_file.nginx_config.rendered}"

        # SQS url
        sqs_url = "${aws_sqs_queue.autoscaling_hooks_queue.id}"

        # Database
        database_address  = "${var.database_address}"
        database_port     = "${var.database_port}"
        database_name     = "${var.database_name}"
        database_username = "${var.database_username}"
        database_password = "${var.database_password}"

    }

    lifecycle {
        create_before_destroy = true
    }

}

# Create instance
resource "aws_instance" "rancher_server" {

    # Amazon linux
    ami = "${lookup(var.server_ami, var.vpc_region)}"

    # Target subnet - should be public
    subnet_id = "${var.server_subnet_id}"
    associate_public_ip_address = true

    # Security groups
    vpc_security_group_ids = [
        "${aws_security_group.rancher_server_sg.id}"
    ]

    # SSH key
    key_name = "${aws_key_pair.keypair.key_name}"

    # User-data
    # Installs docker, starts containers and performs initial server setup
    user_data = "${template_file.user_data.rendered}"

    # Instance profile - sets required permissions to access other aws resources
    iam_instance_profile = "${aws_iam_instance_profile.rancher_server_instance_profile.id}"

    # Misc
    instance_type = "${var.server_instance_type}"

    # Ensure S3 bucket is created first
    depends_on = [
        "aws_s3_bucket.server_credentials_bucket"
    ]

    tags {
        Name = "${var.server_name}"
        ManagedBy = "terraform"
    }

    lifecycle {
        create_before_destroy = true
    }

}

output "server_public_ip" {
    value = "${aws_instance.rancher_server.public_ip}"
}

output "server_hostname" {
    value = "${var.server_hostname}"
}

output "server_keyname" {
    value = "${aws_key_pair.keypair.key_name}"
}
