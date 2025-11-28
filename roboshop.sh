#!/bin/bash

AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-0e1a56e9f94518831"

for instance in $@
do
    INSTANCE_ID=$(aws ec2 run-instances --image-id ami-09c813fb71547fc4f --instance-type t3.micro --security-group-ids sg-0e1a56e9f94518831 --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" --query 'Instances[0].InstanceId' --output text)
#Get private IP
if [ $instance != "frontend" ]; then
    IP=(aws ec2 describe-instances --instance-ids i-07e742a6b3d5cf169 --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)
else
    IP=(aws ec2 describe-instances --instance-ids i-07e742a6b3d5cf169 --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
fi    
    echo "$instance: $IP"
done