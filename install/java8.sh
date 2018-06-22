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
        URL="repo.toast.sh/${_PATH}/${_FILE}"

        echo_ "download... [${URL}]"

        curl -LO ${URL}
    fi
}

remove() {
    if [ "${OS_TYPE}" == "Ubuntu" ]; then
        sudo apt-get remove -y $1
    else
        sudo yum remove -y $1
    fi
}

################################################################################

# s3://repo.toast.sh/java/jdk-8u152-linux-x64.rpm

REPO="$1"

NAME="java"

FILE="jdk-8u152-linux-x64.rpm"

################################################################################

if [ -f ${FILE} ]; then
    exit 0
fi

download "${FILE}" "${NAME}"

if [ ! -f ${FILE} ]; then
    error "Can not download : ${FILE}"
fi

################################################################################

remove "java-1.7.0-openjdk java-1.7.0-openjdk-headless"
remove "java-1.8.0-openjdk java-1.8.0-openjdk-headless java-1.8.0-openjdk-devel"

################################################################################

${SUDO} rpm -Uvh ${FILE}

################################################################################

FILE="local_policy.jar.bin"
download "${FILE}" "${NAME}"

if [ -f ${FILE} ]; then
    ${SUDO} mv ${FILE} /usr/java/default/jre/lib/security/local_policy.jar
fi

################################################################################

FILE="US_export_policy.jar.bin"
download "${FILE}" "${NAME}"

if [ -f ${FILE} ]; then
    ${SUDO} mv ${FILE} /usr/java/default/jre/lib/security/US_export_policy.jar
fi

################################################################################
