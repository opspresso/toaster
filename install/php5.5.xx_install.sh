#!/bin/bash


_MAIN="/usr/local/src"
histchars=

cd $_MAIN

[[ ! -f php-5.5.38.tar.gz ]] && \
    wget https://s3.ap-northeast-2.amazonaws.com/repo.yanolja.com/php/php-5.5.38.tar.gz

tar xzfp php-5.5.38.tar.gz
cd php-5.5.38

./configure --prefix=/usr/local/php \
            --with-libdir=lib64 \
            --with-apxs2=/usr/local/apache/bin/apxs \
            --with-mysql=/usr/local/mariadb \
            --with-config-file-path=/usr/local/php/lib \
            --disable-debug \
            --enable-safe-mode \
            --enable-sockets \
            --enable-mod-charset \
            --enable-sysvsem=yes \
            --enable-sysvshm=yes \
            --enable-ftp \
            --enable-magic-quotes \
            --enable-gd-native-ttf \
            --enable-inline-optimization \
            --enable-bcmath \
            --enable-sigchild \
            --enable-mbstring \
            --enable-pcntl \
            --enable-shmop \
            --with-png-dir \
            --with-zlib \
            --with-jpeg-dir \
            --with-png-dir=/usr/lib \
            --with-freetype-dir=/usr \
            --with-libxml-dir=/usr \
            --enable-exif \
            --with-gd \
            --with-ttf \
            --with-gettext \
            --with-curl \
            --with-mcrypt \
            --with-mhash \
            --with-openssl \
            --with-xmlrpc \
            --with-xsl \
            --enable-maintainer-zts

make
[[ $? -ne 0 ]] && \
    exit -1
make install
[[ $? -ne 0 ]] && \
    exit -1

sed -i 's;AddType application/x-gzip .gz .tgz;AddType application/x-gzip .gz .tgz\n    AddType application/x-httpd-php     .php\n    AddType application/x-httpd-php-source      .phps;g' /usr/local/apache/conf/httpd.conf

cd $_MAIN
wget https://s3.ap-northeast-2.amazonaws.com/repo.yanolja.com/php/php_5.ini
cp -avx $_MAIN/php_5.ini /usr/local/php/lib/php.ini


echo -ne "\n\n
#################################
 PHP-5.5.38 Install success
#################################
\n\n"