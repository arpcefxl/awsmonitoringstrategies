#!/bin/bash
REGION=$1
SNSTOPIC=$2

#Generate a list of instance IDs for instances in RUNNING state
INSTANCES=`/usr/local/bin/aws ec2 describe-instances --region $REGION --output text --filters "Name=instance-state-code,Values=16" --query Reservations[*].Instances[*].InstanceId |tr '\t' '\n'`

#Generate a list of existing alarms to compare against
#Executing this once prevents us from running this for every instance
ALARMS=`/usr/local/bin/aws cloudwatch describe-alarms --alarm-name-prefix StatusCheckFailed-Alarm --state-value OK --output text --region $REGION  --query 'MetricAlarms[].Dimensions[].Value' | tr '\t' '\n'` 


for i in `echo $INSTANCES`; do
  INSTANCE=$i
  echo "checking on $INSTANCE"

  if [[ $ALARMS != *"$INSTANCE"* ]]; then
    #Grab the value of the Name tag
    name=`/usr/local/bin/aws ec2 describe-tags --region $REGION --filters "Name=resource-id,Values=$INSTANCE" "Name=key,Values=Name" --query Tags[*].Value`

    #Create the new alarm
    #Alarm name uses the name tag value
    #SNS topic ARN provided on script command line
    /usr/local/bin/aws cloudwatch put-metric-alarm --alarm-name StatusCheckFailed-Alarm_$name --alarm-description "Alarm when StatusCheckFailed metric has a value of one for two periods" --metric-name StatusCheckFailed --namespace AWS/EC2 --statistic Maximum --dimensions Name=InstanceId,Value=$INSTANCE --region $REGION --period 300 --unit Count --evaluation-periods 2 --threshold 1 --comparison-operator GreaterThanOrEqualToThreshold --alarm-actions $SNSTOPIC --insufficient-data-actions $SNSTOPIC
    echo "creating alarms for $INSTANCE"
  fi
done

