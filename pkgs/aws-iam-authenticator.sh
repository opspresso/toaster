#!/bin/bash

NAME="aws-iam-authenticator"

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
        command -v ${NAME} > /dev/null || brew install ${NAME}
    else
        URL="https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/download/v${VERSION}/heptio-authenticator-aws_${VERSION}_${OS_NAME}_amd64"
        curl -L -o ${TMP}/${NAME} ${URL}
        chmod +x ${TMP}/${NAME} && sudo mv ${TMP}/${NAME} /usr/local/bin/${NAME}
    fi

    printf "${VERSION}" > ${CONFIG}/${NAME}
fi

echo "${VERSION}"
