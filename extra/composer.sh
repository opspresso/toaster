#!/bin/bash

PHP="/usr/bin/php"
COMPOSER="/usr/local/bin/composer"

PROJECT=$1
WORK="~/.jenkins/workspace/${PROJECT}"
TARGET="${WORK}/src/main/webapp"
VENDOR="${TARGET}/vendor"

cd ${TARGET}

if [ -d "${VENDOR}" ]; then
  ${PHP} ${COMPOSER} update
else
  ${PHP} ${COMPOSER} install
fi
