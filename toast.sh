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

# el or ubuntu
OS_FULL=`uname -a`
if [ `echo ${OS_FULL} | grep -c "Ubuntu" ` -gt 0 ]; then
    OS_TYPE="Ubuntu"
else
    if [ `echo ${OS_FULL} | grep -c "el7" ` -gt 0 ]; then
        OS_TYPE="el7"
    else
        OS_TYPE="el6"
    fi
fi

# sudo
SUDO="sudo"

################################################################################

LOGIN_URL=
TOAST_URL=
REPO_PATH=
REPO_USER=
REPO_PASS=
PHASE=
FLEET=
ID=
NAME=
HOST=
PORT=
USER=
TOKEN=
SNO=

SHELL_DIR=$(dirname $0)

CONFIG="${HOME}/.toast"
if [ -f "${CONFIG}" ]; then
    . ${CONFIG}
fi

if [ "${USER}" == "" ]; then
    USER=`whoami`
fi

################################################################################

CMD=$1

PARAM1=$2
PARAM2=$3
PARAM3=$4
PARAM4=$5
PARAM5=$6
PARAM6=$7
PARAM7=$8
PARAM8=$9

HAS_WAR="FALSE"
HAS_JAR="FALSE"

DATA_DIR="/data"
APPS_DIR="${DATA_DIR}/apps"
LOGS_DIR="${DATA_DIR}/logs"
SITE_DIR="${DATA_DIR}/site"
TEMP_DIR="/tmp/deploy"

HTTPD_VERSION="24"

NGINX="/usr/local/nginx/sbin/nginx"
NGINX_CONF_DIR="/usr/local/nginx/conf"

TOMCAT_DIR="${APPS_DIR}/tomcat8"
WEBAPP_DIR="${TOMCAT_DIR}/webapps"

################################################################################

toast() {
    case ${CMD} in
        a|auto)
            auto
            ;;
        u|update)
            update
            ;;
        c|config)
            config
            ;;
        i|init)
            init
            ;;
        t|terminate)
            terminate
            ;;
        v|version)
            version
            ;;
        b|lb)
            lb
            ;;
        d|deploy)
            deploy
            ;;
        h|health)
            health
            ;;
        s|ssh)
            conn
            ;;
        l|log)
            log
            ;;
        *)
            usage
    esac

    if [ ! -f "${CONFIG}" ]; then
        auto
    fi
}

usage() {
    echo_toast

    echo " Usage: toast {auto|update|config|init|version|deploy}"
    echo_bar
    echo_
    echo " Usage: toast auto"
    echo_
    echo " Usage: toast update"
    echo_
    echo " Usage: toast config"
    echo " Usage: toast config auto"
    echo " Usage: toast config save"
    echo " Usage: toast config info"
    echo_
    echo " Usage: toast init"
    echo " Usage: toast init master"
    echo " Usage: toast init slave"
    echo " Usage: toast init httpd"
    echo " Usage: toast init nginx"
    echo " Usage: toast init php5"
    echo " Usage: toast init php7"
    echo " Usage: toast init node"
    echo " Usage: toast init java"
    echo " Usage: toast init tomcat"
    echo " Usage: toast init mysql"
    echo " Usage: toast init redis"
    echo_
    echo " Usage: toast version"
    echo " Usage: toast version next"
    echo " Usage: toast version save"
    echo_
    echo " Usage: toast lb"
    echo " Usage: toast lb up"
    echo " Usage: toast lb down"
    echo_
    echo " Usage: toast deploy"
    echo " Usage: toast deploy vhost"
    echo " Usage: toast deploy fleet"
    echo " Usage: toast deploy project"
    echo_
    echo " Usage: toast health"
    echo_
    echo " Usage: toast terminate"
    echo_
    echo_bar
}

auto() {
    echo_toast

    prepare

    update

    config_auto
    config_save
    config_info
    config_cron

    init_profile
    init_hosts
    init_aws
    init_slave
    init_epel
    init_auto

    deploy_fleet
    deploy_vhost
}

update() {
    self_info
    self_update

    #service_update
}

init() {
    case ${PARAM1} in
        master)
            init_master
            ;;
        slave)
            init_slave
            ;;
        aws)
            init_aws
            ;;
        apache|httpd)
            init_httpd
            ;;
        nginx)
            init_nginx
            ;;
        php5|php55)
            init_php 55
            ;;
        php56)
            init_php 56
            ;;
        php7|php70)
            init_php 70
            ;;
        node|node4)
            init_node4
            ;;
        java|java8)
            init_java8
            ;;
        tomcat|tomcat8)
            init_tomcat8
            ;;
        mysql)
            init_mysql56
            ;;
        redis)
            init_redis
            ;;
        rabbitmq)
            init_rabbitmq
            ;;
        *)
            self_info
            init_auto
    esac
}

config() {
    case ${PARAM1} in
        auto)
            config_auto
            config_save
            ;;
        save)
            config_save
            ;;
        cron)
            config_cron
            ;;
        info|echo|show)
            ;;
        *)
            config_read
            config_save
    esac

    config_info
}

version() {
    version_parse

    case ${PARAM1} in
        next)
            version_next
            ;;
        save)
            version_save
            ;;
        remove)
            version_remove
            ;;
    esac
}

lb() {
    case ${PARAM1} in
        u|up)
            lb_up
            ;;
        d|down)
            lb_down
            ;;
    esac
}

deploy() {
    case ${PARAM1} in
        v|vhost)
            deploy_vhost
            ;;
        f|fleet)
            deploy_fleet
            ;;
        p|project)
            deploy_project
            ;;
        *)
            deploy_fleet
            deploy_vhost
    esac
}

health() {
    if [ "${SNO}" == "" ]; then
        echo "Not configured server. [${SNO}]"
        return 1
    fi

    echo "server health..."

    URL="${TOAST_URL}/server/health/${SNO}"
    RES=`curl -s ${URL}`

    echo "${RES}"
}

terminate() {
    if [ "${PARAM1}" == "" ]; then
        echo "instance-id does not exist."
        return 1
    fi

    aws ec2 terminate-instances --instance-ids ${PARAM1} --region ap-northeast-2
}

log() {
    case ${PARAM1} in
        t|tomcat)
            log_tomcat
            ;;
        w|web)
            log_webapp
            ;;
        *)
            log_cron
    esac
}

################################################################################

self_info() {
    echo_bar
    echo "OS    : ${OS_NAME} ${OS_TYPE}"
    echo "HOME  : ${HOME}"
    echo "NAME  : ${NAME}"
    echo "PHASE : ${PHASE}"
    echo "FLEET : ${FLEET}"
    echo_bar
}

self_update() {
    pushd "${SHELL_DIR}"
    git pull
    popd
}

