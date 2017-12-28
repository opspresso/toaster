#!/bin/bash

CIRCLE_PROJECT_USERNAME="$1"

if [ "${CIRCLE_PROJECT_USERNAME}" == "yanolja" ]; then
    BUCKET="toaster.yanolja.com"
else
    BUCKET="toast.sh"
fi

aws s3 sync target/ s3://${BUCKET}/ --acl public-read
