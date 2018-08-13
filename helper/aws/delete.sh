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
RESOURCES=/tmp/aws_RESOURCES

aws ec2 describe-regions | grep RegionName | cut -d'"' -f4 > ${REGIONS}

# echo "################################################################################"
# echo "# ElasticBeanstalk"

# while read REGION; do
#     echo ">> region : ${REGION}"

#     aws configure set default.region ${REGION}

#     # EB Environments
#     aws elasticbeanstalk describe-environments | jq '.Environments[] | {ApplicationName,EnvironmentName}' | \
#         grep EnvironmentName | cut -d'"' -f4 > ${RESOURCES}

#     while read KEY; do
#         aws elasticbeanstalk delete-environment-configuration --application-name ${KEY} --environment-name ${VAL}
#     done < ${RESOURCES}

#     aws elasticbeanstalk describe-environments | jq '.Environments[] | {ApplicationName,EnvironmentName}'
# done < ${REGIONS}

echo "################################################################################"
echo "# Auto Scaling Groups"

while read REGION; do
    echo ">> region : ${REGION}"

    aws configure set default.region ${REGION}

    # Auto Scaling Groups
    aws autoscaling describe-auto-scaling-groups | jq '.AutoScalingGroups[] | {AutoScalingGroupName}' | \
        grep AutoScalingGroupName | cut -d'"' -f4 > ${RESOURCES}

    while read KEY; do
        aws ec2 delete-auto-scaling-group --auto-scaling-group-name ${KEY}
    done < ${RESOURCES}

    aws autoscaling describe-auto-scaling-groups | jq '.AutoScalingGroups[] | {AutoScalingGroupName}'
done < ${REGIONS}

echo "################################################################################"
echo "# EC2 Instances"

while read REGION; do
    echo ">> region : ${REGION}"

    aws configure set default.region ${REGION}

    # EC2 Instances ('running', 'pending', 'stopping', 'stopped') ('shutting-down', 'terminated')
    aws ec2 describe-instances | \
        jq '.Reservations[].Instances[] | {InstanceId,InstanceType,State:.State.Name} | select(.State != "terminated")' | \
        grep InstanceId | cut -d'"' -f4 > ${RESOURCES}

    while read KEY; do
        aws ec2 modify-instance-attribute --instance-id ${KEY} --no-disable-api-termination
        aws ec2 terminate-instances --instance-ids ${KEY} | grep InstanceId
    done < ${RESOURCES}

    aws ec2 describe-instances | \
        jq '.Reservations[].Instances[] | {InstanceId,InstanceType,State:.State.Name}'
done < ${REGIONS}

echo "################################################################################"
echo "# EBS Volumes"

while read REGION; do
    echo ">> region : ${REGION}"

    aws configure set default.region ${REGION}

#    # EBS Volumes
#    aws ec2 describe-volumes | jq '.Volumes[] | {VolumeId,State} | select(.State=="in-use")' | \
#        grep VolumeId | cut -d'"' -f4 > ${RESOURCES}
#
#    while read KEY; do
#        aws ec2 detach-volume --volume-id ${KEY}
#    done < ${RESOURCES}

    # EBS Volumes
    aws ec2 describe-volumes | jq '.Volumes[] | {VolumeId,State}' | grep VolumeId | cut -d'"' -f4 > ${RESOURCES}

    while read KEY; do
        aws ec2 delete-volume --volume-id ${KEY}
    done < ${RESOURCES}

    aws ec2 describe-volumes | jq '.Volumes[] | {VolumeId,State}'
done < ${REGIONS}

echo "################################################################################"
echo "# done."
