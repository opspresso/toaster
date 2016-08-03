#!/bin/bash

TYPE="jdk"
EXT="tar.gz"

OS_TYPE=`uname`
if [ ${OS_TYPE} != 'Linux' ]; then
    echo "Unsupported OS - $OS_TYPE"
    exit 1
fi

OS_NAME="linux"

MACHINE=`uname -m`
if [ ${MACHINE} == 'x86_64' ]; then
    OS="x64"
else
    OS="i586"
fi

VERSION="8"
if [ "$1" == "7" ]; then
    VERSION="7"
fi

URL="http://www.oracle.com"
URL1="${URL}/technetwork/java/javase/downloads/index.html"
URL2=$(curl -s ${URL1} | egrep -o "\/technetwork\/java/\javase\/downloads\/${TYPE}${VERSION}-downloads-.*\.html" | head -1)

if [[ -z "$URL2" ]]; then
    echo "Could not download - $URL1"
    exit 1
fi

URL3="$(echo ${URL}${URL2} | awk -F\" {'print $1'})"
URL4=$(curl -s "$URL3" | egrep -o "http\:\/\/download.oracle\.com\/otn-pub\/java\/jdk\/[7-8]u[0-9]+\-(.*)+\/${TYPE}-[7-8]u[0-9]+(.*)${OS_NAME}-${OS}.${EXT}")

if [[ -z "$URL4" ]]; then
    echo "Could not get ${TYPE} download url - $URL4"
    exit 1
fi

URL5=$(echo ${URL4} | cut -d " " -f 1)

JAVA=$(echo ${URL5} | cut -d "/" -f 8)
if [[ -z "$JAVA" ]]; then
    echo "Could not be JAVA_INSTALL - $JAVA"
    exit 1
fi

echo ${JAVA}

wget --no-cookies --no-check-certificate --header "Cookie: oraclelicense=accept-securebackup-cookie" ${URL5}

# install
ls -al | grep jdk

java -version

JAVA_PATH=$(dirname $(dirname $(readlink -f $(which java))))
