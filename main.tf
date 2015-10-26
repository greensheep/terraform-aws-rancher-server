###############
## Variables ##
###############

# Target VPC config
variable "vpc_id" {
    description = "ID of target VPC."
}
variable "vpc_region" {
    description = "Region of the target VPC"
}
variable "vpc_private_subnets" {
    description = "Comma separated list of private subnet ip address ranges."
}
variable "vpc_private_subnet_ids" {
    description = "Comma separated list of private subnet ids."
}

# Server config
variable "server_name" {
    description = "Name of the Rancher server. Best not to include non-alphanumeric characters."
}
variable "server_hostname" {
    description = "Hostname of the Rancher server."
}
variable "server_key" {
    description = "Public key file for the Rancher server instance."
}
variable "server_subnet_id" {
    description = "Public subnet id in which to place the rancher server instance."
}
variable "server_version" {
    description = "Rancher server version ton install."
}
variable "server_instance_type" {
    description = "EC2 instance type to use for the rancher server."
    default = "t2.micro"
}
variable "server_ami" {
    description = "Amazon Linux AMI id for the target region."
    default = {
        eu-west-1      = "ami-69b9941e"
        eu-central-1   = "ami-daaeaec7"
        us-west-1      = "ami-cd3aff89"
        us-west-2      = "ami-9ff7e8af"
        us-east-1      = "ami-e3106686"
        ap-northeast-1 = "ami-9a2fb89a"
        ap-southeast-1 = "ami-52978200"
        ap-southeast-2 = "ami-c11856fb"
        sa-east-1      = "ami-3b0c9926"
    }
}

# SSL
variable "ssl_certificate_body" {
	description = "Server SSL certificate body file path."
}
variable "ssl_private_key" {
	description = "Server SSL private key file path."
}

# Database
variable "database_address" {
    description = "Database server address."
}
variable "database_port" {
    description = "Database port."
    default = "3306"
}
variable "database_name" {
    description = "Database name."
    default = "rancherserverdb"
}
variable "database_username" {
    description = "Database username."
    default = "root"
}
variable "database_password" {
    description = "Database password."
}

##################
## Misc outputs ##
##################

output "server_hostname" {
	value = "${var.server_hostname}"
}