prepare() {
    service_install git
    service_install gcc
    service_install curl
    service_install wget
    service_install unzip

    make_dir ${DATA_DIR}
    make_dir ${LOGS_DIR}
    make_dir ${TEMP_DIR}

    make_dir "${HOME}/.m2"
    make_dir "${HOME}/.ssh"

    # hosts
    copy ${SHELL_DIR}/package/linux/hosts.txt /etc/hosts 644

    # timezone
    if [ ! -f "${HOME}/.toast_time" ]; then
        ${SUDO} rm -rf /etc/localtime
        ${SUDO} ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime

        touch "${HOME}/.toast_time"
    fi

    # i18n & selinux
    if [ "${OS_TYPE}" != "Ubuntu" ]; then
        copy ${SHELL_DIR}/package/linux/i18n.txt /etc/sysconfig/i18n 644
        copy ${SHELL_DIR}/package/linux/selinux.txt /etc/selinux/config 644
    fi

    if [ -f "/usr/sbin/setenforce" ]; then
        ${SUDO} setenforce 0
    fi

    # settings.xml
    if [ "${REPO_USER}" != "" ]; then
        TARGET_FILE="${HOME}/.m2/settings.xml"
        copy "${SHELL_DIR}/package/m2/settings.xml" "${TARGET_FILE}" 644

        TEMP_FILE="${TEMP_DIR}/settings.tmp"
        sed "s/REPO_USER/$REPO_USER/g" ${TARGET_FILE} > ${TEMP_FILE} && copy ${TEMP_FILE} ${TARGET_FILE}
        sed "s/REPO_PASS/$REPO_PASS/g" ${TARGET_FILE} > ${TEMP_FILE} && copy ${TEMP_FILE} ${TARGET_FILE}
    fi

    # ssh config
    TARGET_FILE="${HOME}/.ssh/config"
    copy "${SHELL_DIR}/package/ssh/config" "${TARGET_FILE}" 600
}

login() {
    echo "Please input yanolja id."
    read YAJA_ID

    echo "Please input yanolja password."
    read YAJA_PW

    echo "yanolja login..."

    RES=`curl -s --data "id=${YAJA_ID}&passwd=${YAJA_PW}" ${LOGIN_URL}`
    ARR=(${RES})

    if [ "${ARR[0]}" != "OK" ]; then
        echo "Server Error. [${LOGIN_URL}][${RES}]"
    else
        TOKEN="${ARR[1]}"
    fi
}

config_auto() {
    ID=`curl -s http://instance-data/latest/meta-data/instance-id`

    NAME=`hostname`

    ARR=(`${SUDO} netstat -anp | grep LISTEN | grep sshd | grep "0\.0\.0\.0"`)
    PORT=`echo "${ARR[3]}" | cut -d ":" -f 2`
}

config_read() {
    if [ "${TOKEN}" == "" ]; then
        login
    else
        echo "Do you want yanolja login? [yes/no] [default:no]"
        read LOGIN_YN
        if [ "${LOGIN_YN}" == "yes" ]; then
            login
        fi
    fi

    echo "Please input toast url. [default:${TOAST_URL}]"
    read READ_TOAST_URL
    if [ "${READ_TOAST_URL}" != "" ]; then
        TOAST_URL=${READ_TOAST_URL}
    fi

    echo "Please input repository path. [default:${REPO_PATH}]"
    read READ_REPO_PATH
    if [ "${READ_REPO_PATH}" != "" ]; then
        REPO_PATH=${READ_REPO_PATH}
    fi

    echo "Please input server phase. [default:${PHASE}]"
    read READ_PHASE
    if [ "${READ_PHASE}" != "" ]; then
        PHASE=${READ_PHASE}
    fi

    echo "Please input server fleet. [default:${FLEET}]"
    read READ_FLEET
    if [ "${READ_FLEET}" != "" ]; then
        FLEET=${READ_FLEET}
    fi

    echo "Please input server name. [default:${NAME}]"
    read READ_NAME
    if [ "${READ_NAME}" != "" ]; then
        NAME=${READ_NAME}
    fi

    echo "Please input server host. [default:${HOST}]"
    read READ_HOST
    if [ "${READ_HOST}" != "" ]; then
        HOST=${READ_HOST}
    fi

    echo "Please input server port. [default:${PORT}]"
    read READ_PORT
    if [ "${READ_PORT}" != "" ]; then
        PORT=${READ_PORT}
    fi

    echo "Please input server user. [default:${USER}]"
    read READ_USER
    if [ "${READ_USER}" != "" ]; then
        USER=${READ_USER}
    fi
}

config_info() {
    if [ ! -f "${CONFIG}" ]; then
        echo "Not exist file. [${CONFIG}]"
        return 1
    fi

    echo_bar
    cat ${CONFIG}
    echo_bar
}

config_save() {
    echo "server save..."

    URL="${TOAST_URL}/server/config"
    RES=`curl -s --data "token=${TOKEN}&no=${SNO}&phase=${PHASE}&fleet=${FLEET}&name=${NAME}&host=${HOST}&port=${PORT}&user=${USER}&id=${ID}" ${URL}`
    ARR=(${RES})

    if [ "${ARR[0]}" != "OK" ]; then
        echo "Server Error. [${URL}][${RES}]"
    fi

    if [ "${ARR[1]}" != "" ]; then
        SNO="${ARR[1]}"
    fi
    if [ "${ARR[2]}" != "" ]; then
        HOST="${ARR[2]}"
    fi

    echo "# yanolja toast config" > ${CONFIG}
    echo "LOGIN_URL=\"${LOGIN_URL}\"" >> ${CONFIG}
    echo "TOAST_URL=\"${TOAST_URL}\"" >> ${CONFIG}
    echo "REPO_PATH=\"${REPO_PATH}\"" >> ${CONFIG}
    echo "REPO_USER=\"${REPO_USER}\"" >> ${CONFIG}
    echo "REPO_PASS=\"${REPO_PASS}\"" >> ${CONFIG}
    echo "PHASE=\"${PHASE}\"" >> ${CONFIG}
    echo "FLEET=\"${FLEET}\"" >> ${CONFIG}
    echo "ID=\"${ID}\"" >> ${CONFIG}
    echo "NAME=\"${NAME}\"" >> ${CONFIG}
    echo "HOST=\"${HOST}\"" >> ${CONFIG}
    echo "PORT=\"${PORT}\"" >> ${CONFIG}
    echo "USER=\"${USER}\"" >> ${CONFIG}
    echo "TOKEN=\"${TOKEN}\"" >> ${CONFIG}
    echo "SNO=${SNO}" >> ${CONFIG}

    chmod 644 ${CONFIG}

    echo "${RES}"
}

