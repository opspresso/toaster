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

        /usr/bin/wget -q -N ${URL}
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

NAME="mariadb"

VERSION="10.0.29"

FILE="${NAME}-${VERSION}"

EXT="tar.gz"

# s3://repo.toast.sh/mariadb/mariadb-10.0.29.tar.gz

################################################################################

REPO="$1"

download "${FILE}.${EXT}" "${NAME}"

if [ ! -f ${FILE}.${EXT} ]; then
    warning "Can not download : ${FILE}.${EXT}"
    exit 1
fi

################################################################################

tar xzfp ${FILE}.${EXT}

pushd ${FILE}

cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mariadb \
      -DMYSQL_DATADIR=/usr/local/maria/data \
      -DWITH_INNOBASE_STORAGE_ENGINE=1 \
      -DDEFAULT_CHARSET=utf8 \
      -DDEFAULT_COLLATION=utf8_general_ci \
      -DENABLED_LOCAL_INFILE=1 \
      -DWITH_EXTRA_CHARSETS=all \
      -DMYSQL_UNIX_ADDR=/tmp/maria.sock

make -s
${SUDO} make install

cp support-files/my-large.cnf /etc/my.cnf

popd

/usr/local/mariadb/lib/scripts/mysql_install_db --user=maria
cp -avx /usr/local/mariadb/lib /usr/local/mariadb/lib64

rm -rf ${FILE}.${EXT}
rm -rf ${FILE}
