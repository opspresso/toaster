#!/bin/bash

if [ -d target ]; then
    rm -rf target
fi

mkdir target

VERSION=${1}
if [ "${VERSION}" == "" ]; then
    VERSION=`git rev-parse --short HEAD`
fi

# index.html
cp index.html target/

# install.sh
cp install.sh target/

# toaster.txt
echo "version=${VERSION}"
echo "${VERSION}" > target/toaster.txt

# toaster.zip
zip -q -r target/toaster extra install package *.sh
