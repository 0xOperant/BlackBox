#!/bin/bash

# This script is similar to launch_AMI.sh, but migrates an Elastic IP from an existing instance, then terminates the old instance.

# AMI = Ubuntu 14.04.02 LTS 64-bit
# As of 26 Jul 2015, the 64-Bit Ubuntu 14.04.02 Linux AMI’s are:
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

AMI_ID=ami-5189a661	#configure this for your region
SIZE=t2.micro		#adjust for your needs			
KEY_ID=			#Your_SSH_Key
SEC_ID=VPN		#Your_VPC_Security_Group
BOOTSTRAP_SCRIPT=configure_VPN.sh 
OLD_INSTANCE=`aws ec2 describe-instances --filters "Name=instance-state-code,Values=16" | grep INSTANCES | awk '{print $7;exit;}'` #<---ASSUMES NEWEST RUNNING INSTANCE!!!

echo "Starting Instance..."
INSTANCE_DETAILS=`aws ec2 run-instances --image-id $AMI_ID --key-name $KEY_ID --security-groups $SEC_ID --instance-type $SIZE --user-data file://./$BOOTSTRAP_SCRIPT --output text | grep INSTANCES`

INSTANCE_ID=`echo $INSTANCE_DETAILS | awk '{print $7}'`

# wait for new instance to be started
STATUS=`aws ec2 describe-instance-status --instance-ids $INSTANCE_ID --output text | grep INSTANCESTATUS | grep -v INSTANCESTATUSES | awk '{print $2;exit;}'`

while [ "$STATUS" != "ok" ]
do
    echo "Waiting for instance to start..."
    sleep 30
    STATUS=`aws ec2 describe-instance-status --instance-ids $INSTANCE_ID --output text | grep INSTANCESTATUS | grep -v INSTANCESTATUSES | awk '{print $2;exit;}'`
done

echo "Instance "$INSTANCE_ID" successfully started! Migrating Elastic IP address..."

# disassociate elastic IP from old instance <---ASSUMES NEWEST ELASTIC IP!!!
ELASTIC_IP=`aws ec2 describe-addresses | awk '{print $9;exit;}'`
aws ec2 disassociate-address --public-ip $ELASTIC_IP
ASSOCIATION_ID=`aws ec2 associate-address --instance-id $INSTANCE_ID --public-ip $ELASTIC_IP`

# query instance details, log output to file and print to screen
DNS_NAME=`aws ec2 describe-instances --instance-ids $INSTANCE_ID --output text | grep INSTANCES | awk '{print $13;exit;}'`
AVAILABILITY_ZONE=`aws ec2 describe-instances --instance-ids $INSTANCE_ID --output text | grep PLACEMENT | awk '{print $2;exit;}'`
PUBLIC_IP=`aws ec2 describe-instances --instance-ids $INSTANCE_ID --output text | grep INSTANCES | awk '{print $14;exit;}'`
echo "Instance "$INSTANCE_ID" with DNS name "$DNS_NAME" created in availability zone "$AVAILABILITY_ZONE >> $INSTANCE_ID.log
echo "Elastic IP "$PUBLIC_IP" migrated with Association ID "$ASSOCIATION_ID >> $INSTANCE_ID.log
echo "Use SSH key "$KEY_ID".pem for access (ssh -i "$KEY_ID".pem ubuntu@"$PUBLIC_IP") or (ssh -i "$KEY_ID".pem ubuntu@"$DNS_NAME")" >> $INSTANCE_ID.log
cat $INSTANCE_ID.log
echo "Details available in "$INSTANCE_ID".log"

# terminate old instance
echo "Terminating old instance" $OLD_INSTANCE"..."
aws ec2 terminate-instances --instance-ids $OLD_INSTANCE
OLD_STATUS=`aws ec2 describe-instance-status --instance-ids $OLD_INSTANCE --output text | grep INSTANCESTATUS | grep -v INSTANCESTATUSES | awk '{print $2;exit;}'`

while [ "$OLD_STATUS" != "terminated" ]
do
    echo "Waiting for old instance to terminate..."
    sleep 30
    OLD_STATUS=`aws ec2 describe-instance-status --instance-ids $OLD_INSTANCE --output text | grep INSTANCESTATUS | grep -v INSTANCESTATUSES | awk '{print $2;exit;}'`
done

echo $OLD_INSTANCE" terminated successfully. Migration complete."
