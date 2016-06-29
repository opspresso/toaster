#!/bin/bash

PHP="/usr/local/php/bin/php"
PHP_MD="/data/phptool/phpmd/vendor/bin/phpmd"

PROJECT=$1
WORK="/var/lib/jenkins/jobs/${PROJECT}/workspace"

CONFIG="cleancode,codesize,controversial,design,naming,unusedcode"

${PHP} ${PHP_MD} ${WORK} xml ${CONFIG} --reportfile phpmd.xml | echo 1
