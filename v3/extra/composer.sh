#!/bin/bash

# curl -sS https://getcomposer.org/installer | php
# sudo mv composer.phar /usr/local/bin/composer

error() {
    echo -e "$(tput setaf 1)$1$(tput sgr0)"
    exit 1
}

PHP="/usr/bin/php"
COMPOSER="/usr/local/bin/composer"

if [ ! -f ${COMPOSER} ]; then
    error "Not exist composer. [${COMPOSER}]"
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

TARGET="${WORK}/src/main/webapp"

if [ ! -d ${TARGET} ]; then
    error "Not exist target directory. [${TARGET}]"
fi

LOCK="${TARGET}/composer.lock"

if [ -f "${LOCK}" ]; then
    rm -rf ${LOCK}
fi

VENDOR="${TARGET}/vendor"

if [ -d "${VENDOR}" ]; then
    rm -rf ${VENDOR}
fi

cd ${TARGET}

${PHP} ${COMPOSER} install
