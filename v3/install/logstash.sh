#!/bin/bash

echo_() {
    echo -e "$1"
    echo "$1" >> /tmp/toast.log
}

success() {
    echo -e "$(tput setaf 2)$1$(tput sgr0)"
    echo "$1" >> /tmp/toast.log
}

error() {
    echo -e "$(tput setaf 1)$1$(tput sgr0)"
    echo "$1" >> /tmp/toast.log
    exit 1
}

################################################################################

OS_NAME="$(uname)"
OS_FULL="$(uname -a)"
if [ "${OS_NAME}" == "Linux" ]; then
    if [ $(echo "${OS_FULL}" | grep -c "Ubuntu") -gt 0 ]; then
        OS_TYPE="Ubuntu"
    else
        OS_TYPE="generic"
    fi
elif [ "${OS_NAME}" == "Darwin" ]; then
    OS_TYPE="${OS_NAME}"
fi

SUDO=""
if [ "${HOME}" != "/root" ]; then
    SUDO="sudo"
fi

################################################################################

download() {
    _FILE="$1"
    _PATH="$2"

    if [ "${REPO}" != "" ]; then
        URL="s3://${REPO}/${_PATH}/${_FILE}"

        echo_ "download... [${URL}]"

        aws s3 cp ${URL} ./
    fi

    if [ ! -f ${_FILE} ]; then
        URL="http://repo.toast.sh/${_PATH}/${_FILE}"

        echo_ "download... [${URL}]"

        curl -O ${URL}
    fi
}

################################################################################

# s3://repo.toast.sh/elastic/logstash-5.2.1.tar.gz

NAME="elastic"

VERSION="5.2.1"

FILE="logstash-${VERSION}"

EXT="tar"

################################################################################

REPO="$1"

download "${FILE}.${EXT}" "${NAME}"

if [ ! -f ${FILE}.${EXT} ]; then
    error "Can not download : ${FILE}.${EXT}"
fi

################################################################################

tar xf ${FILE}.${EXT}

LOGSTASH_PATH="${FILE}"
LOGSTASH_HOME="/usr/local/${LOGSTASH_PATH}"

if [ ! -d ${LOGSTASH_PATH} ]; then
    error "Can not found : ${LOGSTASH_PATH}"
fi

${SUDO} rm -rf ${LOGSTASH_HOME}
${SUDO} rm -rf /usr/local/logstash

${SUDO} mv ${LOGSTASH_PATH} /usr/local/
${SUDO} ln -s ${LOGSTASH_HOME} /usr/local/logstash

rm -rf ${FILE}.${EXT}

echo_ "LOGSTASH_HOME=${LOGSTASH_HOME}"

################################################################################
