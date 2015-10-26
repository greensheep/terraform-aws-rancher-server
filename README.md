# Rancher Server Terraform module

This is a terraform module to create a Rancher server on AWS.  It is designed to work with host instances placed in autoscaling groups (see my hosts module) and handles (via a sidekick app) automatically deregistering hosts from the server on scale down.

The server is placed behind an Nginx proxy which is responsible for SSL termination.

### Features

- SSL required
- Stateless server container through the use of an external database
- Includes a sidekick app for automatically removing hosts due to be terminated by an autoscaling group (via autoscaling lifecycle hooks)
- Mostly configurable with variables (happy to accept PRs for new vars)

### Example usage

Include the following anywhere in your Terraform config:

    module "rancher_server" {

        # Import the module from Github
        source = "github.com/greensheep/terraform-aws-rancher-server"

        # Set the details of the target VPC
        # Tip: this uses my VPC module: github.com/greensheep/terraform-aws-vpc
        vpc_id                 = "${module.vpc.vpc_id}"
        vpc_region             = "${module.vpc.vpc_region}"
        vpc_private_subnets    = "${module.vpc.vpc_private_subnets}"
        vpc_private_subnet_ids = "${module.vpc.vpc_private_subnet_ids}"

        # Server config
        server_name      = "rancher-server"
        server_hostname  = "rancher-server.yourdomain.tld"
        server_key       = "path/to/key.pub"
        server_subnet_id = "${element(split(",", module.vpc.vpc_public_subnet_ids), 0)}"
        server_version   = "v0.42.0"

        # SSL
        ssl_certificate_body  = "path/to/ssl-cert-including-chain"
        ssl_private_key       = "path/to/private-key"

        # Database
        database_address  = "dbhost"
        database_username = "dbuser"
        database_password = "dbpass"

    }

### Notes

- The rancher server takes a minute or so to start up and longer on initial bootstrap.
- On initial bootstrap, the server will be unprotected.. the first thing you should do is configure access control!
- The hostname should be routable to the server before creating hosts - the best way to do this is with Route53 and a terraform config (see example below).
- It should be possible to use a self-signed SSL certificate, but I've not tested this.
- The rancher database should already be created (Rancher will bootstrap the tables but wont create the DB, see example below).

#### Example DNS config

    resource "aws_route53_record" "server_hostname" {

        zone_id = "YOUR-HOSTED-ZONE-ID"
        name = "rancher-server.yourdomain.tld"
        type = "A"
        ttl = "30"
        records = [
            "${module.rancher_server.server_public_ip}"
        ]

        lifecycle {
            create_before_destroy = true
        }

    }

#### Example RDS database config

    # Subnet groups
    resource "aws_db_subnet_group" "default" {
        
        name = "main"
        description = "Database VPC private subnets"
        subnet_ids = [
            "${split(",",module.vpc.vpc_private_subnet_ids)}"
        ]

        lifecycle {
            create_before_destroy = true
        }

    }

    # Security group
    resource "aws_security_group" "db" {
        
        name = "Rancher-Database-SG"
        description = "Allow rancher server to access database server."
        vpc_id = "${module.vpc.vpc_id}"

        # Allow traffic from the rancher server security group
        ingress {
            from_port = 3306
            to_port = 3306
            protocol = "tcp"
            security_groups = [
                "${module.rancher_server.server_security_group_id}"
            ]
        }

        lifecycle {
            create_before_destroy = true
        }

    }

    # Database instance
    resource "aws_db_instance" "default" {

        allocated_storage = 10
        engine = "mysql"
        engine_version = "5.6.23"
        identifier = "rancher-database"
        instance_class = "db.t2.micro"
        final_snapshot_identifier = "rancher-database-final"
        publicly_accessible = false
        db_subnet_group_name = "${aws_db_subnet_group.default.name}"
        vpc_security_group_ids = [
            "${aws_security_group.db.id}"
        ]

        # Database details
        name = "rancherserverdb"
        username = "root"
        password = "password01"

        lifecycle {
            create_before_destroy = true
        }

    }
