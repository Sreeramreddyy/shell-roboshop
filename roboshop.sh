#!/bin/bash

AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-0e1a56e9f94518831"
ZONE_ID="Z03300762EZT0I4J1GS9U"
DOMAIN_NAME="jashvika.online"

for instance in $@
do
    INSTANCE_ID=$(aws ec2 run-instances --image-id ami-09c813fb71547fc4f --instance-type t3.micro --security-group-ids sg-0e1a56e9f94518831 --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" --query 'Instances[0].InstanceId' --output text)
#Get private IP
if [ $instance != "frontend" ]; then
    IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)
    RECORD_NAME="$instance.$DOMAIN_NAME" # mongodb.jashvika.online

else
    IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
    RECORD_NAME="$DOMAIN_NAME" # jashvika.online
fi    
    echo "$instance: $IP"

      aws route53 change-resource-record-sets \
        --hosted-zone-id $ZONE_ID \
        --change-batch '
{
    "Comment": "Updating record set"
    ,"Changes": [{
      "Action"              : "UPSERT"
      ,"ResourceRecordSet"  : {
        "Name"              : "'$RECORD_NAME'"
        ,"Type"             : "A"
        ,"TTL"              : 1
        ,"ResourceRecords"  : [{
            "Value"         : "'" $IP "'"
        }]
      }
    }]
  }
  '
done