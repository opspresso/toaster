#!/bin/bash

REGIONS=/tmp/aws_regions
INSTANCES=/tmp/aws_ec2_instances
VOLUMES=/tmp/aws_ec2_volumes

aws ec2 describe-regions | grep RegionName | cut -d'"' -f4 > ${REGIONS}

while read REGION; do
    echo ">> region : ${REGION}"

    aws configure set default.region ${REGION}

    # EC2 Instances ('running', 'pending', 'stopping', 'stopped') ('shutting-down', 'terminated')
    aws ec2 describe-instances | \
        jq '.Reservations[].Instances[] | select(.State != "terminated") | {InstanceId: .InstanceId, InstanceType: .InstanceType, State: .State.Name}' | \
        grep InstanceId | cut -d'"' -f4 > ${INSTANCES}

    while read ID; do
        aws ec2 modify-instance-attribute --instance-id ${ID} --no-disable-api-termination
        aws ec2 terminate-instances --instance-ids ${ID} | grep InstanceId
    done < ${INSTANCES}

    aws ec2 describe-instances | jq '.Reservations[].Instances[] | {InstanceId: .InstanceId, InstanceType: .InstanceType, State: .State.Name}'
done < ${REGIONS}

while read REGION; do
    echo ">> region : ${REGION}"

    aws configure set default.region ${REGION}

#    # EBS volumes
#    aws ec2 describe-volumes | jq '.Volumes[] | {VolumeId: .VolumeId, State: .State} | select(.State=="in-use")' | \
#        grep VolumeId | cut -d'"' -f4 > ${VOLUMES}
#
#    while read ID; do
#        aws ec2 detach-volume --volume-id ${ID}
#    done < ${VOLUMES}

    aws ec2 describe-volumes | jq '.Volumes[] | {VolumeId: .VolumeId, State: .State}' | grep VolumeId | cut -d'"' -f4 > ${VOLUMES}

    while read ID; do
        aws ec2 delete-volume --volume-id ${ID}
    done < ${VOLUMES}

    aws ec2 describe-volumes | jq '.Volumes[] | {VolumeId: .VolumeId, State: .State}'
done < ${REGIONS}

echo "# done."
