#!/bin/bash

OS_TYPE=`uname`
if [ ${OS_TYPE} != 'Linux' ]; then
    echo "Unsupported OS - $OS_TYPE"
    exit 1
fi

################################################################################

EXT="tar.gz"

VERSION="8"

################################################################################

URL1="http://mirror.apache-kr.org/tomcat/tomcat-${VERSION}/"
URL2=$(curl -s ${URL1} | egrep -o "v${VERSION}.0.[0-9]+")

ARR=(${URL2})

if [ "$ARR[0]" == "" ]; then
    echo "Could not get node url - $URL2"
    exit 1
fi

CURRENT="${ARR[0]:1}"

URL3="http://mirror.apache-kr.org/tomcat/tomcat-${VERSION}/v${CURRENT}/bin/apache-tomcat-${CURRENT}.tar.gz"

# http://mirror.apache-kr.org/tomcat/tomcat-8/v8.0.36/bin/apache-tomcat-8.0.36.tar.gz

if [[ -z "$URL3" ]]; then
    echo "Could not get node url - $URL3"
    exit 1
fi

TOMCAT=$(echo ${URL3} | cut -d "/" -f 8)

if [[ -z "$TOMCAT" ]]; then
    echo "Could not get tomcat - $TOMCAT"
    exit 1
fi

echo ${URL3}
echo ${TOMCAT}

################################################################################

APPS_DIR="$1"
if [ "${APPS_DIR}" == "" ]; then
    APPS_DIR="/data/apps"
fi

rm -rf ${APPS_DIR}/apache-tomcat*
rm -rf ${APPS_DIR}/tomcat*

wget -q -N "${URL3}"

tar xzf ${TOMCAT}

mv "apache-tomcat-${CURRENT}" "${APPS_DIR}/tomcat${VERSION}"

TOMCAT_DIR="${APPS_DIR}/tomcat${VERSION}"

chmod 755 ${TOMCAT_DIR}/bin/*.sh

rm -rf ${TOMCAT_DIR}/webapps/*
