#!/bin/bash

TYPE="jdk"
VERSION="8"
EXT="rpm"
OS="x64"

OS_TYPE=`uname`
OS_NAME="linux"

if [ ${OS_TYPE} == 'Linux' ]; then
    OS_NAME="linux"
fi

if [ ${OS_TYPE} == 'Darwin' ]; then
    OS_NAME="macosx"
    EXT="dmg"
fi

MACHINE_TYPE=`uname -m`
if [ ${MACHINE_TYPE} == 'x86_64' ]; then
    OS="x64"
else
    OS="i586"
fi

if [[ -n "$1" ]]; then
    if [[ "$1" == "7" ]]; then
        VERSION="7"
    fi
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

JAVA_INSTALL=$(echo ${URL5}|cut -d "/" -f 8)
if [[ -z "$JAVA_INSTALL" ]]; then
    echo "Could not be JAVA_INSTALL - $JAVA_INSTALL"
    exit 1
fi

echo ${JAVA_INSTALL}

if [ ${OS_TYPE} == 'Darwin' ]; then
    sudo curl --cookie "oraclelicense=accept-securebackup-cookie" --location-trusted -O ${URL5}
else
    sudo wget --no-cookies --no-check-certificate --header "Cookie: oraclelicense=accept-securebackup-cookie" ${URL5}
fi

pw2

if [ ${OS_TYPE} == 'Darwin' ]; then
    # install
    ls -al | grep jdk
fi

if [ ${OS_TYPE} == 'Linux' ]; then
    # install
    ls -al | grep jdk
fi

java -version
javac -version
