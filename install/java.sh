#!/bin/bash

echo_() {
    echo "$1"
    echo "$1" >> /tmp/toast.log
}

success() {
    echo -e "$(/usr/bin/tput setaf 2)$1$(/usr/bin/tput sgr0)"
    echo "$1" >> /tmp/toast.log
}

inform() {
    echo -e "$(/usr/bin/tput setaf 6)$1$(/usr/bin/tput sgr0)"
    echo "$1" >> /tmp/toast.log
}

warning() {
    echo -e "$(/usr/bin/tput setaf 1)$1$(/usr/bin/tput sgr0)"
    echo "$1" >> /tmp/toast.log
}

download() {
    _FILE="$1"
    _PATH="$2"

    if [ "${REPO}" != "" ]; then
        URL="${REPO}/${_PATH}/${_FILE}"

        echo_ "download... [${URL}]"

        /usr/bin/aws s3 cp ${URL} ./
    fi

    if [ ! -f ${_FILE} ]; then
        URL="http://repo.toast.sh/${_PATH}/${_FILE}"

        echo_ "download... [${URL}]"

        /usr/bin/curl -O ${URL}
    fi
}

################################################################################

OS_NAME=$(uname)
if [ ${OS_NAME} != "Linux" ]; then
    warning "Not supported OS : ${OS_NAME}"
    exit 1
fi

SUDO=""
if [ "${HOME}" != "/root" ]; then
    SUDO="sudo"
fi

################################################################################

# s3://repo.toast.sh/java/server-jre-8u144-linux-x64.tar.gz

NAME="java"

VERSION="8u144"

FILE="server-jre-${VERSION}-linux-x64"

EXT="tar.gz"

################################################################################

REPO="$1"

download "${FILE}.${EXT}" "${NAME}"

if [ ! -f ${FILE}.${EXT} ]; then
    warning "Can not download : ${FILE}.${EXT}"
    exit 1
fi

################################################################################

tar xzf ${FILE}.${EXT}

VS1=$(echo ${FILE} | cut -d "-" -f 3)
VS2="${VS1/u/.0_}"

JAVA_DIR="jdk1.${VS2}"
JAVA_HOME="/usr/local/${JAVA_DIR}"

if [ ! -d ${JAVA_DIR} ]; then
    warning "Can not found : ${JAVA_DIR}"
    exit 1
fi

${SUDO} rm -rf ${JAVA_HOME}
${SUDO} mv ${JAVA_DIR} /usr/local/

${SUDO} rm -rf /usr/local/java
${SUDO} ln -s ${JAVA_HOME} /usr/local/java

rm -rf ${FILE}.${EXT}

download "local_policy.jar.bin" "${NAME}"
if [ -f local_policy.jar.bin ]; then
    ${SUDO} mv local_policy.jar.bin ${JAVA_HOME}/jre/lib/security/local_policy.jar
fi

download "US_export_policy.jar.bin" "${NAME}"
if [ -f US_export_policy.jar.bin ]; then
    ${SUDO} mv US_export_policy.jar.bin ${JAVA_HOME}/jre/lib/security/US_export_policy.jar
fi

echo_ "JAVA_HOME=${JAVA_HOME}"
