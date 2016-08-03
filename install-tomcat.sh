#!/bin/bash

EXT="tar.gz"

VERSION="8"
#if [ "$1" == "7" ]; then
#    VERSION="7"
#fi

################################################################################

URL="http://tomcat.apache.org"
URL1="${URL}/download-${VERSION}0.cgi"
URL2=$(curl -s "$URL1" | egrep -o "http\:\/\/apache.mirror.cdnetworks.com\/tomcat\/tomcat-${VERSION}\/v${VERSION}.0.[0-9]+\/bin\/apache-tomcat-${VERSION}-0-[0-9]+.${EXT}")

if [[ -z "$URL2" ]]; then
    echo "Could not download - $URL1"
    exit 1
fi

URL3=$(echo ${URL2} | cut -d " " -f 1)

TOMCAT=$(echo ${URL3} | cut -d "/" -f 8)
if [[ -z "$TOMCAT" ]]; then
    echo "Could not get TOMCAT - $TOMCAT"
    exit 1
fi

echo ${TOMCAT}
