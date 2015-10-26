##########################################
## Rancher server instance profile/role ##
##########################################

# Rancher server instance profile
resource "aws_iam_instance_profile" "rancher_server_instance_profile" {

    name = "${var.server_name}-instance-profile"
    roles = [
        "${aws_iam_role.rancher_server_role.name}"
    ]

    lifecycle {
        create_before_destroy = true
    }

}

# Rancher server role
resource "aws_iam_role" "rancher_server_role" {

    name = "${var.server_name}-role"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

    lifecycle {
        create_before_destroy = true
    }

}

#####################
## Custom policies ##
#####################

# S3 credentials bucket access
# Allows the server to read/write api keys to the S3 bucket.
resource "aws_iam_policy" "s3_server_credentials" {

    name = "S3-credentials-access"
    path = "/"
    description = "Allow the Rancher server to access the credentials file in the S3 bucket."
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": [
        "arn:aws:s3:::${aws_s3_bucket.server_credentials_bucket.id}/keys.txt"
      ]
    }
  ]
}
EOF

}

# SQS queue create & delete messages
# Allows the autoscaling hook app to receive and process messages
# published to the SQS queue.
resource "aws_iam_policy" "sqs_queue_access" {

    name = "SQS-queue-access"
    path = "/"
    description = "Allow the lifecycle hook app to receive and process SQS queue messages."
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "sqs:DeleteMessage",
        "sqs:ReceiveMessage"
      ],
      "Resource": [
        "${aws_sqs_queue.autoscaling_hooks_queue.arn}"
      ]
    }
  ]
}
EOF

}

# Autoscaling lifecycle complete action
resource "aws_iam_policy" "autoscaling_complete_lifecycle_action" {

    name = "Allow-autoscaling-complete-action"
    path = "/"
    description = "Allow the lifecycle hook app send a complete action request that releases the instance for termination."
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:CompleteLifecycleAction"
      ],
      "Resource": "*"
    }
  ]
}
EOF

}

#############################
## Attach policies to role ##
#############################

# S3 bucket access
resource "aws_iam_policy_attachment" "rancher_server_s3_policy" {

    name = "rancher_server_s3_policy"
    policy_arn = "${aws_iam_policy.s3_server_credentials.arn}"
    roles = [
        "${aws_iam_role.rancher_server_role.name}"
    ]
    
}

# SQS access
resource "aws_iam_policy_attachment" "rancher_server_sqs_policy" {

    name = "rancher_server_sqs_policy"
    policy_arn = "${aws_iam_policy.sqs_queue_access.arn}"
    roles = [
        "${aws_iam_role.rancher_server_role.name}"
    ]
    
}

# Complete autoscaling hook
resource "aws_iam_policy_attachment" "complete_autoscaling_hooks" {

    name = "complete_autoscaling_hooks"
    policy_arn = "${aws_iam_policy.autoscaling_complete_lifecycle_action.arn}"
    roles = [
        "${aws_iam_role.rancher_server_role.name}"
    ]
    
}
