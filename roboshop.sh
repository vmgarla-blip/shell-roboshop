#!/bin/bash

AMI_ID=ami-0220d79f3f480ecf5
ZONE_ID=Z09078742W8AN20R1OHKZ
DOMAIN_NAME="devops90s.online"
SUBNET_ID=subnet-044d6d915383f4f9b

for instance in "$@"
do
  echo "Launching instance for $instance"

  SG_ID=$(aws ec2 describe-security-groups \
    --filters "Name=group-name,Values=roboshop-${instance}" \
    --query 'SecurityGroups[0].GroupId' \
    --output text)

  COMMON_SG=$(aws ec2 describe-security-groups \
    --filters "Name=group-name,Values=roboshop-common" \
    --query 'SecurityGroups[0].GroupId' \
    --output text)

  INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type t3.micro \
    --security-group-ids $COMMON_SG $SG_ID \
    --subnet-id $SUBNET_ID \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=roboshop-${instance}}]" \
    --query 'Instances[0].InstanceId' \
    --output text)

  echo "Instance ID for $instance is $INSTANCE_ID"

  # Wait until instance is running
  aws ec2 wait instance-running --instance-ids $INSTANCE_ID

  if [ "$instance" = "frontend" ]; then
    IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID \
      --query 'Reservations[*].Instances[*].PublicIpAddress' \
      --output text)
    R53_RECORD="$DOMAIN_NAME"
  else
    IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID \
      --query 'Reservations[*].Instances[*].PrivateIpAddress' \
      --output text)
    R53_RECORD="$instance.$DOMAIN_NAME"
  fi

  echo "Updating DNS: $R53_RECORD → $IP"

  aws route53 change-resource-record-sets \
    --hosted-zone-id $ZONE_ID \
    --change-batch "{
      \"Comment\": \"Creating record\",
      \"Changes\": [{
        \"Action\": \"UPSERT\",
        \"ResourceRecordSet\": {
          \"Name\": \"$R53_RECORD\",
          \"Type\": \"A\",
          \"TTL\": 300,
          \"ResourceRecords\": [{
            \"Value\": \"$IP\"
          }]
        }
      }]
    }"

done