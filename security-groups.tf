# Rancher server security group
resource "aws_security_group" "rancher_server_sg" {

    name = "${var.server_name}-Rancher-Server"
    description = "Rules for the Rancher server instance."
    vpc_id = "${var.vpc_id}"

    # Incoming HTTP from internet
    # Nginx will redirect all http traffic to https
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # Incoming HTTPS from internet
    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # Outgoing HTTP to internet
    egress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # Outgoing HTTPS to internet
    egress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # Outgoing SSH to VPC private subnets
    egress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [
            "${split(",",var.vpc_private_subnets)}"
        ]
    }

    # Outgoing docker API to VPC private subnets
    egress {
        from_port = 2376
        to_port = 2376
        protocol = "tcp"
        cidr_blocks = [
            "${split(",",var.vpc_private_subnets)}"
        ]
    }

    # Outgoing mysql
    egress {
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags {
        Name = "${var.server_name}"
    }

    lifecycle {
        create_before_destroy = true
    }

}

output "server_security_group_id" {
    value = "${aws_security_group.rancher_server_sg.id}"
}
