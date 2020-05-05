#!/bin/bash

REGION=$1
DBID=$2
MINSIZE=10000000000

#UNCOMMENT IF YOU ARE RUNNING ON PROPER LINUX
#linux date
tenminago=`date -u +%FT%TZ -d "10 minutes ago"`
now=`date -u +%FT%TZ`

#UNCOMMENT IF YOU ARE RUNNING ON MACOS
#macos date
#tenminago=`date -v -10M -u +%FT%TZ`
#now=`date -u +%FT%TZ`

freesize=`aws --region $REGION cloudwatch get-metric-statistics \
  --metric-name FreeStorageSpace --start-time $tenminago \
  --end-time $now --period 3600 --namespace AWS/RDS \
  --statistics Average \
  --dimensions Name=DBInstanceIdentifier,Value=$DBID \
  --query Datapoints[].Average \
  --output text`

#Convert the output of the free size to an integer for easy comparison
freesizeint=`echo ${freesize%.*}`

#Print out the amount of free space
echo "free size is $freesizeint"

if [ "$freesizeint" -lt "$MINSIZE" ]; then
  echo "DB volume will be extended due to limited space"

  #Figure out existing storage for DB instance
  currentstorage=`aws rds describe-db-instances \
  --db-instance-identifier $DBID --region $REGION \
  --query DBInstances[].AllocatedStorage --output text`

  #Print out the current provisioned storage
  echo "The current storage size is $currentstorage"

  #Add 10Gb to the existing storage
  NEWSTORAGE=$(($currentstorage + 10))
  echo "Increasing storage size to $NEWSTORAGE"
  aws rds modify-db-instance --db-instance-identifier $DBID \
  --allocated-storage $NEWSTORAGE --apply-immediately --region $REGION
else
  echo "DB size is fine"
fi
