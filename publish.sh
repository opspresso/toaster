#!/bin/bash

TARGET_PATH="target"
DEPLOY_PATH="s3://toast.sh/circle"

OPTION="--grants read=uri=http://acs.amazonaws.com/groups/global/AllUsers"

# upload
aws s3 sync "${TARGET_PATH}" "${DEPLOY_PATH}" ${OPTION}