config_cron() {
    TEMP_FILE="${TEMP_DIR}/toast-cron.tmp"

    echo "# yanolja cron" > ${TEMP_FILE}
    echo "* 1 * * * ${SHELL_DIR}/toast.sh log > /dev/null 2>&1" >> ${TEMP_FILE}
    echo "* 5 * * * ${SHELL_DIR}/toast.sh update > /dev/null 2>&1" >> ${TEMP_FILE}
    echo "* * * * * ${SHELL_DIR}/toast.sh health > /dev/null 2>&1" >> ${TEMP_FILE}

    crontab ${TEMP_FILE}

    echo_bar
    crontab -l
    echo_bar
}

init_hosts() {
    URL="${TOAST_URL}/phase/hosts/${PHASE}"
    RES=`curl -s --data "token=${TOKEN}" ${URL}`

    if [ "${RES}" != "" ]; then
        ${SUDO} echo "# yanolja hosts" > /etc/hosts
        ${SUDO} echo "127.0.0.1 ${NAME}" >> /etc/hosts
        ${SUDO} echo "127.0.0.1 localhost localhost.localdomain" >> /etc/hosts
        ${SUDO} echo "${RES}" >> /etc/hosts
    fi
}

init_profile() {
    # bashrc
    BASHRC="${HOME}/.bashrc"

    if [ `cat ${BASHRC} | grep -c "toast_profile"` -eq 0 ]; then
        echo "" >> ${BASHRC}
        echo "# toast_profile" >> ${BASHRC}
        echo "if [ -f ~/.toast_profile ]; then" >> ${BASHRC}
        echo "  . ~/.toast_profile" >> ${BASHRC}
        echo "fi" >> ${BASHRC}
    fi

    # toast_profile
    URL="${TOAST_URL}/phase/profile/${PHASE}"
    RES=`curl -s --data "token=${TOKEN}" ${URL}`

    if [ "${RES}" != "" ]; then
        ${SUDO} echo "${RES}" > ${HOME}/.toast_profile
    fi

    # toast config
    if [ ! -f "${CONFIG}" ]; then
        copy "${SHELL_DIR}/package/toast.txt" ${CONFIG} 644

        . ${CONFIG}
    fi

    if [ "${PARAM1}" != "" ]; then
        PHASE="${PARAM1}"
        echo "PHASE=${PHASE}" >> ${CONFIG}
    fi
    if [ "${PARAM2}" != "" ]; then
        FLEET="${PARAM2}"
        echo "FLEET=${FLEET}" >> ${CONFIG}
    fi
}

init_aws() {
    make_dir "${HOME}/.aws"

    copy ${SHELL_DIR}/package/aws/config.txt ${HOME}/.aws/config 600
    copy ${SHELL_DIR}/package/aws/credentials.txt ${HOME}/.aws/credentials 600

    TEMP_FILE="${TEMP_DIR}/toast-credentials.tmp"
    DEST_FILE="${HOME}/.aws/credentials"

    URL="${TOAST_URL}/config/key/aws_access_key_id"
    RES=`curl -s --data "token=${TOKEN}" ${URL}`
    if [ "${RES}" != "" ]; then
        sed "s/AWS_ACCESS_KEY/$RES/g" ${DEST_FILE} > ${TEMP_FILE} && copy ${TEMP_FILE} ${DEST_FILE}
    fi

    URL="${TOAST_URL}/config/key/aws_secret_access_key"
    RES=`curl -s --data "token=${TOKEN}" ${URL}`
    if [ "${RES}" != "" ]; then
        sed "s/AWS_SECRET_KEY/$RES/g" ${DEST_FILE} > ${TEMP_FILE} && copy ${TEMP_FILE} ${DEST_FILE}
    fi

    if [ ! -f "/usr/bin/aws" ]; then
        if [ ! -f "${HOME}/.toast_awscli" ]; then
            echo "init aws cli..."

            wget -q -N "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip"
            unzip awscli-bundle.zip
            sudo ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws

            rm -rf awscli-bundle
            rm -rf awscli-bundle.zip

            touch "${HOME}/.toast_awscli"
        fi
    fi

    echo_bar
    aws --version
    echo_bar
}

init_master() {
    # rsa private key
    ID_RSA="${HOME}/.ssh/id_rsa"
    touch ${ID_RSA}

    URL="${TOAST_URL}/config/key/rsa_private_key"
    RES=`curl -s --data "token=${TOKEN}" ${URL}`

    if [ "${RES}" != "" ]; then
        echo "${RES}" > ${ID_RSA}
        chmod 600 ${ID_RSA}
    fi

    # rsa public key
    ID_RSA_PUB="${HOME}/.ssh/id_rsa.pub"
    touch ${ID_RSA_PUB}

    URL="${TOAST_URL}/config/key/rsa_public_key"
    RES=`curl -s --data "token=${TOKEN}" ${URL}`

    if [ "${RES}" != "" ]; then
        echo "${RES}" > ${ID_RSA_PUB}
        chmod 644 ${ID_RSA_PUB}
    fi
}

init_slave() {
    AUTH_KEYS="${HOME}/.ssh/authorized_keys"
    touch ${AUTH_KEYS}

    if [ `cat ${AUTH_KEYS} | grep -c "toast@yanolja.in"` -eq 0 ]; then
        URL="${TOAST_URL}/config/key/rsa_public_key"
        RES=`curl -s --data "token=${TOKEN}" ${URL}`

        if [ "${RES}" != "" ]; then
            echo "${RES}" >> ${AUTH_KEYS}
            chmod 700 ${AUTH_KEYS}
        fi
    fi
}

init_auto() {
    URL="${TOAST_URL}/fleet/apps/${PHASE}/${FLEET}"
    RES=`curl -s --data "token=${TOKEN}" ${URL}`
    ARR=(${RES})

    for i in "${ARR[@]}"; do
        case "$i" in
            apache|httpd)
                init_httpd
                ;;
            nginx)
                init_nginx
                ;;
            php5|php55)
                init_php 55
                ;;
            php56)
                init_php 56
                ;;
            php7|php70)
                init_php 70
                ;;
            node|node4)
                init_node4
                ;;
            java|java8)
                init_java8
                ;;
            tomcat|tomcat8)
                init_tomcat8
                ;;
            mysql55)
                init_mysql55
                ;;
            mysql|mysql56)
                init_mysql56
                ;;
            redis)
                init_redis
                ;;
            rabbitmq)
                init_rabbitmq
                ;;
        esac
    done
}

