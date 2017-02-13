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

NAME="nginx"

VERSION="1.11.9"

FILE="nginx-${VERSION}"

EXT="tar.gz"

# s3://repo.toast.sh/nginx/nginx-1.11.9.tar.gz

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

tar xzf ${FILE}.${EXT}

pushd ${FILE}

# sudo yum install -y pcre-devel openssl-devel

./configure --prefix=/usr/local/nginx \
            --sbin-path=/usr/sbin/nginx \
            --with-http_ssl_module \
            --with-http_realip_module \
            --with-http_stub_status_module \
            --with-http_slice_module \
            --with-stream \
            --with-stream_ssl_module \
            --with-threads

make -s
${SUDO} make install

popd

rm -rf ${FILE}
