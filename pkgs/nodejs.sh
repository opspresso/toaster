#!/bin/bash

NAME="nodejs"

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
        command -v node > /dev/null || brew install node
    else
        if [ "$(command -v yum)" != "" ]; then
            curl -sL https://rpm.nodesource.com/setup_${VERSION}.x | sudo bash -
            sudo yum install -y ${NAME}
        fi
        if [ "$(command -v apt)" != "" ]; then
            curl -sL https://deb.nodesource.com/setup_${VERSION}.x | sudo bash -
            sudo apt install -y ${NAME}
        fi
    fi

    printf "${VERSION}" > ${CONFIG}/${NAME}
fi

node -v | xargs
