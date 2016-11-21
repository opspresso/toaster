#!/bin/bash

OS_NAME=`uname`
if [ ${OS_NAME} != "Linux" ]; then
    echo "Not supported OS - $OS_NAME"
    exit 1
fi

################################################################################

OS_NAME="linux"

EXT="tar.gz"

VERSION="8"

SUDO=""
if [ "${HOME}" != "/root" ]; then
    SUDO="sudo"
fi

MACHINE=`uname -m`
if [ ${MACHINE} == 'x86_64' ]; then
    OS_BIT="x64"
else
    OS_BIT="i586"
fi

################################################################################

URL0="http://www.oracle.com"
URL1="${URL0}/technetwork/java/javase/downloads/index.html"
URL2=$(curl -s ${URL1} | egrep -o "\/technetwork\/java/\javase\/downloads\/server-jre${VERSION}-downloads-(.*)\.html" | head -1)

# http://www.oracle.com/technetwork/java/javase/downloads/server-jre8-downloads-2133154.html

if [[ -z "$URL2" ]]; then
    echo "Could not download - $URL1"
    exit 1
fi

URL3="$(echo ${URL0}${URL2} | awk -F\" {'print $1'})"
URL4=$(curl -s ${URL3} | egrep -o "http\:\/\/download\.oracle\.com\/otn-pub\/java\/jdk\/${VERSION}u(.*)\/server-jre-${VERSION}u(.*)-${OS_NAME}-${OS_BIT}.${EXT}")

# http://download.oracle.com/otn-pub/java/jdk/8u101-b13/server-jre-8u101-linux-x64.tar.gz

if [[ -z "$URL4" ]]; then
    echo "Could not get java url - $URL4"
    exit 1
fi

URL5=$(echo ${URL4} | cut -d " " -f 1)

JAVA=$(echo ${URL5} | cut -d "/" -f 8)
if [[ -z "$JAVA" ]]; then
    echo "Could not get java - $JAVA"
    exit 1
fi

echo ${URL5}
echo ${JAVA}

################################################################################

wget -q -N --no-cookies --no-check-certificate --header "Cookie: oraclelicense=accept-securebackup-cookie" ${URL5}

tar xzf ${JAVA}

rm -rf ${JAVA}

VS1=$(echo ${JAVA} | cut -d "-" -f 3)
VS2="${VS1/u/.0_}"

JAVA_DIR="jdk1.${VS2}"
JAVA_HOME="/usr/local/${JAVA_DIR}"

${SUDO} rm -rf ${JAVA_HOME}
${SUDO} mv ${JAVA_DIR} /usr/local/

${SUDO} rm -rf /usr/local/java
${SUDO} ln -s ${JAVA_HOME} /usr/local/java

echo "JAVA_HOME=${JAVA_HOME}"
