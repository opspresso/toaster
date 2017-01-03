#!/bin/bash

# composer global require phpmd/phpmd

warning() {
    echo "$(tput setaf 1)$1$(tput sgr0)"
}

PHP="/usr/bin/php"
COMPOSER="/usr/local/bin/composer"
PHPMD="${HOME}/.composer/vendor/bin/phpmd"

if [ ! -f ${PHPMD} ]; then
    ${COMPOSER} global require phpmd/phpmd
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

CONFIG="cleancode,codesize,controversial,design,naming,unusedcode"

${PHP} ${PHPMD} ${WORK} xml ${CONFIG} --reportfile phpmd.xml | echo 1
