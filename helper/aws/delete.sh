#!/bin/bash

echo "################################################################################"
echo "#                                                                              #"
echo "#    !!! Warning, If you enter 'yes', All Instances will be Terminate. !!!     #"
echo "#                                                                              #"
echo "################################################################################"

read YES
if [ "${YES}" != "yes" ]; then
    exit 1
fi

REGIONS=/tmp/aws_regions
INSTANCES=/tmp/aws_ec2_instances
VOLUMES=/tmp/aws_ec2_volumes

aws ec2 describe-regions | grep RegionName | cut -d'"' -f4 > ${REGIONS}

echo "################################################################################"
echo "# EC2 Instances."

while read REGION; do
    echo ">> region : ${REGION}"

    aws configure set default.region ${REGION}

    # EC2 Instances ('running', 'pending', 'stopping', 'stopped') ('shutting-down', 'terminated')
    aws ec2 describe-instances | \
        jq '.Reservations[].Instances[] | {InstanceId: .InstanceId, InstanceType: .InstanceType, State: .State.Name} | select(.State != "terminated")' | \
        grep InstanceId | cut -d'"' -f4 > ${INSTANCES}

    while read ID; do
        aws ec2 modify-instance-attribute --instance-id ${ID} --no-disable-api-termination
        aws ec2 terminate-instances --instance-ids ${ID} | grep InstanceId
    done < ${INSTANCES}

    aws ec2 describe-instances | \
        jq '.Reservations[].Instances[] | {InstanceId: .InstanceId, InstanceType: .InstanceType, State: .State.Name}'
done < ${REGIONS}

echo "################################################################################"
echo "# EBS volumes."

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

echo "################################################################################"
echo "# done."
