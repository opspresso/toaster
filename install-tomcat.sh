#!/bin/bash

EXT="tar.gz"

VERSION="8.0"
if [ "$1" == "8.5" ]; then
    VERSION="8.5"
fi

################################################################################

URL0="http://tomcat.apache.org"
URL1="${URL0}/download-80.cgi"
URL2=$(curl -s ${URL1} | egrep -o "http\:\/\/apache\.mirror\.cdnetworks\.com\/tomcat\/tomcat-8\/v${VERSION}\.[0-9]+\/bin\/apache-tomcat-${VERSION}\.[0-9]+\.${EXT}")

# http://apache.mirror.cdnetworks.com/tomcat/tomcat-8/v8.0.36/bin/apache-tomcat-8.0.36.tar.gz
# http://apache.mirror.cdnetworks.com/tomcat/tomcat-8/v8.5.4/bin/apache-tomcat-8.5.4.tar.gz

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

################################################################################

wget ${URL3}
