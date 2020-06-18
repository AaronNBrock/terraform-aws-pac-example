#!/bin/bash

# steps:
#    set up cleanup routine
#    accept and validate all CLI arguments
#    list all SQS queue for cloudfront/elb log transport
#    create splunk AWS add-on input config file
#    create ansible playbook
#    run ansible to copy the add-on input config file onto the target splunk servers and reload splunk config

set -e
set -o pipefail
#    set up cleanup routine
cleanup() {
  exit_code=$?
  rm -rf /tmp/playbook.yml
  exit $exit_code
}

trap cleanup INT TERM HUP KILL QUIT EXIT

#    accept and validate all CLI arguments
show_usage () {
  cat <<EOF
Missing at least one argument.

Syntax:
  ./runme.sh -r <aws regions, ',' delimited> \\
     -p <queue name prefix> \\
     -a <aws account, as configured in Splunk AWS add-on> \\
     -i <interval in seconds> \\
     -b <sqs queue batch size> \\
     -h <splunk servers, ',' delimited> \\
     -u <splunk_username, to reload splunk config with> \\
     -w <splunk_password>

Example:
  $0 -r us-east-1,us-west-1 -p access-log -a splunk -i 300 -b 10 -h localhost -u sp_admin -w sp_pass1234
EOF
  exit 1
}

while getopts "r:p:a:x:i:b:h:u:w:" OPTION; do
    case $OPTION in
    r)
        aws_regions=$OPTARG
        ;;
    p)
        queue_name_prefix=$OPTARG
        ;;
    a)
        export aws_account=$OPTARG
        ;;
    i)
        export interval=$OPTARG
        ;;
    b)
        export batch_size=$OPTARG
        ;;
    h)
        splunk_hosts=$OPTARG
        ;;
    u)
        export splunk_username=$OPTARG
        ;;
    w)
        export splunk_password=$OPTARG
        ;;
    *)
        echo "Incorrect options provided"
        show_usage
        ;;
    esac
done

if [[ -z $aws_regions ]] || [[ -z $queue_name_prefix ]] || [[ -z $aws_account ]] \
   || [[ -z $interval ]] || [[ -z $batch_size ]] \
   || [[ -z $splunk_hosts ]] || [[ -z $splunk_username ]] \
   || [[ -z $splunk_username ]]; then
  show_usage
fi

rm -rf /tmp/input.config
rm -rf /tmp/playbook.yml

# reformat variable to use \n for item delimiter
aws_regions=$(echo "$aws_regions" | tr ',' '\n' | sort)
splunk_hosts=$(echo "$splunk_hosts" | tr ',' '\n')

while IFS= read -r aws_region
do
  #    list all SQS queue for cloudfront/elb log transport
  queues=$(aws sqs list-queues --region $aws_region --queue-name-prefix $queue_name_prefix | jq ".QueueUrls[]" -r | grep -v "deadletter" | sort)
  #    create splunk AWS add-on input config file
  while IFS= read -r queue_url
  do
    export aws_region
    export queue_url
    export input_name=$(echo "$queue_url" | awk -F/ '{print $4"-"$5}' | sed "s/[^[:alnum:]_-]//g")
    export index=$(echo "$input_name" | awk -F- '{print $NF}')
    log_source_type=$(echo "$input_name" | awk -F- '{print $(NF-1)}')
    if [[ "$log_source_type" == "cloudfront" ]]; then
      export decoder=CloudFrontAccessLogs
      export sourcetype=aws:cloudfront:accesslogs
    elif [[ "$log_source_type" == "lb" ]]; then
      export decoder=ELBAccessLogs
      export sourcetype=aws:elb:accesslogs
    else
      echo "unhandled log sourcetype for queue: $queue_url"
      exit 1
    fi
    envsubst < input_template >>/tmp/input.config
  done <<< "$queues"
done <<< "$aws_regions"

#    create ansible playbook
envsubst < playbook_template >/tmp/playbook.yml

#    run ansible to copy the add-on input config file onto the target splunk server(s) and reload splunk config
while IFS= read -r line
do
  if [[ $line -eq "localhost" ]]; then
    ansible-playbook --connection=local --inventory $line, /tmp/playbook.yml
  else
    ansible-playbook --inventory $line, /tmp/playbook.yml
  fi
done <<< "$splunk_hosts"
