#!/bin/bash

# composer global require zircote/swagger-php

warning() {
    echo "$(tput setaf 1)$1$(tput sgr0)"
}

PHP="/usr/bin/php"
COMPOSER="/usr/local/bin/composer"
SWAGGER="${HOME}/.composer/vendor/bin/swagger"

if [ ! -f ${SWAGGER} ]; then
    ${COMPOSER} global require zircote/swagger-php
fi

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
    warning "Not exist work directory. [${WORK}]"
    exit 1
fi

TARGET="${WORK}/src/main/webapp/application"
DEST="${WORK}/src/main/webapp/apidoc"

if [ ! -d ${TARGET} ]; then
    warning "Not exist target directory. [${TARGET}]"
    exit 1
fi

${PHP} ${SWAGGER} ${TARGET} -o ${DEST}
