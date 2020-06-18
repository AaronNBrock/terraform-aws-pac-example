# Configure SQS-based S3 inputs for Splunk Add-on for AWS, to notify Splunk of ELB and CloudFront log file creation. using SQS queues

## Background
* AWS ELB and CloudFront both can log to S3 buckets.
* An S3 bucket can be configured to post ObjectCreated events to an SQS queue.
* Splunk provides an Add-on for AWS. Use the add-on to notify Splunk of ELB and CloudFront log creation via SQS queues, and download the log files from S3.

## Summary
* Agree to a naming convention for SQS queues used for ELB and CloudFront log creation notification.
* Set up CloudFront and ELB to log to S3 buckets.
* Ceate SQS queues to receive ObjectCreated events from these S3 buckets.
* Configure the S3 buckets to send ObjectCreated events to the SQS queues.
* Run `./runme.sh` to
  * Get SQS queue list from AWS.
  * Generate input configuration file for Splunk Add-on for AWS, based on discovered SQS queues.
  * Using Ansible, deploy the generated configuration file to the Splunk server(s) and trigger Splunk server to reload its input configuration.

## [Diagram](AWS_SQS_Splunk.pdf)

## SQS queue naming convention
* Please follow this convention when naming related SQS queues: `<`queue-prefix`>`-xxxx-`<`log-type`>`-`<`splunk-index-name`>`.
Where `queue-prefix` is a fixed prefix for all queues for ELB and CloudFront log creation events to Splunk, `log-type` is either 'lb', or 'cloudfront', and `splunk-index-name` is the Splunk index to send the logs to.
* The queue name should not contain the word "deadletter".
* Example queue names: `access-log-mysite0034-cloudfront-main`, `access-log-mysite0056-lb-main`.

## Pre-reqs
* The Splunk server already has Splunk Add-on for AWS installed.
* The add-on for AWS has an AWS account configured, the account can access the SQS queues and download logs from the S3 buckets.
* The SQS queues have been set up according to the agreed naming convention.

## When to update configuration for SQS-based S3 inputs for Splunk Add-on for AWS, and how?
* When a new SQS queue has been set up to notify Splunk of CloudFront/ELB log creation.
* On a machine, using an account with sufficient access to:
  * to list the AWS SQS queues via AWS CLI.
  * to update and reload Splunk input configuration file on the Splunk server via Ansible.
* Install dependencies such as ansible, jq, aws-cli onto this machine.
* Run this command and follow the prompt: `./runme.sh`. Below is a test run:
```
MyComputer:ansible_code_0324 myuid$ ./runme.sh 
Missing at least one argument.

Syntax:
  ./runme.sh -r <aws regions, ',' delimited> \
     -p <queue name prefix> \
     -a <aws account, as configured in Splunk AWS add-on> \
     -i <interval in seconds> \
     -b <sqs queue batch size> \
     -h <splunk servers, ',' delimited> \
     -u <splunk_username, to reload splunk config with> \
     -w <splunk_password>

Example:
  ./runme.sh -r us-east-1,us-west-1 -p access-log -a splunk -i 300 -b 10 -h localhost -u sp_admin -w sp_pass1234
```

## TBD
* How does Ansible authenticate for splunk server access?
* What if there are other parties updating the same AWS add-on configuration file on the splunk server?
