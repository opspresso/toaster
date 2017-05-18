#!/bin/bash

OPTION="--quiet --grants read=uri=http://acs.amazonaws.com/groups/global/AllUsers"

# upload
aws s3 cp target/* s3://toast.sh/ ${OPTION}
