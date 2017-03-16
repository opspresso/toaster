#!/bin/bash

echo_() {
    echo "$1"
    echo "$1" >> /tmp/toast.log
}

success() {
    echo -e "$(tput setaf 2)$1$(tput sgr0)"
    echo "$1" >> /tmp/toast.log
}

inform() {
    echo -e "$(tput setaf 6)$1$(tput sgr0)"
    echo "$1" >> /tmp/toast.log
}

warning() {
    echo -e "$(tput setaf 1)$1$(tput sgr0)"
    echo "$1" >> /tmp/toast.log
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

FILE="rabbitmq-server-${VERSION}.el6.noarch"

EXT="rpm"

RABBIT_HOME="/usr/lib/rabbitmq/lib/rabbitmq_server-3.6.6"

# s3://repo.toast.sh/rabbitmq/rabbitmq-server-3.6.6-1.el6.noarch.rpm
# https://www.rabbitmq.com/releases/rabbitmq-server/v${VERSION}/rabbitmq-server-${VERSION}.el6.noarch.rpm

################################################################################

REPO="$1"

if [ "${REPO}" != "" ]; then
    URL="${REPO}/${NAME}/${FILE}.${EXT}"

    echo_ "download... [${URL}]"

    aws s3 cp ${URL} ./
fi

if [ ! -f ${FILE}.${EXT} ]; then
    warning "Can not download : ${URL}"

    URL="http://repo.toast.sh/${NAME}/${FILE}.${EXT}"

    echo_ "download... [${URL}]"

    wget -q -N ${URL}
fi

if [ ! -f ${FILE}.${EXT} ]; then
    warning "Can not download : ${URL}"
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
