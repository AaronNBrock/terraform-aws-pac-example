data "aws_s3_bucket" "s3_bucket" {
  count = ((var.enabled && var.enable_sqs) ? 1 : 0) * length(var.bucket_names)
  bucket = var.bucket_names[count.index]
}

resource "aws_sqs_queue" "sqs_queue_deadletter" {
  count = (var.enabled && var.enable_sqs) ? 1 : 0
  name = "access-log-bucket-deadletter"
  delay_seconds = 300
  max_message_size = 262144
  message_retention_seconds = 345600
  receive_wait_time_seconds = 10
}

resource "aws_sqs_queue" "sqs_queue" {
  count = (var.enabled && var.enable_sqs) ? 1 : 0
  name = "access-log-bucket"
  delay_seconds = 300
  max_message_size = 262144
  message_retention_seconds = 345600
  receive_wait_time_seconds = 10
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "sqs:*",
      "Resource": "arn:aws:sqs:*:*:access-log-bucket}",
      "Condition": {
        "ArnEquals": { "aws:SourceArn": "arn:aws:s3:::*" }
      }
    }
  ]
}
POLICY
  redrive_policy = <<REDRIVE
{
  "deadLetterTargetArn": "${aws_sqs_queue.sqs_queue_deadletter[0].arn}",
  "maxReceiveCount": 1000
}
REDRIVE
}

resource "aws_s3_bucket_notification" "s3_bucket_notification" {
  count = ( (var.enabled && var.enable_sqs) ? 1 : 0 ) * length(var.bucket_names)
  bucket = data.aws_s3_bucket.s3_bucket[count.index].id
  queue {
    queue_arn = aws_sqs_queue.sqs_queue[count.index].arn
    events = ["s3:ObjectCreated:*"]
    filter_suffix = ".log.gz"
  }
}
