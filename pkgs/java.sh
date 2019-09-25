#!/bin/bash

NAME="java"

VERSION=${1}

BUCKET="repo.opspresso.com"

OS_NAME="$(uname | awk '{print tolower($0)}')"

_prepare() {
    CONFIG=~/.config/opspresso/latest
    mkdir -p ${CONFIG} && touch ${CONFIG}/${NAME}

    TMP=/tmp/opspresso/tools
    mkdir -p ${TMP}

    _brew
}

_brew() {
    if [ "${OS_NAME}" == "darwin" ]; then
        command -v brew > /dev/null || ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    fi
}

_compare() {
    touch ${CONFIG}/${NAME}
    NOW=$(cat ${CONFIG}/${NAME} | xargs)

    if [ "${VERSION}" != "" ]; then
        NEW="${VERSION}"
    else
        NEW=$(curl -sL ${BUCKET}/latest/${NAME} | xargs)
    fi

    if [ "${NEW}" != "" ] && [ "${NEW}" != "${NOW}" ]; then
        echo "${NOW:-new} >> ${NEW}"

        VERSION="${NEW}"
    else
        VERSION=""
    fi
}

echo "================================================================================"
echo "install ${NAME} ${VERSION}..."

_prepare
_compare

if [ "${VERSION}" != "" ]; then
    if [ "${OS_NAME}" == "darwin" ]; then
        command -v java > /dev/null || HAS_JAVA=false
        if [ ! -z ${HAS_JAVA} ]; then
            brew tap caskroom/versions && brew cask install java8
        fi
    else
        if [ "$(command -v yum)" != "" ]; then
            sudo yum remove -y java-1.7.0-openjdk
            sudo yum install -y java-1.8.0-openjdk java-1.8.0-openjdk-devel
        fi
        if [ "$(command -v apt)" != "" ]; then
            sudo apt install -y openjdk-8-jdk
        fi
    fi

    printf "${VERSION}" > ${CONFIG}/${NAME}
fi

java -version 2>&1 | grep version | cut -d'"' -f2
