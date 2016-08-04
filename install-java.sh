#!/bin/bash

OS_TYPE=`uname`
if [ ${OS_TYPE} != 'Linux' ]; then
    echo "Unsupported OS - $OS_TYPE"
    exit 1
fi

################################################################################

OS_NAME="linux"

TYPE="jdk"
EXT="tar.gz"

VERSION="8"
if [ "$1" == "7" ]; then
    VERSION="7"
fi

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
URL2=$(curl -s ${URL1} | egrep -o "\/technetwork\/java/\javase\/downloads\/${TYPE}${VERSION}-downloads-.*\.html" | head -1)

if [[ -z "$URL2" ]]; then
    echo "Could not download - $URL1"
    exit 1
fi

URL3="$(echo ${URL0}${URL2} | awk -F\" {'print $1'})"
URL4=$(curl -s ${URL3} | egrep -o "http\:\/\/download\.oracle\.com\/otn-pub\/java\/jdk\/${VERSION}u(.*)\/${TYPE}-${VERSION}u(.*)-${OS_NAME}-${OS_BIT}.${EXT}")

# http://download.oracle.com/otn-pub/java/jdk/8u101-b13/jdk-8u101-linux-x64.tar.gz

if [[ -z "$URL4" ]]; then
    echo "Could not get ${TYPE} url - $URL4"
    exit 1
fi

URL5=$(echo ${URL4} | cut -d " " -f 1)

JAVA=$(echo ${URL5} | cut -d "/" -f 8)
if [[ -z "$JAVA" ]]; then
    echo "Could not get JAVA - $JAVA"
    exit 1
fi

echo ${JAVA}

################################################################################

wget --no-cookies --no-check-certificate --header "Cookie: oraclelicense=accept-securebackup-cookie" ${URL5}

tar xvzf ${JAVA}

rm -rf ${JAVA}

VS0=$(echo ${JAVA} | cut -d "-" -f 1)
VS1=$(echo ${JAVA} | cut -d "-" -f 2)
VS2="${VS1/u/.0_}"

JAVA_DIR="${VS0}1.${VS2}"
JAVA_HOME="/usr/local/${JAVA_DIR}"

${SUDO} rm -rf "${JAVA_HOME}"
${SUDO} mv ${JAVA_DIR} /usr/local/

${SUDO} rm -f /usr/bin/java
${SUDO} ln -s "${JAVA_HOME}/bin/java" /usr/bin/java

${SUDO} rm -f /usr/bin/javac
${SUDO} ln -s "${JAVA_HOME}/bin/javac" /usr/bin/javac

${SUDO} rm -f /usr/bin/jar
${SUDO} ln -s "${JAVA_HOME}/bin/jar" /usr/bin/jar

echo "JAVA_HOME=${JAVA_HOME}"
