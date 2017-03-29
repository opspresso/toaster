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

download() {
    FILE="$1"
    PATH="$2"

    if [ "${REPO}" != "" ]; then
        URL="${REPO}/${PATH}/${FILE}"

        echo_ "download... [${URL}]"

        aws s3 cp ${URL} ./
    fi

    if [ ! -f ${FILE} ]; then
        warning "Can not download : ${URL}"

        URL="http://repo.toast.sh/${PATH}/${FILE}"

        echo_ "download... [${URL}]"

        wget -q -N ${URL}
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

REPO="$1"

download "apr-1.5.2.tar.gz" "httpd"
download "apr-util-1.5.4.tar.gz" "httpd"

if [ ! -f apr-1.5.2.tar.gz ]; then
    warning "Can not download : apr-1.5.2.tar.gz"
    exit 1
fi

if [ ! -f apr-util-1.5.4.tar.gz ]; then
    warning "Can not download : apr-util-1.5.4.tar.gz"
    exit 1
fi

################################################################################

yum remove -y apr apr-docs apr-devel apr-util apr-util-devel apr-util-docs apr-util-mysql

tar xzfp apr-1.5.2.tar.gz
tar xzfp apr-util-1.5.4.tar.gz

pushd apr-1.5.2
./configure --prefix=/usr/local/apr
make && make install
popd

pushd apr-util-1.5.4
./configure --prefix=/usr/local/apr-util/ --with-apr=/usr/local/apr/
make && make install
popd

rm -rf apr-*
rm -rf apr-util-*
