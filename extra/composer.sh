#!/bin/bash

PHP="/usr/bin/php"
COMPOSER="/usr/local/bin/composer"

PROJECT=$1
if [ -d "~/.jenkins/workspace/${PROJECT}" ]; then
    WORK="~/.jenkins/workspace/${PROJECT}"
else
    if [ -d "/var/lib/jenkins/jobs/${PROJECT}/workspace" ]; then
        WORK="/var/lib/jenkins/jobs/${PROJECT}/workspace"
    fi
fi
if [ "WORK" == "" ]; then
    exit 1
fi
TARGET="${WORK}/src/main/webapp"
VENDOR="${TARGET}/vendor"

cd ${TARGET}

if [ -d "${VENDOR}" ]; then
  ${PHP} ${COMPOSER} update
else
  ${PHP} ${COMPOSER} install
fi
