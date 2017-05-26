#!/bin/bash

TARGET_PATH="target/"
DEPLOY_PATH="s3://toast.sh/"

OPTION="--quiet --acl public-read"

# upload
aws s3 sync "${TARGET_PATH}" "${DEPLOY_PATH}" "${OPTION}"