init_epel() {
    if [ "${OS_TYPE}" == "Ubuntu" ]; then
        return 1
    fi

    if [ -f "${HOME}/.toast_epel" ]; then
        return 1
    fi

    if [ ! -f "/usr/bin/yum-config-manager" ]; then
        service_install yum-utils
    fi

    if [ "${OS_TYPE}" == "el7" ]; then
        ${SUDO} rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
    else
        ${SUDO} rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm
    fi

    ${SUDO} yum-config-manager --enable epel

    touch "${HOME}/.toast_epel"
}

init_webtatic() {
    if [ "${OS_TYPE}" == "Ubuntu" ]; then
        return 1
    fi

    if [ -f "${HOME}/.toast_webtatic" ]; then
        return 1
    fi

    status=`${SUDO} yum list | grep php56 | wc -l | awk '{print $1}'`

    if [ ${status} -lt 1 ]; then
        if [ "${OS_TYPE}" == "el7" ]; then
            ${SUDO} rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
        else
            ${SUDO} rpm -Uvh https://mirror.webtatic.com/yum/el6/latest.rpm
        fi
    fi

    touch "${HOME}/.toast_webtatic"
}

init_httpd() {
    if [ ! -f "${HOME}/.toast_httpd" ]; then
        echo "init httpd..."

        if [ "${OS_TYPE}" == "Ubuntu" ]; then
            service_install apache2

            HTTPD_VERSION="ubuntu"
        else
            status=`${SUDO} yum list | grep httpd24 | wc -l | awk '{print $1}'`

            if [ ${status} -ge 1 ]; then
                service_install httpd24
            else
                service_install httpd
            fi

            VERSION=$(httpd -version | egrep -o "Apache\/2.4")

            if [ "${VERSION}" != "" ]; then
                HTTPD_VERSION="24"
            else
                HTTPD_VERSION="22"
            fi
        fi

        if [ "${OS_TYPE}" == "Ubuntu" ]; then
            service_ctl apache2 start on
        else
            service_ctl httpd start on
        fi

        echo "HTTPD_VERSION=${HTTPD_VERSION}" > "${HOME}/.toast_httpd"
    fi

    if [ -d "/var/www/html" ]; then
        copy "${SHELL_DIR}/package/health.txt" "/var/www/html/index.html"
        copy "${SHELL_DIR}/package/health.txt" "/var/www/html/health.html"
    fi

    make_dir "${SITE_DIR}"
    make_dir "${SITE_DIR}/files" 777
    make_dir "${SITE_DIR}/upload" 777

    echo_bar
    if [ "${OS_TYPE}" == "Ubuntu" ]; then
        apache2 -version
    else
        httpd -version
    fi
    echo_bar
}

init_nginx () {
    if [ ! -f "${HOME}/.toast_nginx" ]; then
        echo "init nginx..."

        service_install nginx

        service_ctl nginx start on

        touch "${HOME}/.toast_nginx"
    fi

    if [ -d "/usr/share/nginx/html" ]; then
        copy "${SHELL_DIR}/package/health.txt" "/usr/share/nginx/html/index.html"
        copy "${SHELL_DIR}/package/health.txt" "/usr/share/nginx/html/health.html"
    fi

    make_dir "${SITE_DIR}"
    make_dir "${SITE_DIR}/files" 777
    make_dir "${SITE_DIR}/upload" 777

    echo_bar
    ${NGINX} -v
    echo_bar
}

init_php() {
    if [ ! -f "${HOME}/.toast_php" ]; then
        if [ "${OS_TYPE}" == "Ubuntu" ]; then
            VERSION=""

            echo "init php${VERSION}..."

            service_install "php${VERSION} php${VERSION}-mysql php${VERSION}-mcrypt php${VERSION}-gd"
        else
            init_webtatic

            VERSION="$1"

            echo "init php${VERSION}..."

            status=`${SUDO} yum list | grep php${VERSION}w | wc -l | awk '{print $1}'`

            if [ ${status} -ge 1 ]; then
                service_install "php${VERSION}w php${VERSION}w-mysqlnd php${VERSION}w-mcrypt php${VERSION}w-gd php${VERSION}w-mbstring"
            else
                service_install "php${VERSION} php${VERSION}-mysqlnd php${VERSION}-mcrypt php${VERSION}-gd php${VERSION}-mbstring"
            fi
        fi

        init_php_ini

        echo "PHP_VERSION=${VERSION}" > "${HOME}/.toast_php"
    fi

    echo_bar
    if [ "${OS_TYPE}" == "Ubuntu" ]; then
        php -v
    else
        php -version
    fi
    echo_bar
}

init_node4() {
    if [ ! -f "${HOME}/.toast_node" ]; then
        echo "init node..."

        ${SHELL_DIR}/install-node.sh

        NODE_HOME=$(dirname $(dirname $(readlink -f $(which node))))

        add_env "NODE_HOME" "${NODE_HOME}"

        echo "NODE_HOME=${NODE_HOME}"

        touch "${HOME}/.toast_node"
    fi

    echo_bar
    echo "node version `node -v`"
    echo "npm version `npm -v`"
    echo_bar
}

init_java8() {
    if [ ! -f "${HOME}/.toast_java" ]; then
        echo "init java..."

        ${SHELL_DIR}/install-java.sh

        JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))

        add_env "JAVA_HOME" "${JAVA_HOME}"
        add_env "CATALINA_OPTS" "-Dproject.profile=${PHASE}"

        echo "JAVA_HOME=${JAVA_HOME}"

        copy "${SHELL_DIR}/package/jce8/local_policy.jar.bin" "${JAVA_HOME}/jre/lib/security/local_policy.jar"
        copy "${SHELL_DIR}/package/jce8/US_export_policy.jar.bin" "${JAVA_HOME}/jre/lib/security/US_export_policy.jar"

        touch "${HOME}/.toast_java"
    fi

    make_dir "${APPS_DIR}"

    echo_bar
    java -version
    echo_bar
}

init_tomcat8() {
    if [ ! -f "${HOME}/.toast_tomcat" ]; then
        echo "init tomcat..."

        make_dir "${APPS_DIR}"

        ${SHELL_DIR}/install-tomcat.sh "${APPS_DIR}"

        touch "${HOME}/.toast_tomcat"
    fi
}

init_mysql55() {
    if [ ! -f "${HOME}/.toast_mysql" ]; then
        echo "init mysql55..."

        service_install mysql55-server

        service_ctl mysqld start on

        touch "${HOME}/.toast_mysql"
    fi
}

init_mysql56() {
    if [ ! -f "${HOME}/.toast_mysql" ]; then
        echo "init mysql56..."

        service_install mysql56-server

        service_ctl mysqld start on

        touch "${HOME}/.toast_mysql"
    fi
}

