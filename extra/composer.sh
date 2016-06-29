#!/bin/bash

PHP="/usr/local/php/bin/php"
COMPOSER="/usr/local/bin/composer"

PROJECT=$1
WORK="/var/lib/jenkins/jobs/${PROJECT}/workspace"
TARGET="${WORK}/src/main/webapp"
VENDOR="${TARGET}/vendor"

cd ${TARGET}

if [ -d "${VENDOR}" ]; then
  ${PHP} ${COMPOSER} update
else
  ${PHP} ${COMPOSER} install
fi
