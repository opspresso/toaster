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

# toaster.tar.gz
tar -czf target/toaster.tar.gz extra install package *.sh

# toaster.zip
zip -q -r target/toaster.zip extra install package *.sh

# list
echo -e "$(ls -al target)"
