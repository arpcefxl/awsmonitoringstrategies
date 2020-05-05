#!/bin/bash

REGION=$1
SNSTOPIC=$2

#Create the event rule first.  These can exist with no targets
aws events put-rule --name "EC2RetirementNotification" \
--event-pattern "{\"source\":[\"aws.health\"],\"detail-type\":[\"AWS Health Event\"],\"detail\":{\"service"\":[\"EC2\"],\"eventTypeCategory"\":[\"scheduledChange\"],\"eventTypeCode"\":[\"AWS_EC2_INSTANCE_RETIREMENT_SCHEDULED\"]}"}" \
--region $REGION

#Remove target.json from previous script run
rm target.json
#Replace the template values with correct values
sed "s/TOPICARN/$SNSTOPIC/g" template.json > target.json

#Create the event target using the updated json template
aws events put-targets --rule EC2RetirementNotification \
--targets file://target.json --region $REGION

