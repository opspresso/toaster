#!/bin/bash

mkdir -p build
mkdir -p target

VERSION="$(git rev-parse --short HEAD)"

echo "VERSION=${VERSION}"

# toaster.txt
echo "${VERSION}" > target/toaster.txt

# 755
find ./** | grep [.]sh | xargs chmod 755

# draft
cp -rf draft.sh target/draft
pushd draft/
tar -czf ../target/draft.tar.gz *
popd

# helper
cp -rf helper build/
cp -rf helper target/

# web
cp -rf web/* target/

# install.sh
cp -rf install.sh target/install

# toast.sh
cp -rf toast.sh build/

# build
pushd build/
tar -czf ../target/toaster.tar.gz *
popd

ls -al build
ls -al target
