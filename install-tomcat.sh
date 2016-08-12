#!/bin/bash

OS_TYPE=`uname`
if [ ${OS_TYPE} != 'Linux' ]; then
    echo "Unsupported OS - $OS_TYPE"
    exit 1
fi

################################################################################

OS_NAME="linux"

EXT="tar.gz"

VERSION="8"

################################################################################

URL1="http://tomcat.apache.org/download-80.cgi?Preferred=http%3A%2F%2Fmirror.apache-kr.org%2F"
URL2=$(curl -s ${URL1} | egrep -o "http\:\/\/mirror\.apache-kr\.org\/tomcat\/tomcat-${VERSION}\/v${VERSION}.0.(.*)\/bin\/apache-tomcat-${VERSION}.0.(.*).${EXT}")

# http://mirror.apache-kr.org/tomcat/tomcat-8/v8.0.36/bin/apache-tomcat-8.0.36.tar.gz

if [[ -z "$URL2" ]]; then
    echo "Could not get tomcat url - $URL2"
    exit 1
fi

URL3=$(echo ${URL2} | cut -d " " -f 1)

TOMCAT=$(echo ${URL3} | cut -d "/" -f 6)

if [[ -z "$TOMCAT" ]]; then
    echo "Could not get tomcat - $TOMCAT"
    exit 1
fi

echo ${TOMCAT}

################################################################################

wget -q -N ${URL3}
