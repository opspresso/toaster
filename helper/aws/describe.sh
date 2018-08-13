#!/bin/bash

REGIONS=/tmp/aws_regions

aws ec2 describe-regions | grep RegionName | cut -d'"' -f4 > ${REGIONS}

echo "################################################################################"
echo "# ElasticBeanstalk"

while read REGION; do
    echo ">> region : ${REGION}"

    aws configure set default.region ${REGION}

    aws elasticbeanstalk describe-environments | jq '.Environments[] | {ApplicationName,EnvironmentName}'
done < ${REGIONS}

echo "################################################################################"
echo "# Auto Scaling Groups"

while read REGION; do
    echo ">> region : ${REGION}"

    aws configure set default.region ${REGION}

    aws autoscaling describe-auto-scaling-groups | jq '.AutoScalingGroups[] | {AutoScalingGroupName}'
done < ${REGIONS}

echo "################################################################################"
echo "# EC2 Instances"

while read REGION; do
    echo ">> region : ${REGION}"

    aws configure set default.region ${REGION}

    aws ec2 describe-instances | \
        jq '.Reservations[].Instances[] | {InstanceId,InstanceType,State:.State.Name}'
done < ${REGIONS}

echo "################################################################################"
echo "# EBS Volumes"

while read REGION; do
    echo ">> region : ${REGION}"

    aws configure set default.region ${REGION}

    aws ec2 describe-volumes | jq '.Volumes[] | {VolumeId,State}'
done < ${REGIONS}

echo "################################################################################"
echo "# done."
