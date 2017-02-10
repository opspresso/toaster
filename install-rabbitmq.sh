#!/bin/bash

OS_NAME=`uname`
if [ ${OS_NAME} != "Linux" ]; then
    echo "Not supported OS : $OS_NAME"
    exit 1
fi

################################################################################

VERSION="3.6.6"

SUDO=""
if [ "${HOME}" != "/root" ]; then
    SUDO="sudo"
fi

################################################################################

# erlang repo
URL="http://packages.erlang-solutions.com/erlang-solutions-1.0-1.noarch.rpm"
${SUDO} rpm -Uvh "${URL}"

# erlang, socat
${SUDO} yum install -y erlang socat

# rabbitmq-server
URL="https://www.rabbitmq.com/releases/rabbitmq-server/v${VERSION}/rabbitmq-server-${VERSION}-1.el6.noarch.rpm"
${SUDO} rpm -Uvh "${URL}"

# delayed_message_exchange
DIR="/usr/lib/rabbitmq/lib/rabbitmq_server-${VERSION}/plugins/"
URL="http://www.rabbitmq.com/community-plugins/v3.6.x/rabbitmq_delayed_message_exchange-0.0.1.ez"
${SUDO} wget -q -N -P "${DIR}" "${URL}"
