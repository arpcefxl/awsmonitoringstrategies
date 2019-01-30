#!/bin/bash

REGION=$1
SNSTOPIC=$2

aws events put-rule --name "EC2RetirementNotification" --event-pattern "{\"source\":[\"aws.health\"],\"detail-type\":[\"AWS Health Event\"],\"detail\":{\"service"\":[\"EC2\"],\"eventTypeCategory"\":[\"scheduledChange\"],\"eventTypeCode"\":[\"AWS_EC2_INSTANCE_RETIREMENT_SCHEDULED\"]}"}" --region $REGION

rm target.json
sed "s/TOPICARN/$SNSTOPIC/g" template.json > target.json

aws events put-targets --rule EC2RetirementNotification --targets file://target.json --region $REGION