init_redis() {
    if [ ! -f "${HOME}/.toast_redis" ]; then
        echo "init redis..."

        service_install redis

        service_ctl redis start on

        touch "${HOME}/.toast_redis"
    fi
}

init_rabbitmq() {
    if [ ! -f "${HOME}/.toast_rabbitmq" ]; then
        echo "init rabbitmq..."

        #wget -q -N -P "${HOME}" https://packages.erlang-solutions.com/erlang/esl-erlang/FLAVOUR_1_general/esl-erlang_19.0~centos~6_amd64.rpm
        #wget -q -N -P "${HOME}" https://www.rabbitmq.com/releases/rabbitmq-server/v3.6.4/rabbitmq-server-3.6.4-1.noarch.rpm

        service_install rabbitmq-server

        service_ctl rabbitmq-server restart on

        touch "${HOME}/.toast_rabbitmq"
    fi
}

init_munin() {
    if [ ! -f "${HOME}/.toast_munin" ]; then
        echo "init munin..."

        service_install munin

        service_ctl munin-node restart on

        touch "${HOME}/.toast_munin"
    fi
}

init_php_ini() {
    if [ "${OS_TYPE}" == "Ubuntu" ]; then
        PHP_INI="/etc/php5/apache2/php.ini"

        if [ ! -f ${PHP_INI} ]; then
            PHP_INI="/etc/php/7.0/apache2/php.ini"
        fi
    else
        PHP_INI="/etc/php.ini"
    fi

    if [ -f ${PHP_INI} ]; then
        TEMP_FILE="${TEMP_DIR}/toast-php-ini.tmp"

        # short_open_tag = On
        sed "s/short\_open\_tag\ \=\ Off/short\_open\_tag\ \=\ On/g" ${PHP_INI} > ${TEMP_FILE}
        copy ${TEMP_FILE} ${PHP_INI}

        # date.timezone = Asia/Seoul
        sed "s/\;date\.timezone\ \=/date\.timezone\ \=\ Asia\/Seoul/g" ${PHP_INI} > ${TEMP_FILE}
        copy ${TEMP_FILE} ${PHP_INI}
    fi
}

version_parse() {
    DEST_FILE="./pom.xml"

    if [ -f "${DEST_FILE}" ]; then
        echo "Not exist file. [${DEST_FILE}]"
        return 1
    fi

    ARR_GROUP=($(cat ${DEST_FILE} | grep -oP '(?<=groupId>)[^<]+'))
    ARR_ARTIFACT=($(cat ${DEST_FILE} | grep -oP '(?<=artifactId>)[^<]+'))
    ARR_VERSION=($(cat ${DEST_FILE} | grep -oP '(?<=version>)[^<]+'))

    if [ "${ARR_GROUP[0]}" == "" ]; then
        echo "groupId does not exist. [${ARR_GROUP[0]}]"
        exit 1
    fi
    if [ "${ARR_ARTIFACT[0]}" == "" ]; then
        echo "artifactId does not exist. [${ARR_ARTIFACT[0]}]"
        exit 1
    fi

    echo "groupId=${ARR_GROUP[0]}"
    echo "artifactId=${ARR_ARTIFACT[0]}"
    echo "version=${ARR_VERSION[0]}"

    GROUP_ID=${ARR_GROUP[0]}
    ARTIFACT_ID=${ARR_ARTIFACT[0]}
    VERSION=${ARR_VERSION[0]}

    GROUP_PATH=`echo "${GROUP_ID}" | sed "s/\./\//"`
}

version_next() {
    if [ "${ARTIFACT_ID}" == "" ]; then
        echo "Not set artifact_id. [${ARTIFACT_ID}]"
        return 1
    fi

    echo "version get..."

    URL="${TOAST_URL}/version/latest/${ARTIFACT_ID}"
    RES=`curl -s --data "token=${TOKEN}" ${URL}`
    ARR=(${RES})

    if [ "${ARR[0]}" != "OK" ]; then
        echo "Server Error. [${URL}][${RES}]"
        return 1
    fi

    NEXT_VERSION="${ARR[1]}"

    echo "${NEXT_VERSION}"

    VER1="<version>[\.0-9a-zA-Z]\+<\/version>"
    VER2="<version>${NEXT_VERSION}<\/version>"

    TEMP_FILE="${TEMP_DIR}/toast-pom.tmp"

    if [ -f ${DEST_FILE} -a -r ${DEST_FILE} ]; then
        sed "s/$VER1/$VER2/;10q;" ${DEST_FILE} > ${TEMP_FILE}
        sed "1,10d" ${DEST_FILE} >> ${TEMP_FILE}

        cp -rf ${TEMP_FILE} ${DEST_FILE}
    fi

    VERSION=NEXT_VERSION
}

version_save() {
    if [ "${ARTIFACT_ID}" == "" ]; then
        echo "Not set artifact_id. [${ARTIFACT_ID}]"
        return 1
    fi

    echo "version save..."

    if [ "${REPO_USER}" == "s3" ]; then
        aws s3 sync ~/.m2/repository/${GROUP_PATH}/${ARTIFACT_ID}/ ${REPO_PATH}/${GROUP_PATH}/${ARTIFACT_ID}/
    fi

    URL="${TOAST_URL}/version/build/${ARTIFACT_ID}/${VERSION}"
    RES=`curl -s --data "token=${TOKEN}" ${URL}`
    ARR=(${RES})

    if [ "${ARR[0]}" != "OK" ]; then
        echo "Server Error. [${URL}][${RES}]"
    else
        echo "${ARR[1]}"
    fi
}

version_remove() {
    echo "version remove..."

    GROUP_PATH=`echo "${GROUP_ID}" | sed "s/\./\//"`

    if [ "${REPO_USER}" == "s3" ]; then
        aws s3 rm ${REPO_PATH}/${GROUP_PATH}/${ARTIFACT_ID}/${VERSION} --recursive
    fi

    rm -rf ~/.m2/repository/${GROUP_PATH}/${ARTIFACT_ID}/${VERSION}
}

lb_up() {
    if [ ! -d ${NGINX_CONF_DIR} ]; then
        echo "not found nginx conf dir. [${NGINX_CONF_DIR}]"
        return 1
    fi

    echo "lb up... ${PARAM2}"

    TEMP_FILE="${TEMP_DIR}/toast-nginx.tmp"
    NGINX_CONF="${NGINX_CONF_DIR}/nginx.conf"

    CONF1="\#server\s$PARAM2\:80"
    CONF2=" server $PARAM2:80"

    sed "s/$CONF1/$CONF2/g" ${NGINX_CONF} > ${TEMP_FILE} && copy ${TEMP_FILE} ${NGINX_CONF}
    cat ${NGINX_CONF} | grep ":80"

    service_ctl nginx reload
}

