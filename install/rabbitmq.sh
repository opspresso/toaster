#!/bin/bash

echo_() {
    echo "$1"
    echo "$1" >> /tmp/toast.log
}

success() {
    echo "$(tput setaf 2)$1$(tput sgr0)"
    echo "$1" >> /tmp/toast.log
}

warning() {
    echo "$(tput setaf 1)$1$(tput sgr0)"
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

# s3://repo.toast.sh/rabbitmq/rabbitmq-server-3.6.6-1.el6.noarch.rpm

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
#URL="https://www.rabbitmq.com/releases/rabbitmq-server/v${VERSION}/rabbitmq-server-${VERSION}.el6.noarch.rpm"
#${SUDO} rpm -Uvh "${URL}"

${SUDO} rpm -Uvh ${FILE}.${EXT}

# delayed_message_exchange
DIR="/usr/lib/rabbitmq/lib/rabbitmq_server-${VERSION}/plugins/"
URL="http://www.rabbitmq.com/community-plugins/v3.6.x/rabbitmq_delayed_message_exchange-0.0.1.ez"
${SUDO} wget -q -N -P "${DIR}" "${URL}"

rm -rf ${FILE}.${EXT}
