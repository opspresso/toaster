#!/bin/bash

REPO=$1

if [ "${REPO}" == "" ]; then
    REPO="toast.sh"
fi

aws s3 sync target/ s3://${REPO}/ --quiet --acl public-read

echo "sync to ${REPO}"
