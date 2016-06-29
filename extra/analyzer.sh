#!/bin/bash

PHP_MD="/data/phptool/phpmd/vendor/bin/phpmd"

PROJECT=$1
WORK="/var/lib/jenkins/jobs/${PROJECT}/workspace"

/usr/local/php/bin/php ${PHP_MD} ${WORK} xml cleancode,codesize,controversial,design,naming,unusedcode --reportfile phpmd.xml | echo 1
