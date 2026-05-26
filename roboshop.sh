#!/bin/bash
AMI_ID=ami-0220d79f3f480ecf5
ZONE_ID=Z09078742W8AN20R1OHKZ
DOMAIN_NAME="devops90s.online"

for instance in $@
do
  echo "launching instance for $instance"
  INSTANCE_ID=$(aws ec2 run-instances \
  --image-id ami-0220d79f3f480ecf5 \
  --instance-type t3.micro \
  --security-groups "roboshop-common" "roboshop-${instance}" \
  --subnet-id subnet-044d6d915383f4f9b \
      --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=roboshop-${instance}}]" \
      --query 'Instances[0].InstanceId' \
  --output text
  )
  echo "Instance ID for $instance is $INSTANCE_ID"

  sleep 20

  if [ $instance = "frontend" ]; then
    IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID \
  --query 'Reservations[*].Instances[*].PublicIpAddress' \
  --output text
  )
  R53_RECORD="$DOMAIN_NAME"
  else
    IP =$(aws ec2 describe-instances --instance-ids $INSTANCE_ID \
  --query 'Reservations[*].Instances[*].PrivateIpAddress' \
  --output text
  )
   R53_RECORD="$instance.$DOMAIN_NAME"
  fi
  
  aws route53 change-resource-record-sets \
  --hosted-zone-id $ZONE_ID \
  --change-batch '{
    "Comment": "Creating record",
    "Changes": [{
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "'$R53_RECORD'",
        "Type": "A",
        "TTL": 1,
        "ResourceRecords": [{
          "Value": "'$IP'"
        }]
      }
    }]
  }'

done