lb_down() {
    if [ ! -d ${NGINX_CONF_DIR} ]; then
        echo "not found nginx conf dir. [${NGINX_CONF_DIR}]"
        return 1
    fi

    echo "lb down... ${PARAM2}"

    TEMP_FILE="${TEMP_DIR}/toast-nginx.tmp"
    NGINX_CONF="${NGINX_CONF_DIR}/nginx.conf"

    CONF1="\sserver\s$PARAM2\:80"
    CONF2="#server $PARAM2:80"

    sed "s/$CONF1/$CONF2/g" ${NGINX_CONF} > ${TEMP_FILE} && copy ${TEMP_FILE} ${NGINX_CONF}
    cat ${NGINX_CONF} | grep ":80"

    service_ctl nginx reload
}

deploy_lb() {
    echo_bar

    echo_bar
}

deploy_vhost() {
    if [ "${OS_TYPE}" == "Ubuntu" ]; then
        HTTPD_CONF_DIR="/etc/apache2/sites-enabled"
    else
        HTTPD_CONF_DIR="/etc/httpd/conf.d"
    fi

    if [ ! -d ${HTTPD_CONF_DIR} ]; then
        echo "not found httpd conf dir. [${HTTPD_CONF_DIR}]"
        return 1
    fi

    echo_bar
    echo "download vhost..."

    VHOST_LIST="${TEMP_DIR}/${FLEET}"
    rm -rf ${VHOST_LIST}

    URL="${TOAST_URL}/target/vhost/${PHASE}/${FLEET}"
    wget -q -N --post-data "token=${TOKEN}" -P "${TEMP_DIR}" "${URL}"

    if [ -f ${VHOST_LIST} ]; then
        echo "placement vhost..."

        ${SUDO} rm -rf ${HTTPD_CONF_DIR}/localhost*
        ${SUDO} rm -rf ${HTTPD_CONF_DIR}/toast*

        TOAST_APACHE="${HOME}/.toast_httpd"
        if [ -f "${TOAST_APACHE}" ]; then
            . ${TOAST_APACHE}
        fi
        if [ "${HTTPD_VERSION}" == "" ]; then
            HTTPD_VERSION="24"
        fi

        echo "httpd version [${HTTPD_VERSION}]"

        # localhost
        TEMPLATE="${SHELL_DIR}/package/vhost/${HTTPD_VERSION}/localhost.conf"
        if [ -f "${TEMPLATE}" ]; then
            copy "${TEMPLATE}" "${HTTPD_CONF_DIR}/localhost.conf" 644
        fi

        # vhost
        TEMPLATE="${SHELL_DIR}/package/vhost/${HTTPD_VERSION}/vhost.conf"
        TEMP_FILE="${TEMP_DIR}/toast-vhost.tmp"

        while read line
        do
            TARGET=(${line})

            DOM="${TARGET[0]}"

            make_dir "${SITE_DIR}/${DOM}"

            DEST_FILE="${HTTPD_CONF_DIR}/toast-${DOM}.conf"

            echo "--> ${DEST_FILE}"

            # vhost
            sed "s/DOM/$DOM/g" ${TEMPLATE} > ${TEMP_FILE} && copy ${TEMP_FILE} ${DEST_FILE}
        done < ${VHOST_LIST}

        if [ "${OS_TYPE}" == "Ubuntu" ]; then
            service_ctl apache2 graceful
        else
            service_ctl httpd graceful
        fi
    fi

    echo_bar
}

deploy_project() {
    # "deploy project com.yanolja yanolja.deploy 0.0.2 php deploy.yanolja.com"

    GROUP_ID="${PARAM2}"
    ARTIFACT_ID="${PARAM3}"
    VERSION="${PARAM4}"
    TYPE="${PARAM5}"
    DOMAIN="${PARAM6}"

    GROUP_PATH=`echo "${GROUP_ID}" | sed "s/\./\//"`

    PACKAGING="${TYPE}"
    if [ "${PACKAGING}" == "war" ]; then
        DEPLOY_PATH="${WEBAPP_DIR}"
    fi
    if [ "${PACKAGING}" == "jar" ]; then
        DEPLOY_PATH="${APPS_DIR}"
    fi
    if [ "${PACKAGING}" == "php" ]; then
        PACKAGING="war"
        DEPLOY_PATH="${SITE_DIR}/${DOMAIN}"
    fi

    FILENAME="${ARTIFACT_ID}-${VERSION}.${PACKAGING}"
    FILEPATH="${TEMP_DIR}/${FILENAME}"

    UNZIP_DIR="${TEMP_DIR}/${ARTIFACT_ID}"

    echo_bar
    echo "download..."

    download

    tomcat_stop

    echo "placement..."

    placement

    tomcat_start

    echo_bar
}

deploy_fleet() {
    # "deploy fleet"

    echo_bar
    echo "download target..."

    TARGET_FILE="${TEMP_DIR}/${FLEET}"
    rm -rf ${TARGET_FILE}

    URL="${TOAST_URL}/target/deploy/${PHASE}/${FLEET}"
    wget -q -N --post-data "token=${TOKEN}" -P "${TEMP_DIR}" "${URL}"

    if [ -f ${TARGET_FILE} ]; then
        echo "download..."

        while read line
        do
            TARGET=(${line})

            deploy_value

            download
        done < ${TARGET_FILE}

        tomcat_stop
        process_stop_all

        echo "placement..."

        while read line
        do
            TARGET=(${line})

            deploy_value

            placement
        done < ${TARGET_FILE}

        tomcat_start
    fi

    echo_bar
}

deploy_value() {
    RANDOM="${TARGET[0]}"
    GROUP_ID="${TARGET[1]}"
    ARTIFACT_ID="${TARGET[2]}"
    VERSION="${TARGET[3]}"
    TYPE="${TARGET[4]}"
    DOMAIN="${TARGET[5]}"

    GROUP_PATH=`echo "${GROUP_ID}" | sed "s/\./\//"`

    PACKAGING="${TYPE}"
    if [ "${PACKAGING}" == "war" ]; then
        DEPLOY_PATH="${WEBAPP_DIR}"
    fi
    if [ "${PACKAGING}" == "jar" ]; then
        DEPLOY_PATH="${APPS_DIR}"
    fi
    if [ "${PACKAGING}" == "php" ]; then
        PACKAGING="war"
        DEPLOY_PATH="${SITE_DIR}/${DOMAIN}"
    fi

    FILENAME="${ARTIFACT_ID}-${VERSION}.${PACKAGING}"
    FILEPATH="${TEMP_DIR}/${FILENAME}"

    UNZIP_DIR="${TEMP_DIR}/${RANDOM}"
}

