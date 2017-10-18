#!/bin/bash

if [ -d target ]; then
    rm -rf target
fi

mkdir target

VERSION="$(git rev-parse --short HEAD)"

# toaster.txt
echo "version=${VERSION}"
echo "${VERSION}" > target/toaster.txt

# web
cp -rf web/* target/

# install.sh
cp -rf install.sh target/install

# toaster v2
pushd v2
tar -czf ../target/toaster-v2.tar.gz extra install package *.sh
popd

# toaster v3
#pushd v3
#tar -czf ../target/toaster-v3.tar.gz *.sh
#popd
