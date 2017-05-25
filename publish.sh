#!/bin/bash

OPTION="--grants read=uri=http://acs.amazonaws.com/groups/global/AllUsers"

# upload
aws s3 sync target/ s3://toast.sh/circle/ ${OPTION}