download() {
    SOURCE="${REPO_PATH}/${GROUP_PATH}/${ARTIFACT_ID}/${VERSION}/${FILENAME}"

    echo "--> from: ${SOURCE}"
    echo "--> to  : ${TEMP_DIR}/${FILENAME}"

    if [ -d "${FILEPATH}" ] || [ -f "${FILEPATH}" ]; then
        rm -rf "${FILEPATH}"
    fi

    if [ "${REPO_USER}" == "s3" ]; then
        aws s3 cp "${SOURCE}" "${TEMP_DIR}"
    else
        if [ "${REPO_USER}" == "" ] || [ "${REPO_PASS}" == "" ]; then
            wget -q -N -P "${TEMP_DIR}" "${SOURCE}"
        else
            wget -q -N -P "${TEMP_DIR}" --user "${REPO_USER}" --password "${REPO_PASS}" "${SOURCE}"
        fi
    fi

    if [ ! -f "${FILEPATH}" ]; then
        echo "deploy file does not exist. [${FILEPATH}]"
    else
        # war (for tomcat stop/start)
        if [ "${TYPE}" == "war" ]; then
            HAS_WAR="TRUE"
        fi

        # jar (for jar stop/start)
        if [ "${TYPE}" == "jar" ]; then
            HAS_JAR="true"
        fi

        # php unzip
        if [ "${TYPE}" == "php" ]; then
            if [ -d "${UNZIP_DIR}" ] || [ -f "${UNZIP_DIR}" ]; then
                rm -rf "${UNZIP_DIR}"
            fi

            if [ -d "${UNZIP_DIR}" ] || [ -f "${UNZIP_DIR}" ]; then
                echo "deploy file can not unzip. [${UNZIP_DIR}]"
            else
                unzip -q "${FILEPATH}" -d "${UNZIP_DIR}"

                if [ -d "${UNZIP_DIR}/application/logs" ]; then
                    chmod 777 "${UNZIP_DIR}/application/logs"
                fi
            fi
        fi
    fi
}

placement() {
    echo "--> ${DEPLOY_PATH}"

    # php
    if [ "${TYPE}" == "php" ]; then
        rm -rf "${DEPLOY_PATH}.backup"

        if [ -d "${DEPLOY_PATH}" ] || [ -f "${DEPLOY_PATH}" ]; then
            mv -f "${DEPLOY_PATH}" "${DEPLOY_PATH}.backup"
        fi

        if [ -d "${DEPLOY_PATH}" ] || [ -f "${DEPLOY_PATH}" ]; then
            echo "deploy dir can not copy. [${DEPLOY_PATH}]"
        else
            mv -f "${UNZIP_DIR}" "${DEPLOY_PATH}"
        fi
    fi

    # war
    if [ "${TYPE}" == "war" ]; then
        DEST_WAR="${DEPLOY_PATH}/${ARTIFACT_ID}.${PACKAGING}"

        rm -rf "${DEPLOY_PATH}/${ARTIFACT_ID}"
        rm -rf "${DEST_WAR}"

        if [ -d "${DEST_WAR}" ] || [ -f "${DEST_WAR}" ]; then
            echo "deploy file can not copy. [${DEST_WAR}]"
        else
            cp -rf "${FILEPATH}" "${DEST_WAR}"
        fi
    fi

    # jar
    if [ "${TYPE}" == "jar" ]; then
        DEST_WAR="${DEPLOY_PATH}/${ARTIFACT_ID}.${PACKAGING}"

        rm -rf "${DEST_WAR}"

        if [ -d "${DEST_WAR}" ] || [ -f "${DEST_WAR}" ]; then
            echo "deploy file can not copy. [${DEST_WAR}]"
        else
            process_stop
            cp -rf "${FILEPATH}" "${DEST_WAR}"
            process_start
        fi
    fi

    # version status
    URL="${TOAST_URL}/version/deploy/${PHASE}/${FLEET}/${ARTIFACT_ID}/${VERSION}"
    RES=`curl -s --data "token=${TOKEN}" ${URL}`
    ARR=(${RES})

    if [ "${ARR[0]}" != "OK" ]; then
        echo "Server Error. [${URL}][${RES}]"
    fi
}

conn() {
    PHASE="${PARAM1}"
    FLEET="${PARAM2}"

    # phase
    if [ "${PHASE}" == "" ]; then
        URL="${TOAST_URL}/phase/conn"
        wget -q -N --post-data "token=${TOKEN}" -P "${TEMP_DIR}" "${URL}"

        CONN_LIST="${TEMP_DIR}/conn"

        echo_bar
        cat ${CONN_LIST}
        echo_bar

        if [ `cat ${CONN_LIST} | wc -l` -eq 1 ]; then
            while read line
            do
                ARR=(${line})

                if [ "${ARR[0]}" != "" ]; then
                    PHASE="${ARR[1]}"
                fi
            done < ${CONN_LIST}
        else
            echo "Please input phase no."
            read READ_NO

            while read line
            do
                ARR=(${line})

                if [ "${ARR[0]}" == "${READ_NO}" ]; then
                    PHASE="${ARR[1]}"
                fi
            done < ${CONN_LIST}
        fi

        if [ "${PHASE}" == "" ]; then
            return 1
        fi
    fi

    # fleet
    if [ "${FLEET}" == "" ]; then
        URL="${TOAST_URL}/fleet/conn/${PHASE}"
        wget -q -N --post-data "token=${TOKEN}" -P "${TEMP_DIR}" "${URL}"

        CONN_LIST="${TEMP_DIR}/${PHASE}"

        echo_bar
        cat ${CONN_LIST}
        echo_bar

        if [ `cat ${CONN_LIST} | wc -l` -eq 1 ]; then
            while read line
            do
                ARR=(${line})

                if [ "${ARR[0]}" != "" ]; then
                    PHASE="${ARR[1]}"
                    FLEET="${ARR[2]}"
                fi
            done < ${CONN_LIST}
        else
            echo "Please input fleet no."
            read READ_NO

            while read line
            do
                ARR=(${line})

                if [ "${ARR[0]}" == "${READ_NO}" ]; then
                    PHASE="${ARR[1]}"
                    FLEET="${ARR[2]}"
                fi
            done < ${CONN_LIST}
        fi

        if [ "${FLEET}" == "" ]; then
            return 1
        fi
    fi

    # server
    URL="${TOAST_URL}/server/conn/${PHASE}/${FLEET}"
    wget -q -N --post-data "token=${TOKEN}" -P "${TEMP_DIR}" "${URL}"

    CONN_LIST="${TEMP_DIR}/${FLEET}"
    CONN_PARAM=""

    echo_bar
    cat ${CONN_LIST}
    echo_bar

    if [ `cat ${CONN_LIST} | wc -l` -eq 1 ]; then
        while read line
        do
            ARR=(${line})

            if [ "${ARR[0]}" != "" ]; then
                CONN_PARAM="${ARR[1]}@${ARR[2]} -p ${ARR[3]}"
            fi
        done < ${CONN_LIST}
    else
        echo "Please input server no."
        read READ_NO

        while read line
        do
            ARR=(${line})

            if [ "${ARR[0]}" == "${READ_NO}" ]; then
                CONN_PARAM="${ARR[1]}@${ARR[2]} -p ${ARR[3]}"
            fi
        done < ${CONN_LIST}
    fi

    if [ "${CONN_PARAM}" == "" ]; then
        return 1
    fi

    echo "connect... ${CONN_PARAM}..."

    # ssh
    ssh ${CONN_PARAM}
}

