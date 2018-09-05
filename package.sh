#!/bin/bash

rm -rf target
mkdir -p target/dist
mkdir -p target/helper

# OS_NAME
OS_NAME="$(uname | awk '{print tolower($0)}')"

echo "OS_NAME=${OS_NAME}"

# VERSION
VERSION=$(curl -s https://api.github.com/repos/nalbam/toaster/releases/latest | grep tag_name | cut -d'"' -f4)
VERSION=$(echo ${VERSION:-v0.0.0} | perl -pe 's/^(([v\d]+\.)*)(\d+)(.*)$/$1.($3+1).$4/e')

if [ "x$(echo ${VERSION} | cut -d'.' -f2)" == "x0" ]; then
    VERSION="v0.1.0"
fi

echo "VERSION=${VERSION}"
printf "${VERSION}" > target/VERSION

# 755
find ./** | grep [.]sh | xargs chmod 755

# target/
cp -rf install.sh target/install
cp -rf toaster.sh target/dist/toaster

# version
if [ "${OS_NAME}" == "linux" ]; then
    sed -i -e "s/THIS_VERSION=.*/THIS_VERSION=${VERSION}/" target/dist/toaster
elif [ "${OS_NAME}" == "darwin" ]; then
    sed -i "" -e "s/THIS_VERSION=.*/THIS_VERSION=${VERSION}/" target/dist/toaster
fi

# target/dist/draft.tar.gz
pushd draft
tar -czf ../target/dist/draft.tar.gz *
popd

# target/dist/helper.tar.gz
pushd helper
tar -czf ../target/dist/helper.tar.gz *
popd

# target/helper/
cp -rf helper/* target/helper/

# target/
cp -rf web/* target/

ls -al target
