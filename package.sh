#!/bin/bash

mkdir -p build
mkdir -p target

VERSION="$(git rev-parse --short HEAD)"

echo "VERSION=${VERSION}"

# toaster.txt
echo "${VERSION}" > target/toaster.txt
echo "v2-${VERSION}" > target/toaster-v2.txt
echo "v3-${VERSION}" > target/toaster-v3.txt

# chmod
find ./** | grep [.]sh | xargs chmod 755

# web
cp -rf web/* target/

# install.sh
cp -rf install-v2.sh target/install
cp -rf install-v2.sh target/install-v2
cp -rf install-v3.sh target/install-v3

# build
cp -rf v2 build/
cp -rf v3 build/

cp -rf extra helper install build/v2/
cp -rf extra helper install build/v3/

# toaster v2
pushd build/v2
tar -czf ../../target/toaster-v2.tar.gz extra install package *.sh
popd

# toaster v3
pushd build/v3
tar -czf ../../target/toaster-v3.tar.gz extra install *.sh
popd

ls -alh target
