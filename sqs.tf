# Autoscaling hooks queue
resource "aws_sqs_queue" "autoscaling_hooks_queue" {

    name = "${var.server_name}-asg-hooks"

    # Allow upto 5 minutes for the message to be processed
    # before it can be retrieved by another consumer.
    visibility_timeout_seconds = 300

    # Keep the message in the queue for a max of 30 minutes.
    # This is the same as the wait period for lifecycle hooks.
    message_retention_seconds = 1800
    
    tags {
        Name = "${var.server_name}-asg-hooks"
        ManagedBy = "terraform"
    }

    lifecycle {
        create_before_destroy = true
    }

}

output "lifecycle_hooks_sqs_queue_arn" {
    value = "${aws_sqs_queue.autoscaling_hooks_queue.arn}"
}
