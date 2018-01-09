#!/bin/bash

# composer global require zircote/swagger-php

error() {
    echo -e "$(tput setaf 1)$1$(tput sgr0)"
    exit 1
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
    error "Not exist work directory. [${WORK}]"
fi

TARGET="${WORK}/src/main/webapp/application"

if [ ! -d ${TARGET} ]; then
    error "Not exist target directory. [${TARGET}]"
fi

DEST="${WORK}/src/main/webapp/apidoc"

${PHP} ${SWAGGER} ${TARGET} -o ${DEST}
