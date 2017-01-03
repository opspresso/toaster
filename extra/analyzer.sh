#!/bin/bash

# composer global require phpmd/phpmd

PHP="/usr/bin/php"
PHPMD="~/.composer/vendor/bin/phpmd"

if [ ! -f ${PHPMD} ]; then
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
    exit 1
fi

CONFIG="cleancode,codesize,controversial,design,naming,unusedcode"

${PHP} ${PHPMD} ${WORK} xml ${CONFIG} --reportfile phpmd.xml | echo 1
