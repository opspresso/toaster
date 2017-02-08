#!/bin/bash

if [ -d target ]; then
    rm -rf target
fi

mkdir target

VERSION=${1}
if [ "${VERSION}" == "" ]; then
    VERSION=`git rev-parse --short HEAD`
fi

echo "version=${VERSION}"
echo "${VERSION}" > target/toaster.txt

# zip
zip -q -r target/toaster extra package *.sh

REPO="s3://repo.toast.sh"

OPTION="--quiet --grants read=uri=http://acs.amazonaws.com/groups/global/AllUsers"

# upload
aws s3 cp target/toaster.txt ${REPO}/release/ ${OPTION}
aws s3 cp target/toaster.zip ${REPO}/release/ ${OPTION}
aws s3 cp install.sh ${REPO}/release/ ${OPTION}
