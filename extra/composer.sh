#!/bin/bash

# curl -sS https://getcomposer.org/installer | php
# mv composer.phar /usr/local/bin/composer

warning() {
    echo "$(tput setaf 1)$1$(tput sgr0)"
}

PHP="/usr/bin/php"
COMPOSER="/usr/local/bin/composer"

if [ ! -f ${COMPOSER} ]; then
    warning "Not exist composer file. [${COMPOSER}]"
    exit 1
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

TARGET="${WORK}/src/main/webapp"
VENDOR="${TARGET}/vendor"

if [ ! -d ${TARGET} ]; then
    warning "Not exist target directory. [${TARGET}]"
    exit 1
fi

cd ${TARGET}

if [ -d "${VENDOR}" ]; then
    ${PHP} ${COMPOSER} update
else
    ${PHP} ${COMPOSER} install
fi
