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
zip -q -r target/toaster extra install package *.sh
