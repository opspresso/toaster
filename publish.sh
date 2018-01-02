#!/bin/bash

BUCKET="toast.sh"

aws s3 sync target/ s3://${BUCKET}/ --acl public-read
