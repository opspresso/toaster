#!/bin/bash

if [ -d target ]; then
    rm -rf target
fi

mkdir target

zip -q -r target/toaster extra package *.sh

VERSION=${1}
if [ "${VERSION}" == "" ]; then
    VERSION=`git rev-parse --short HEAD`
fi

echo "version=${VERSION}"
echo "${VERSION}" > target/version.txt

REPO="s3://repo.toast.sh"

OPTION="--quiet --grants read=uri=http://acs.amazonaws.com/groups/global/AllUsers"

aws s3 cp target/toaster.zip ${REPO}/release/ ${OPTION}
aws s3 cp target/version.txt ${REPO}/release/ ${OPTION}
aws s3 cp install.sh ${REPO}/release/ ${OPTION}