log_tomcat() {
    tail -f -n 500 "${TOMCAT_DIR}/logs/catalina.out"
}

log_webapp() {
    TODAY=`date +%Y-%m-%d`

    tail -f -n 500 "${SITE_DIR}/${PARAM1}/application/logs/log-${TODAY}.php"
}

log_cron() {
    LOG_DIR="/data/logs"

    find ${LOG_DIR}/** -type f -mtime +5 | xargs gzip
    find ${LOG_DIR}/** -type f -mtime +9 | xargs rm -rf
}

service_update() {
    if [ "${OS_TYPE}" == "Ubuntu" ]; then
        ${SUDO} apt-get update
        ${SUDO} apt-get upgrade -y
    else
        ${SUDO} yum update -y
    fi
}

service_install() {
    if [ ! -f "/usr/bin/$1" ]; then
        if [ "${OS_TYPE}" == "Ubuntu" ]; then
            ${SUDO} apt-get install -y $1
        else
            ${SUDO} yum install -y $1
        fi
    fi
}

service_ctl() {
    if [ "${OS_TYPE}" == "el7" ]; then
        ${SUDO} systemctl $2 $1.service

        if [ "$3" == "on" ]; then
            ${SUDO} systemctl enable $1.service
        fi
        if [ "$3" == "off" ]; then
            ${SUDO} systemctl disable $1.service
        fi
    else
        ${SUDO} service $1 $2

        if [ "$3" == "on" ]; then
            ${SUDO} chkconfig $1 on
        fi
        if [ "$3" == "off" ]; then
            ${SUDO} chkconfig $1 off
        fi
    fi
}

tomcat_stop() {
    if [ "${HAS_WAR}" == "TRUE" ]; then
        status=`ps -ef | grep catalina | grep java | grep -v grep | wc -l | awk '{print $1}'`
        if [ ${status} -ge 1 ]; then
            echo "tomcat stop..."
            ${TOMCAT_DIR}/bin/shutdown.sh
        fi
    fi
}

tomcat_start() {
    if [ "${HAS_WAR}" == "TRUE" ]; then
        status=`ps -ef | grep catalina | grep java | grep -v grep | wc -l | awk '{print $1}'`
        count=0
        while [ ${status} -ge 1 ]; do
            echo "sleep..."
            sleep 3

            if [ ${count} -ge 5 ]; then
                pid=`ps -ef | grep catalina | grep java | grep -v grep | awk '{print $2}'`
                kill -9 ${pid}
                echo "tomcat (${pid}) was killed."
            fi

            sleep 2
            status=`ps -ef | grep catalina | grep java | grep -v grep | wc -l | awk '{print $1}'`
            count=`expr ${count} + 1`
        done

        echo "tomcat start..."
        ${TOMCAT_DIR}/bin/startup.sh
    fi
}

process_stop_all() {
    if [ "${HAS_JAR}" == "TRUE" ]; then
        PID=`ps -ef | grep "[j]ava" | grep "[-]jar" | awk '{print $2}'`
        if [ "${PID}" != "" ]; then
            kill -9 ${PID}
            echo "killed (${PID})"
        fi
    fi
}

process_stop() {
    PID=`ps -ef | grep "[${ARTIFACT_ID:0:1}]""${ARTIFACT_ID:1}" | grep "[-]jar" | awk '{print $2}'`
    if [ "${PID}" != "" ]; then
        kill -9 ${PID}
        echo "killed (${PID})"
    fi
}

process_start() {
    java -jar ${DEPLOY_PATH}/${ARTIFACT_ID}.${PACKAGING} >> /dev/null &

    PID=`ps -ef | grep "[${ARTIFACT_ID:0:1}]""${ARTIFACT_ID:1}" | grep "[-]jar" | awk '{print $2}'`
    if [ "${PID}" != "" ]; then
        echo "startup (${PID})"
    fi
}

add_env() {
    TARGET="${HOME}/.bashrc"

    if [ ! -f "${TARGET}" ]; then
        touch ${TARGET}
    fi

    KEY=$1
    VAL=$2

    HAS_KEY="false"

    while read LINE
    do
        KEY1=$(echo ${LINE} | cut -d "=" -f 1)

        if [ "${KEY1}" == "export ${KEY}" ]; then
            HAS_KEY="true"
        fi
    done < ${TARGET}

    if [ "${HAS_KEY}" == "false" ]; then
        echo "export ${KEY}=\"${VAL}\"" >> ${TARGET}
    fi

    source ${TARGET}
}

copy() {
    ${SUDO} cp -rf $1 $2

    if [ "$3" != "" ]; then
        ${SUDO} chmod $3 $2
    fi

    if [ "${USER}" != "" ]; then
        ${SUDO} chown ${USER}.${USER} $2
    fi
}

make_dir() {
    if [ ! -d $1 ] && [ ! -f $1 ]; then
        ${SUDO} mkdir $1
    fi

    if [ "$2" != "" ]; then
        ${SUDO} chmod $2 $1
    fi

    if [ "${USER}" != "" ]; then
        ${SUDO} chown ${USER}.${USER} $1
    fi
}

echo_toast() {
    echo_bar
    echo "                              _  _          _                  _        "
    echo "      _   _  __ _ _ __   ___ | |(_) __ _   | |_ ___   __ _ ___| |_      "
    echo "     | | | |/ _\` | '_ \ / _ \| || |/ _\` |  | __/ _ \ / _\` / __| __|  "
    echo "     | |_| | (_| | | | | (_) | || | (_| |  | || (_) | (_| \__ \ |_      "
    echo "      \__, |\__,_|_| |_|\___/|_|/ |\__,_|   \__\___/ \__,_|___/\__|     "
    echo "      |___/                   |__/                                      "
    echo "                                                         by nalbam      "
    echo_bar
}

echo_bar() {
    echo "================================================================================"
}

echo_() {
    echo ""
}

################################################################################

toast

# done
echo "done."
