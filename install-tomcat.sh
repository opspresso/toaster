#!/bin/bash

OS_NAME=`uname`
if [ ${OS_NAME} != "Linux" ]; then
    echo "Not supported OS : $OS_NAME"
    exit 1
fi

################################################################################

EXT="tar.gz"

VERSION="8"

APPS_DIR="$1"
if [ "${APPS_DIR}" == "" ]; then
    APPS_DIR="/data/apps"
fi

TOMCAT_DIR="${APPS_DIR}/tomcat${VERSION}"

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

wget -q -N -P "${APPS_DIR}" "${URL3}"

tar xzf ${TOMCAT}

#rm -rf ${TOMCAT}

rm -rf ${TOMCAT_DIR}

mv apache-tomcat-${CURRENT} ${TOMCAT_DIR}

chmod 755 ${TOMCAT_DIR}/bin/*.sh

rm -rf ${TOMCAT_DIR}/webapps/*
