#!/bin/bash

mkdir -p build
mkdir -p target/dist

# VERSION
VERSION=$(curl -s https://api.github.com/repos/nalbam/toaster/releases/latest | grep tag_name | cut -d'"' -f4)
VERSION=$(echo ${VERSION:-v0.0.0} | perl -pe 's/^(([v\d]+\.)*)(\d+)(.*)$/$1.($3+1).$4/e')

echo "VERSION=${VERSION}"
printf "${VERSION}" > target/VERSION

# 755
find ./** | grep [.]sh | xargs chmod 755

# target/
cp -rf draft.sh target/draft
cp -rf toast.sh target/toaster
cp -rf install.sh target/install

# target/dist/
cp -rf draft.sh target/dist/draft
cp -rf toast.sh target/dist/toaster

# target/dist/draft.tar.gz
pushd draft
tar -czf ../target/dist/draft.tar.gz *
popd

# target/dist/helper.tar.gz
pushd helper
tar -czf ../target/dist/helper.tar.gz *
popd

# target/helper/
cp -rf helper target/

# target/
cp -rf web/* target/

ls -al build
ls -al target
