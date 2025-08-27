#!/bin/bash
# dns-manager.sh
# Manage DNS records in Route53 for environments

while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    --environment)
      ENVIRONMENT="$2"
      shift
      shift
      ;;
    --subdomain)
      SUBDOMAIN="$2"
      shift
      shift
      ;;
    --domain)
      DOMAIN="$2"
      shift
      shift
      ;;
    --service-type)
      SERVICE_TYPE="$2"
      shift
      shift
      ;;
    --branch-name)
      BRANCH_NAME="$2"
      shift
      shift
      ;;
    *)
      shift
      ;;
  esac
done

# Configure AWS credentials
aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
aws configure set region $AWS_REGION

# Create DNS record in Route53
HOSTED_ZONE_ID=$(aws route53 list-hosted-zones-by-name --dns-name $DOMAIN --query 'HostedZones[0].Id' --output text | cut -d'/' -f3)

cat > change-batch.json <<EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "$SUBDOMAIN.$DOMAIN",
      "Type": "CNAME",
      "TTL": 300,
      "ResourceRecords": [{
        "Value": "$SERVICE_TYPE.$DOMAIN"
      }]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID --change-batch file://change-batch.json