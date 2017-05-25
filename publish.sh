#!/bin/bash

TARGET_PATH="target/"
DEPLOY_PATH="s3://toast.sh/circle/"

OPTION="--acl public-read"

# upload
aws s3 sync "${TARGET_PATH}" "${DEPLOY_PATH}" ${OPTION}
