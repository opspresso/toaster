#!/bin/bash

if [ -d target ]; then
    rm -rf target
fi

mkdir target

zip -q -r target/toaster extra package *.sh

aws s3 cp target/toaster.zip s3://repo.toast.sh/release/ --quiet --grants read=uri=http://acs.amazonaws.com/groups/global/AllUsers
