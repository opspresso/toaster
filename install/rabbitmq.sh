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
        warning "Can not download : ${URL}"

        URL="http://repo.toast.sh/${_PATH}/${_FILE}"

        echo_ "download... [${URL}]"

        /usr/bin/wget -q -N ${URL} --show-progress
    fi
}

################################################################################

OS_NAME=`uname`
if [ ${OS_NAME} != "Linux" ]; then
    warning "Not supported OS : ${OS_NAME}"
    exit 1
fi

SUDO=""
if [ "${HOME}" != "/root" ]; then
    SUDO="sudo"
fi

################################################################################

NAME="rabbitmq"

VERSION="3.6.6-1"

FILE="${NAME}-server-${VERSION}.el6.noarch"

EXT="rpm"

RABBIT_HOME="/usr/lib/rabbitmq/lib/rabbitmq_server-3.6.6"

# s3://repo.toast.sh/rabbitmq/rabbitmq-server-3.6.6-1.el6.noarch.rpm
# https://www.rabbitmq.com/releases/rabbitmq-server/v${VERSION}/rabbitmq-server-${VERSION}.el6.noarch.rpm

################################################################################

REPO="$1"

download "${FILE}.${EXT}" "${NAME}"

if [ ! -f ${FILE}.${EXT} ]; then
    warning "Can not download : ${FILE}.${EXT}"
    exit 1
fi

################################################################################

# erlang repo
URL="http://packages.erlang-solutions.com/erlang-solutions-1.0-1.noarch.rpm"
${SUDO} rpm -Uvh "${URL}"

# erlang, socat
${SUDO} yum install -y erlang socat

# rabbitmq-server
${SUDO} rpm -Uvh ${FILE}.${EXT}

# delayed_message_exchange
URL="http://www.rabbitmq.com/community-plugins/v3.6.x/rabbitmq_delayed_message_exchange-0.0.1.ez"
${SUDO} wget -q -N -P "${RABBIT_HOME}/plugins/" "${URL}"

rm -rf ${FILE}.${EXT}
