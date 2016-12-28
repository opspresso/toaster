#!/bin/bash

PHP="/usr/bin/php"
SWAGGER="~/.composer/vendor/bin/swagger"

PROJECT=$1
if [ "${PROJECT}" == "" ]; then
    WORK="."
else
    if [ -d "~/.jenkins/workspace/${PROJECT}" ]; then
        WORK="~/.jenkins/workspace/${PROJECT}"
    else
        if [ -d "/var/lib/jenkins/jobs/${PROJECT}/workspace" ]; then
            WORK="/var/lib/jenkins/jobs/${PROJECT}/workspace"
        fi
    fi
fi

if [ "${WORK}" == "" ]; then
    exit 1
fi

TARGET="${WORK}/src/main/webapp/application"
DEST="${WORK}/src/main/webapp/apidoc"

if [ ! -d ${TARGET} ]; then
    exit 1
fi

${PHP} ${SWAGGER} ${TARGET} -o ${DEST}
