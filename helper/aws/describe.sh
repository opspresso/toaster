#!/bin/bash

REGIONS=/tmp/aws_regions

aws ec2 describe-regions | grep RegionName | cut -d'"' -f4 > ${REGIONS}

echo "################################################################################"
echo "# EC2 Instances."

while read REGION; do
    echo ">> region : ${REGION}"

    aws configure set default.region ${REGION}

    aws ec2 describe-instances | \
        jq '.Reservations[].Instances[] | {InstanceId: .InstanceId, InstanceType: .InstanceType, State: .State.Name}'
done < ${REGIONS}

echo "################################################################################"
echo "# EBS volumes."

while read REGION; do
    echo ">> region : ${REGION}"

    aws configure set default.region ${REGION}

    aws ec2 describe-volumes | jq '.Volumes[] | {VolumeId: .VolumeId, State: .State}'
done < ${REGIONS}

echo "################################################################################"
echo "# done."
