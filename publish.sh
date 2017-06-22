#!/bin/bash

#aws s3 sync target/ s3://toast.sh/ --acl public-read
aws s3 cp target/* s3://toast.sh/ --acl public-read
