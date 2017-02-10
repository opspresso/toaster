#!/bin/bash

OS_NAME=`uname`
if [ ${OS_NAME} != "Linux" ]; then
    echo "Not supported OS : $OS_NAME"
    exit 1
fi

################################################################################

VERSION="1.11"

EXT="tar.gz"

SUDO=""
if [ "${HOME}" != "/root" ]; then
    SUDO="sudo"
fi

################################################################################

URL1="https://nginx.org/en/download.html"
URL2=$(curl -s ${URL1} | egrep -o "\/download\/nginx-${VERSION}.(.*).${EXT}")

# /download/nginx-1.11.4.tar.gz

if [[ -z "$URL2" ]]; then
    echo "Could not get nginx url - $URL2"
    exit 1
fi

URL3=$(echo ${URL2} | cut -d "\"" -f 1)

NGINX=$(echo ${URL3} | cut -d "/" -f 3)

if [[ -z "$NGINX" ]]; then
    echo "Could not get nginx - $NGINX"
    exit 1
fi

echo "https://nginx.org/download/${NGINX}"
echo ${NGINX}

################################################################################

wget -q -N "https://nginx.org/download/${NGINX}"

tar xzf ${NGINX}

#rm -rf ${NGINX}

NGINX_DIR=$(echo ${NGINX} | egrep -o "nginx-${VERSION}.[0-9]+")

pushd ${NGINX_DIR}

# sudo yum install -y pcre-devel
# sudo yum install -y openssl-devel

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

rm -rf ${NGINX_DIR}
