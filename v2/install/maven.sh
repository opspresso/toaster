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

# s3://repo.toast.sh/maven/apache-maven-3.5.0-bin.tar.gz

NAME="maven"

VERSION="3.5.0"

FILE="apache-${NAME}-${VERSION}-bin"

EXT="tar.gz"

MAVEN_HOME="/data/apps/maven3"

################################################################################

REPO="$1"

download "${FILE}.${EXT}" "${NAME}"

if [ ! -f ${FILE}.${EXT} ]; then
    warning "Can not download : ${FILE}.${EXT}"
    exit 1
fi

################################################################################

tar xzf ${FILE}.${EXT}

if [ ! -d apache-${NAME}-${VERSION} ]; then
    warning "Can not found : apache-${NAME}-${VERSION}"
    exit 1
fi

mv apache-${NAME}-${VERSION} ${MAVEN_HOME}

rm -rf ${FILE}.${EXT}

echo_ "MAVEN_HOME=${MAVEN_HOME}"
