#!/bin/bash

REPO="s3://repo.toast.sh"

OPTION="--quiet --grants read=uri=http://acs.amazonaws.com/groups/global/AllUsers"

# upload
aws s3 cp install.sh ${REPO}/release/ ${OPTION}
aws s3 cp target/toaster.txt ${REPO}/release/ ${OPTION}
aws s3 cp target/toaster.zip ${REPO}/release/ ${OPTION}
