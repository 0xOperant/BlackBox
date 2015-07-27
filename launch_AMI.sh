#!/bin/bash
#This script uses the AWS API to create a new instance, and apply configurations contained in the BOOTSTRAP_SCRIPT.

# create and start an instance
#AMI = Ubuntu 14.04.02 LTS 64-bit
#As of 26 Jul 2015, the 64-Bit Ubuntu 14.04.02 Linux AMI’s are:
#"Mappings": {
#        "AWSRegionToAMI": {
#            "us-east-1": { "AMI": "ami-d05e75b8" }, #N. Virginia
#            "us-west-2": { "AMI": "ami-5189a661" }, #Oregon
#            "us-west-1": { "AMI": "ami-df6a8b9b" }, #N. California
#            "eu-west-1": { "AMI": "ami-47a23a30" }, #Ireland
#	     “eu-central-1”: { “AMI”: “ami-accff2b1” }, #Frankfurt
#            "ap-southeast-1": { "AMI": "ami-96f1c1c4" }, #Singapore
#            "ap-northeast-1": { "AMI": "ami-936d9d93" }, #Tokyo
#            "ap-southeast-2": { "AMI": "ami-69631053" }, #Syndey
#            "sa-east-1": { "AMI": "ami-4d883350" }, #Sao Paulo
#        }
#    }

AMI_ID=ami-5189a661 #configure this for your region
KEY_ID=#Your_SSH_Key
SEC_ID=#Your_VPC_Security_Group
BOOTSTRAP_SCRIPT=configure_VPN.sh 

echo "Starting Instance..."
INSTANCE_DETAILS=`aws ec2 run-instances --image-id $AMI_ID --key-name $KEY_ID --security-groups $SEC_ID --instance-type t2.micro --user-data file://./$BOOTSTRAP_SCRIPT --output text | grep INSTANCES`

INSTANCE_ID=`echo $INSTANCE_DETAILS | awk '{print $7}'`

# wait for instance to be started
STATUS=`aws ec2 describe-instance-status --instance-ids $INSTANCE_ID --output text | grep INSTANCESTATUS | grep -v INSTANCESTATUSES | awk '{print $2}'`

while [ "$STATUS" != "ok" ]
do
    echo "Waiting for instance to start..."
    sleep 30
    STATUS=`aws ec2 describe-instance-status --instance-ids $INSTANCE_ID --output text | grep INSTANCESTATUS | grep -v INSTANCESTATUSES | awk '{print $2}'`
done

echo "Instance "$INSTANCE_ID" successfully started!"
DNS_NAME=`aws ec2 describe-instances --instance-ids $INSTANCE_ID --output text | grep INSTANCES | awk '{print $13}'`
AVAILABILITY_ZONE=`aws ec2 describe-instances --instance-ids $INSTANCE_ID --output text | grep PLACEMENT | awk '{print $2}'`
PUBLIC_IP=`aws ec2 describe-instances --instance-ids $INSTANCE_ID --output text | grep INSTANCES | awk '{print $14}'`
echo "Instance "$INSTANCE_ID" with DNS name "$DNS_NAME" created in availability zone "$AVAILABILITY_ZONE", with public IP address" $PUBLIC_IP > $INSTANCE_ID.log
echo "Use SSH key ""$KEY_ID".pem" for access (ssh -i $KEY_ID.pem ubuntu@$PUBLIC_IP)" >> $INSTANCE_ID.log
cat $INSTANCE_ID.log
echo "Details available in "$INSTANCE_ID".log"
