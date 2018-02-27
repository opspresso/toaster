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
        URL="http://repo.toast.sh/${_PATH}/${_FILE}"

        echo_ "download... [${URL}]"

        /usr/bin/curl -O ${URL}
    fi
}

################################################################################

OS_NAME=$(uname)
if [ ${OS_NAME} != "Linux" ]; then
    warning "Not supported OS : ${OS_NAME}"
    exit 1
fi

SUDO=""
if [ "${HOME}" != "/root" ]; then
    SUDO="sudo"
fi

################################################################################

# s3://repo.toast.sh/nginx/nginx-1.13.6.tar.gz

NAME="nginx"

VERSION="1.13.6"

FILE="${NAME}-${VERSION}"

EXT="tar.gz"

################################################################################

REPO="$1"

download "${FILE}.${EXT}" "${NAME}"

if [ ! -f ${FILE}.${EXT} ]; then
    warning "Can not download : ${URL}"
    exit 1
fi

################################################################################

${SUDO} yum install -y gcc pcre pcre-devel zlib zlib-devel openssl openssl-devel

tar xzf ${FILE}.${EXT}

if [ ! -d ${FILE} ]; then
    warning "Can not found : ${FILE}"
    exit 1
fi

pushd ${FILE}

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

rm -rf ${FILE}.${EXT}
rm -rf ${FILE}
