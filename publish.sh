#!/bin/bash

OPTION="--quiet --grants read=uri=http://acs.amazonaws.com/groups/global/AllUsers"

REPO="s3://toast.sh"

# upload
aws s3 cp install.sh ${REPO}/ ${OPTION}
aws s3 cp target/toaster.txt ${REPO}/ ${OPTION}
aws s3 cp target/toaster.zip ${REPO}/ ${OPTION}

REPO="s3://repo.toast.sh"

# upload
aws s3 cp install.sh ${REPO}/release/ ${OPTION}
aws s3 cp target/toaster.txt ${REPO}/release/ ${OPTION}
aws s3 cp target/toaster.zip ${REPO}/release/ ${OPTION}
