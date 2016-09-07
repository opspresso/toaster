#!/bin/bash

# root
if [ "${HOME}" == "/root" ]; then
    echo "Not supported ROOT"
    exit 1
fi

# linux
OS_NAME=`uname`
if [ ${OS_NAME} != 'Linux' ]; then
    echo "Not supported OS - $OS_NAME"
    exit 1
fi

DEV=
