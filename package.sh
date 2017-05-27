#!/bin/bash

if [ -d target ]; then
    rm -rf target
fi

mkdir target

VERSION=$(git rev-parse --short HEAD)

# toaster.txt
echo "version=${VERSION}"
echo "${VERSION}" > target/toaster.txt

# toaster.zip
zip -q -r target/toaster ./extra ./install ./package ./*.sh

# install.sh
cp -rf install.sh target/install

# web
cp -rf web/* target/
