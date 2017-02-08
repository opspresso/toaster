#!/bin/bash

if [ -d target ]; then
    rm -rf target
fi

mkdir target

zip -q -r target/toaster extra package *.sh

VERSION=${1}
if [ "${VERSION}" == "" ]; then
    VERSION="0.0.0"
fi

echo "${VERSION}" > target/version.txt

option="--quiet --grants read=uri=http://acs.amazonaws.com/groups/global/AllUsers"

aws s3 cp target/toaster.zip s3://repo.toast.sh/release/ ${option}
aws s3 cp target/version.txt s3://repo.toast.sh/release/ ${option}
aws s3 cp install.sh s3://repo.toast.sh/release/ ${option}
