#!/bin/bash

PHP="/usr/bin/php"
PHPMD="~/.composer/vendor/bin/phpmd"

PROJECT=$1
WORK="/var/lib/jenkins/jobs/${PROJECT}/workspace"

CONFIG="cleancode,codesize,controversial,design,naming,unusedcode"

${PHP} ${PHPMD} ${WORK} xml ${CONFIG} --reportfile phpmd.xml | echo 1
