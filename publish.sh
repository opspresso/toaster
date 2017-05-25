#!/bin/bash

TARGET_PATH="target"
DEPLOY_PATH="s3://toast.sh/circle"

OPTION="--acl public-read --region=ap-northeast-2"

# upload
aws s3 sync "${TARGET_PATH}" "${DEPLOY_PATH}" ${OPTION}
