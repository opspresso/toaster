#!/bin/bash

success() {
    echo "$(tput setaf 2)$1$(tput sgr0)"
}

warning() {
    echo "$(tput setaf 1)$1$(tput sgr0)"
}

################################################################################

# root
if [ "${HOME}" == "/root" ]; then
    warning "Not supported ROOT."
    exit 1
fi

# linux
OS_NAME=`uname`
if [ "${OS_NAME}" == "Linux" ]; then
    OS_FULL=`uname -a`
    if [ `echo ${OS_FULL} | grep -c "Ubuntu"` -gt 0 ]; then
        OS_TYPE="Ubuntu"
    else
        if [ `echo ${OS_FULL} | grep -c "el7"` -gt 0 ]; then
            OS_TYPE="el7"
        else
            OS_TYPE="el6"
        fi
    fi
else
    if [ "${OS_NAME}" == "Darwin" ]; then
        OS_TYPE="${OS_NAME}"
    else
        warning "Not supported OS - ${OS_NAME}"
        exit 1
    fi
fi

# sudo
SUDO="sudo"

################################################################################

SHELL_DIR=$(dirname $0)

TOAST_URL=
REPO_PATH=
ORG=
PHASE=
FLEET=
UUID=
NAME=
HOST=
PORT=
USER=
TOKEN=
SNO=

PROFILE="${HOME}/.bash_profile"
if [ -f "${PROFILE}" ]; then
    . ${PROFILE}
fi

CONFIG="${HOME}/.toast"
if [ -f "${CONFIG}" ]; then
    . ${CONFIG}
fi

UUID=`curl -s http://instance-data/latest/meta-data/instance-id`
NAME=`hostname`
USER=`whoami`

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
TEMP_DIR="/tmp"

HTTPD_VERSION="24"

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
        e|eip)
            eip
            ;;
        c|config)
            config
            ;;
        i|init)
            init
            ;;
        v|version)
            version
            ;;
        o|vhost)
            vhost
            ;;
        d|deploy)
            deploy
            ;;
        h|health)
            health
            ;;
        s|ssh)
            connect
            ;;
        l|log)
            log
            ;;
        *)
            usage
    esac
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
    echo " Usage: toast vhost"
    echo " Usage: toast vhost lb"
    echo " Usage: toast vhost fleet"
    echo " Usage: toast vhost domain"
    echo_
    echo " Usage: toast deploy"
    echo " Usage: toast deploy fleet"
    echo " Usage: toast deploy project"
    echo_
    echo " Usage: toast health"
    echo_
    echo " Usage: toast ssh"
    echo_
    echo_bar
}

auto() {
    not_darwin

    echo_toast

    prepare

    config
    self_info

    init_hosts
    init_profile
    init_slave
    init_aws
    init_epel
    init_auto

    repo_path
    deploy_fleet

    nginx_lb
    vhost_fleet

    eip_release
}

update() {
    self_info
    self_update

    #service_update
}

eip() {
    case ${PARAM1} in
        a|allocate)
            eip_allocate
            ;;
        r|release)
            eip_release
            ;;
        *)
            eip_allocate
    esac
}

config() {
    config_auto
    config_save
    config_info
    config_cron
}

init() {
    case ${PARAM1} in
        hosts)
            init_hosts
            ;;
        profile)
            init_profile
            ;;
        master)
            init_master
            ;;
        slave)
            init_slave
            ;;
        aws)
            init_aws
            ;;
        certificate)
            init_certificate
            ;;
        httpd)
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
            init_node
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
        munin)
            init_munin
            ;;
        *)
            self_info
            init_auto
    esac
}

version() {
    repo_path

    version_parse

    case ${PARAM1} in
        n|next)
            version_next
            ;;
        s|save)
            version_save
            ;;
        d|remove)
            version_remove
            ;;
    esac
}

vhost() {
    case ${PARAM1} in
        b|lb)
            nginx_lb
            ;;
        d|domain)
            vhost_domain
            ;;
        *)
            vhost_fleet
    esac
}

deploy() {
    repo_path

    init_hosts
    init_profile

    case ${PARAM1} in
        p|project)
            deploy_project
            ;;
        *)
            deploy_fleet
            vhost_fleet
    esac
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

health() {
    if [ "${SNO}" == "" ]; then
        warning "Not configured server. [${SNO}]"
        return 1
    fi

    echo "server health..."

    UNAME=`uname -a`
    UPTIME=`uptime`
    CPU=`grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print usage}'`

    echo "server cpu usage [${CPU}]"

    URL="${TOAST_URL}/server/health/${SNO}"
    RES=`curl -s --data "org=${ORG}&token=${TOKEN}&id=${UUID}&cpu=${CPU}&uname=${UNAME}&uptime=${UPTIME}" ${URL}`

    echo "${RES}"
}

################################################################################

self_info() {
    echo_bar
    echo "OS    : ${OS_NAME} ${OS_TYPE}"
    echo "HOME  : ${HOME}"
    echo_bar
    echo "ORG   : ${ORG}"
    echo "PHASE : ${PHASE}"
    echo "FLEET : ${FLEET}"
    echo "NAME  : ${NAME}"
    echo_bar
}

self_update() {
    pushd ${SHELL_DIR}
    git pull
    popd
}

prepare() {
    service_install "gcc curl wget unzip vim git sysstat"

    make_dir ${DATA_DIR}
    make_dir ${LOGS_DIR} 777

    make_dir ${HOME}/.aws
    make_dir ${HOME}/.ssh

    # timezone
    if [ ! -f "${SHELL_DIR}/.config_time" ]; then
        ${SUDO} rm -rf /etc/localtime
        ${SUDO} ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime

        touch "${SHELL_DIR}/.config_time"
    fi

    # i18n & selinux
    if [ "${OS_TYPE}" != "Ubuntu" ]; then
        copy ${SHELL_DIR}/package/linux/i18n.txt /etc/sysconfig/i18n 644
        copy ${SHELL_DIR}/package/linux/selinux.txt /etc/selinux/config 644
    fi

    if [ -f "/usr/sbin/setenforce" ]; then
        ${SUDO} setenforce 0
    fi
}

eip_allocate() {
    echo "eip allocate... [${UUID}]"

    URL="${TOAST_URL}/server/eip/allocate"
    RES=`curl -s --data "org=${ORG}&token=${TOKEN}&id=${UUID}" ${URL}`

    echo "eip allocate [${RES}]"
}

eip_release() {
    echo "eip release... [${UUID}]"

    URL="${TOAST_URL}/server/eip/release"
    RES=`curl -s --data "org=${ORG}&token=${TOKEN}&id=${UUID}" ${URL}`

    echo "eip release [${RES}]"
}

config_auto() {
    SSH=`${SUDO} cat /etc/ssh/sshd_config | egrep ^\#?Port`
    if [ "${SSH}" != "" ]; then
        ARR=(${SSH})
        PORT="${ARR[1]}"
    fi

    # .toast
    if [ ! -f "${CONFIG}" ]; then
        copy ${SHELL_DIR}/package/toast.txt ${CONFIG} 644
        . ${CONFIG}
    fi

    #  fleet phase org token
    if [ "${PARAM1}" != "" ]; then
        FLEET="${PARAM1}"
        echo "FLEET=${FLEET}" >> ${CONFIG}
    fi
    if [ "${PARAM2}" != "" ]; then
        PHASE="${PARAM2}"
        echo "PHASE=${PHASE}" >> ${CONFIG}
    fi
    if [ "${PARAM3}" != "" ]; then
        ORG="${PARAM3}"
        echo "ORG=${ORG}" >> ${CONFIG}
    fi
    if [ "${PARAM4}" != "" ]; then
        TOKEN="${PARAM4}"
        echo "TOKEN=${TOKEN}" >> ${CONFIG}
    fi
}

config_save() {
    echo "config save... [${UUID}][${SNO}]"

    URL="${TOAST_URL}/server/config"
    RES=`curl -s --data "org=${ORG}&token=${TOKEN}&phase=${PHASE}&fleet=${FLEET}&id=${UUID}&name=${NAME}&host=${HOST}&port=${PORT}&user=${USER}&no=${SNO}" ${URL}`
    ARR=(${RES})

    if [ "${ARR[0]}" == "OK" ]; then
        if [ "${ARR[1]}" != "" ]; then
            SNO="${ARR[1]}"
        fi
        if [ "${ARR[2]}" != "" ]; then
            HOST="${ARR[2]}"
        fi
        if [ "${ARR[3]}" != "" ]; then
            PHASE="${ARR[3]}"
        fi
        if [ "${ARR[4]}" != "" ]; then
            FLEET="${ARR[4]}"
        fi
    else
        echo "Server Error. [${URL}][${RES}]"
    fi

    echo "# yanolja toast config" > ${CONFIG}
    echo "TOAST_URL=${TOAST_URL}" >> ${CONFIG}
    echo "ORG=${ORG}" >> ${CONFIG}
    echo "PHASE=${PHASE}" >> ${CONFIG}
    echo "FLEET=${FLEET}" >> ${CONFIG}
    echo "UUID=${UUID}" >> ${CONFIG}
    echo "NAME=${NAME}" >> ${CONFIG}
    echo "HOST=${HOST}" >> ${CONFIG}
    echo "PORT=${PORT}" >> ${CONFIG}
    echo "USER=${USER}" >> ${CONFIG}
    echo "TOKEN=${TOKEN}" >> ${CONFIG}
    echo "SNO=${SNO}" >> ${CONFIG}

    chmod 644 ${CONFIG}
    . ${CONFIG}

    echo "${RES}"
}

config_info() {
    if [ ! -f "${CONFIG}" ]; then
        warning "Not exist file. [${CONFIG}]"
        return 1
    fi

    echo_bar
    cat ${CONFIG}
    echo_bar
}

config_cron() {
    TEMP_FILE="${TEMP_DIR}/toast-cron.tmp"

    echo "# yanolja cron" > ${TEMP_FILE}
    echo "0 1 * * * ${SHELL_DIR}/toast.sh log > /dev/null 2>&1" >> ${TEMP_FILE}
    echo "0 5 * * * ${SHELL_DIR}/toast.sh update > /dev/null 2>&1" >> ${TEMP_FILE}
    echo "* * * * * ${SHELL_DIR}/toast.sh health > /dev/null 2>&1" >> ${TEMP_FILE}

    crontab ${TEMP_FILE}

    echo_bar
    crontab -l
    echo_bar
}

init_hosts() {
    echo "init hosts..."

    TARGET="/etc/hosts"
    TEMP_FILE="${TEMP_DIR}/toast-hosts.tmp"

    new_file ${TEMP_FILE}

    if [ -f "${TARGET}_toast" ]; then
        copy "${TARGET}_toast" ${TARGET}
    else
        copy ${TARGET} "${TARGET}_toast"
    fi

    # default hosts
    URL="${TOAST_URL}/config/key/hosts"
    RES=`curl -s --data "org=${ORG}&token=${TOKEN}" ${URL}`

    echo "# toast default hosts" >> ${TEMP_FILE}
    echo "" >> ${TEMP_FILE}
    echo "${RES}" >> ${TEMP_FILE}
    echo "127.0.0.1 ${NAME}" >> ${TEMP_FILE}

    # phase hosts
    URL="${TOAST_URL}/phase/hosts/${PHASE}"
    RES=`curl -s --data "org=${ORG}&token=${TOKEN}" ${URL}`

    if [ "${RES}" != "" ]; then
        echo "" >> ${TEMP_FILE}
        echo "# toast ${PHASE} hosts" >> ${TEMP_FILE}
        echo "" >> ${TEMP_FILE}
        echo "${RES}" >> ${TEMP_FILE}
    fi

    # fleet hosts
    URL="${TOAST_URL}/fleet/hosts/${PHASE}/${FLEET}"
    RES=`curl -s --data "org=${ORG}&token=${TOKEN}" ${URL}`

    if [ "${RES}" != "" ]; then
        echo "" >> ${TEMP_FILE}
        echo "# toast ${FLEET} hosts" >> ${TEMP_FILE}
        echo "" >> ${TEMP_FILE}
        echo "${RES}" >> ${TEMP_FILE}
    fi

    copy ${TEMP_FILE} ${TARGET}
}

init_profile() {
    echo "init profile..."

    # .bash_profile
    TARGET="${HOME}/.bash_profile"
    touch ${TARGET}

    if [ -f "${TARGET}_toast" ]; then
        cp "${TARGET}_toast" ${TARGET}
    else
        cp ${TARGET} "${TARGET}_toast"
    fi

    # default profile
    URL="${TOAST_URL}/config/key/profile"
    RES=`curl -s --data "org=${ORG}&token=${TOKEN}" ${URL}`

    if [ "${RES}" != "" ]; then
        echo "" >> ${TARGET}
        echo "# toast default profile" >> ${TARGET}
        echo "" >> ${TARGET}
        echo "${RES}" >> ${TARGET}
    fi

    # phase profile
    URL="${TOAST_URL}/phase/profile/${PHASE}"
    RES=`curl -s --data "org=${ORG}&token=${TOKEN}" ${URL}`

    if [ "${RES}" != "" ]; then
        echo "" >> ${TARGET}
        echo "# toast ${PHASE} profile" >> ${TARGET}
        echo "" >> ${TARGET}
        echo "${RES}" >> ${TARGET}
    fi

    # fleet profile
    URL="${TOAST_URL}/fleet/profile/${PHASE}/${FLEET}"
    RES=`curl -s --data "org=${ORG}&token=${TOKEN}" ${URL}`

    if [ "${RES}" != "" ]; then
        echo "" >> ${TARGET}
        echo "# toast ${FLEET} profile" >> ${TARGET}
        echo "" >> ${TARGET}
        echo "${RES}" >> ${TARGET}
    fi

    echo "" >> ${TARGET}
}

init_master() {
    echo "init master..."

    # .ssh/id_rsa
    URL="${TOAST_URL}/config/key/rsa_private_key"
    RES=`curl -s --data "org=${ORG}&token=${TOKEN}" ${URL}`

    if [ "${RES}" != "" ]; then
        TARGET="${HOME}/.ssh/id_rsa"
        echo "${RES}" > ${TARGET}
        chmod 600 ${TARGET}
    fi

    # .ssh/id_rsa.pub
    URL="${TOAST_URL}/config/key/rsa_public_key"
    RES=`curl -s --data "org=${ORG}&token=${TOKEN}" ${URL}`

    if [ "${RES}" != "" ]; then
        TARGET="${HOME}/.ssh/id_rsa.pub"
        echo "${RES}" > ${TARGET}
        chmod 644 ${TARGET}
    fi

    # .aws/credentials
    URL="${TOAST_URL}/config/key/aws_master"
    RES=`curl -s --data "org=${ORG}&token=${TOKEN}" ${URL}`

    if [ "${RES}" != "" ]; then
        TARGET="${HOME}/.aws/credentials"
        echo "${RES}" > ${TARGET}
        chmod 600 ${TARGET}
    fi
}

init_slave() {
    echo "init slave..."

    # .ssh/authorized_keys
    TARGET="${HOME}/.ssh/authorized_keys"
    touch ${TARGET}

    if [ `cat ${TARGET} | grep -c "toast@yanolja.in"` -eq 0 ]; then
        URL="${TOAST_URL}/config/key/rsa_public_key"
        RES=`curl -s --data "org=${ORG}&token=${TOKEN}" ${URL}`

        if [ "${RES}" != "" ]; then
            echo "${RES}" >> ${TARGET}
            chmod 700 ${TARGET}
        fi
    fi

    # .ssh/id_rsa
    TARGET="${HOME}/.ssh/id_rsa"
    rm -rf ${TARGET}

    # .ssh/id_rsa.pub
    TARGET="${HOME}/.ssh/id_rsa.pub"
    rm -rf ${TARGET}

    # .ssh/config
    URL="${TOAST_URL}/config/key/ssh_config"
    RES=`curl -s --data "org=${ORG}&token=${TOKEN}" ${URL}`

    if [ "${RES}" != "" ]; then
        TARGET="${HOME}/.ssh/config"
        echo "${RES}" > ${TARGET}
        chmod 600 ${TARGET}
    fi

    # .aws/credentials
    URL="${TOAST_URL}/config/key/aws_slave"
    RES=`curl -s --data "org=${ORG}&token=${TOKEN}" ${URL}`

    if [ "${RES}" != "" ]; then
        TARGET="${HOME}/.aws/credentials"
        echo "${RES}" > ${TARGET}
        chmod 600 ${TARGET}
    fi
}

init_aws() {
    echo "init aws..."

    # .aws/config
    URL="${TOAST_URL}/config/key/aws_config"
    RES=`curl -s --data "org=${ORG}&token=${TOKEN}" ${URL}`

    if [ "${RES}" != "" ]; then
        TARGET="${HOME}/.aws/config"
        echo "${RES}" > ${TARGET}
        chmod 600 ${TARGET}
    fi

    # aws cli
    if [ ! -f "/usr/bin/aws" ]; then
        if [ ! -f "${SHELL_DIR}/.config_aws_cli" ]; then
            echo "init aws cli..."

            wget -q -N https://s3.amazonaws.com/aws-cli/awscli-bundle.zip

            if [ -f "${HOME}/awscli-bundle.zip" ]; then
                unzip awscli-bundle.zip

                AWS_HOME="/usr/local/aws"

                ${SUDO} ./awscli-bundle/install -i ${AWS_HOME} -b /usr/bin/aws

                add_path "${AWS_HOME}/bin"

                rm -rf awscli-bundle
                rm -rf awscli-bundle.zip

                touch "${SHELL_DIR}/.config_aws_cli"
            fi
        fi
    fi

    echo_bar
    aws --version
    echo_bar
}

init_certificate() {
    echo "init certificate..."

    if [ "$1" != "" ]; then
        PARAM="$1"
    else
        if [ "${PARAM2}" != "" ]; then
            PARAM="${PARAM2}"
        else
            return
        fi
    fi

    SSL_DIR="/data/conf"
    make_dir ${SSL_DIR}

    SSL_NAME=
    SSL_INFO="${SSL_DIR}/info"

    if [ -f ${SSL_INFO} ]; then
        . ${SSL_INFO}
    fi

    if [ "${PARAM}" == "${SSL_NAME}" ]; then
        return
    fi

    CERTIFICATE="${TEMP_DIR}/${PARAM}"

    URL="${TOAST_URL}/certificate/name/${PARAM}"
    wget -q -N --post-data "org=${ORG}&token=${TOKEN}" -P "${TEMP_DIR}" "${URL}"

    if [ -f ${CERTIFICATE} ]; then
        echo "save certificate..."

        TARGET=

        while read line
        do
            ARR=(${line})

            if [ "${ARR[0]}" == "#" ]; then
                TARGET="${SSL_DIR}/${ARR[1]}"
                new_file ${TARGET} 600
            else
                if [ -w ${TARGET} ]; then
                    echo "${line}" >> ${TARGET}
                fi
            fi
        done < ${CERTIFICATE}

        echo "SSL_NAME=${PARAM}" > ${SSL_INFO}
    fi
}

init_auto() {
    URL="${TOAST_URL}/fleet/apps/${PHASE}/${FLEET}"
    RES=`curl -s --data "org=${ORG}&token=${TOKEN}" ${URL}`
    ARR=(${RES})

    for i in "${ARR[@]}"; do
        case "$i" in
            httpd)
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
                init_node
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

    if [ -f "${SHELL_DIR}/.config_epel" ]; then
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

    touch "${SHELL_DIR}/.config_epel"
}

init_webtatic() {
    if [ "${OS_TYPE}" == "Ubuntu" ]; then
        return 1
    fi

    if [ -f "${SHELL_DIR}/.config_webtatic" ]; then
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

    touch "${SHELL_DIR}/.config_webtatic"
}

init_httpd() {
    if [ ! -f "${SHELL_DIR}/.config_httpd" ]; then
        echo "init httpd..."

        service_install "openssl openssl-devel"

        if [ "${OS_TYPE}" == "Ubuntu" ]; then
            service_install apache2

            HTTPD_VERSION="ubuntu"
        else
            service_install "centos-release-scl"

            status=`${SUDO} yum list | grep httpd24 | wc -l | awk '{print $1}'`

            if [ ${status} -ge 1 ]; then
                service_install "httpd24"
            else
                service_install "httpd"
            fi

            VERSION=$(httpd -version | egrep -o "Apache\/2.4")

            if [ "${VERSION}" != "" ]; then
                HTTPD_VERSION="24"
            else
                HTTPD_VERSION="22"
            fi
        fi

        init_httpd_conf

        if [ "${OS_TYPE}" == "Ubuntu" ]; then
            service_ctl apache2 start on
        else
            service_ctl httpd start on
        fi

        echo "HTTPD_VERSION=${HTTPD_VERSION}" > "${SHELL_DIR}/.config_httpd"
    fi

    if [ -d "/var/www/html" ]; then
        TEMP_FILE="${TEMP_DIR}/toast-health.tmp"
        echo "OK ${HOST}" > ${TEMP_FILE}
        copy ${TEMP_FILE} "/var/www/html/index.html" 644
        copy ${TEMP_FILE} "/var/www/html/health.html" 644
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

init_nginx() {
    if [ ! -f "${SHELL_DIR}/.config_nginx" ]; then
        echo "init nginx..."

        service_install "pcre pcre-devel zlib zlib-devel openssl openssl-devel"

        ${SHELL_DIR}/install-nginx.sh

        ${SUDO} nginx

        touch "${SHELL_DIR}/.config_nginx"
    fi

    if [ -d "/usr/local/nginx/html" ]; then
        TEMP_FILE="${TEMP_DIR}/toast-health.tmp"
        echo "OK ${NAME}" > ${TEMP_FILE}
        copy ${TEMP_FILE} "/usr/local/nginx/html/index.html" 644
        copy ${TEMP_FILE} "/usr/local/nginx/html/health.html" 644
    fi

    make_dir "${SITE_DIR}"
    make_dir "${SITE_DIR}/files" 777
    make_dir "${SITE_DIR}/upload" 777

    echo_bar
    nginx -v
    echo_bar
}

init_php() {
    if [ ! -f "${SHELL_DIR}/.config_php" ]; then
        if [ "${OS_TYPE}" == "Ubuntu" ]; then
            if [ "$1" == "70" ]; then
                VERSION="7.0"
            else
                if [ "$1" == "55" ]; then
                    VERSION="5.5"
                else
                    VERSION="5.6"
                fi
            fi

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

        echo "PHP_VERSION=${VERSION}" > "${SHELL_DIR}/.config_php"
    fi

    echo_bar
    if [ "${OS_TYPE}" == "Ubuntu" ]; then
        php -v
    else
        php -version
    fi
    echo_bar
}

init_node() {
    if [ ! -f "${SHELL_DIR}/.config_node" ]; then
        echo "init node..."

        ${SHELL_DIR}/install-node.sh

        NODE_HOME="/usr/local/node"

        add_path "${NODE_HOME}/bin"
        add_env "NODE_HOME" "${NODE_HOME}"

        echo "NODE_HOME=${NODE_HOME}"
        echo "NODE_HOME=${NODE_HOME}" > "${SHELL_DIR}/.config_node"
    fi

    echo_bar
    echo "node version `node -v`"
    echo "npm version `npm -v`"
    echo_bar
}

init_java8() {
    if [ ! -f "${SHELL_DIR}/.config_java" ]; then
        echo "init java..."

        service_remove "java-1.8.0-openjdk java-1.8.0-openjdk-devel java-1.8.0-openjdk-headless"

        ${SHELL_DIR}/install-java.sh

        JAVA_HOME="/usr/local/java"

        add_path "${JAVA_HOME}/bin"
        add_env "JAVA_HOME" "${JAVA_HOME}"

        copy "${SHELL_DIR}/package/jce8/local_policy.jar.bin" "${JAVA_HOME}/jre/lib/security/local_policy.jar" 644
        copy "${SHELL_DIR}/package/jce8/US_export_policy.jar.bin" "${JAVA_HOME}/jre/lib/security/US_export_policy.jar" 644

        echo "JAVA_HOME=${JAVA_HOME}"
        echo "JAVA_HOME=${JAVA_HOME}" > "${SHELL_DIR}/.config_java"
    fi

    make_dir "${APPS_DIR}"

    echo_bar
    java -version
    echo_bar
}

init_tomcat8() {
    if [ ! -f "${SHELL_DIR}/.config_tomcat" ]; then
        echo "init tomcat..."

        make_dir "${APPS_DIR}"

        ${SHELL_DIR}/install-tomcat.sh "${APPS_DIR}"

        CATALINA_HOME="${APPS_DIR}/tomcat8"

        copy "${SHELL_DIR}/package/tomcat/web.xml" "${CATALINA_HOME}/conf/web.xml" 644

        add_env "CATALINA_HOME" "${CATALINA_HOME}"

        echo "CATALINA_HOME=${CATALINA_HOME}"
        echo "CATALINA_HOME=${CATALINA_HOME}" > "${SHELL_DIR}/.config_tomcat"
    fi
}

init_mysql55() {
    if [ ! -f "${SHELL_DIR}/.config_mysql" ]; then
        echo "init mysql55..."

        service_install mysql55-server

        service_ctl mysqld start on

        touch "${SHELL_DIR}/.config_mysql"
    fi
}

init_mysql56() {
    if [ ! -f "${SHELL_DIR}/.config_mysql" ]; then
        echo "init mysql56..."

        service_install mysql56-server

        service_ctl mysqld start on

        touch "${SHELL_DIR}/.config_mysql"
    fi
}

init_redis() {
    if [ ! -f "${SHELL_DIR}/.config_redis" ]; then
        echo "init redis..."

        service_install redis

        service_ctl redis start on

        touch "${SHELL_DIR}/.config_redis"
    fi
}

init_rabbitmq() {
    if [ ! -f "${SHELL_DIR}/.config_rabbitmq" ]; then
        echo "init rabbitmq..."

        #wget -q -N -P "${HOME}" https://packages.erlang-solutions.com/erlang/esl-erlang/FLAVOUR_1_general/esl-erlang_19.0~centos~6_amd64.rpm
        #wget -q -N -P "${HOME}" https://www.rabbitmq.com/releases/rabbitmq-server/v3.6.4/rabbitmq-server-3.6.4-1.noarch.rpm

        service_install rabbitmq-server

        service_ctl rabbitmq-server restart on

        touch "${SHELL_DIR}/.config_rabbitmq"
    fi
}

init_munin() {
    if [ ! -f "${SHELL_DIR}/.config_munin" ]; then
        echo "init munin..."

        service_install munin

        service_ctl munin-node restart on

        touch "${SHELL_DIR}/.config_munin"
    fi
}

init_httpd_conf() {
    if [ -f "/etc/httpd/conf/httpd.conf" ]; then
        HTTPD_CONF="/etc/httpd/conf/httpd.conf"
    else
        if [ "${OS_TYPE}" == "Ubuntu" ]; then
            if [ -f "/etc/apache2/httpd.conf" ]; then
                HTTPD_CONF="/etc/apache2/httpd.conf"
            fi
        else
            if [ -f "/usr/local/apache/conf/httpd.conf" ]; then
                HTTPD_CONF="/usr/local/apache/conf/httpd.conf"
            fi
        fi
    fi

    if [ -f ${HTTPD_CONF} ]; then
        echo "${HTTPD_CONF}"

        TEMP_FILE="${TEMP_DIR}/toast-httpd-conf.tmp"

        # User apache
        sed "s/User\ apache/User\ $USER/g" ${HTTPD_CONF} > ${TEMP_FILE}
        copy ${TEMP_FILE} ${HTTPD_CONF} 644

        # Group apache
        sed "s/Group\ apache/Group\ $USER/g" ${HTTPD_CONF} > ${TEMP_FILE}
        copy ${TEMP_FILE} ${HTTPD_CONF} 644
    fi
}

init_php_ini() {
    if [ -f "/etc/php.ini" ]; then
        PHP_INI="/etc/php.ini"
    else
        if [ "${OS_TYPE}" == "Ubuntu" ]; then
            if [ -f "/etc/php/5.6/apache2/php.ini" ]; then
                PHP_INI="/etc/php/5.6/apache2/php.ini"
            else
                if [ -f "/etc/php/7.0/apache2/php.ini" ]; then
                    PHP_INI="/etc/php/7.0/apache2/php.ini"
                fi
            fi
        fi
    fi

    if [ -f ${PHP_INI} ]; then
        echo "${PHP_INI}"

        TEMP_FILE="${TEMP_DIR}/toast-php-ini.tmp"

        # short_open_tag = On
        sed "s/short\_open\_tag\ \=\ Off/short\_open\_tag\ \=\ On/g" ${PHP_INI} > ${TEMP_FILE}
        copy ${TEMP_FILE} ${PHP_INI} 644

        # expose_php = Off
        sed "s/expose\_php\ \=\ On/expose\_php\ \=\ Off/g" ${PHP_INI} > ${TEMP_FILE}
        copy ${TEMP_FILE} ${PHP_INI} 644

        # date.timezone = Asia/Seoul
        sed "s/\;date\.timezone\ \=/date\.timezone\ \=\ Asia\/Seoul/g" ${PHP_INI} > ${TEMP_FILE}
        copy ${TEMP_FILE} ${PHP_INI} 644
    fi
}

version_parse() {
    DEST_FILE="./pom.xml"

    if [ ! -f "${DEST_FILE}" ]; then
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
        warning "Not set artifact_id. [${ARTIFACT_ID}]"
        return 1
    fi

    echo "version get..."

    URL="${TOAST_URL}/version/latest/${ARTIFACT_ID}"
    RES=`curl -s --data "org=${ORG}&token=${TOKEN}" ${URL}`
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

    if [ -f ${DEST_FILE} ]; then
        sed "s/$VER1/$VER2/;10q;" ${DEST_FILE} > ${TEMP_FILE}
        sed "1,10d" ${DEST_FILE} >> ${TEMP_FILE}

        cp -rf ${TEMP_FILE} ${DEST_FILE}
    fi

    VERSION=NEXT_VERSION
}

version_save() {
    if [ "${ARTIFACT_ID}" == "" ]; then
        warning "Not set artifact_id. [${ARTIFACT_ID}]"
        return 1
    fi

    echo "version save..."

    ARTIFACT_PATH="${GROUP_PATH}/${ARTIFACT_ID}/${VERSION}"

    aws s3 sync ~/.m2/repository/${ARTIFACT_PATH}/ ${REPO_PATH}/${ARTIFACT_PATH}/

    URL="${TOAST_URL}/version/build/${ARTIFACT_ID}/${VERSION}"
    RES=`curl -s --data "org=${ORG}&token=${TOKEN}" ${URL}`
    ARR=(${RES})

    if [ "${ARR[0]}" != "OK" ]; then
        echo "Server Error. [${URL}][${RES}]"
    else
        echo "${ARR[1]}"
    fi
}

version_remove() {
    if [ "${ARTIFACT_ID}" == "" ]; then
        warning "Not set artifact_id. [${ARTIFACT_ID}]"
        return 1
    fi

    echo "version remove..."

    GROUP_PATH=`echo "${GROUP_ID}" | sed "s/\./\//"`
    ARTIFACT_PATH="${GROUP_PATH}/${ARTIFACT_ID}/${VERSION}"

    aws s3 rm ${REPO_PATH}/${ARTIFACT_PATH} --recursive

    rm -rf ~/.m2/repository/${ARTIFACT_PATH}
}

nginx_conf() {
    TOAST_NGINX="${SHELL_DIR}/.config_nginx"
    if [ ! -f "${TOAST_NGINX}" ]; then
        return 1
    fi

    NGINX_CONF_DIR=""

    if [ -f "/usr/local/nginx/conf/nginx.conf" ]; then
        NGINX_CONF_DIR="/usr/local/nginx/conf"
    fi
}

httpd_conf() {
    TOAST_APACHE="${SHELL_DIR}/.config_httpd"
    if [ ! -f "${TOAST_APACHE}" ]; then
        return 1
    fi

    . ${TOAST_APACHE}

    if [ "${HTTPD_VERSION}" == "" ]; then
        HTTPD_VERSION="24"
    fi

    HTTPD_CONF_DIR=""

    if [ "${OS_TYPE}" == "Ubuntu" ]; then
        if [ -d "/etc/apache2/sites-enabled" ]; then
            HTTPD_CONF_DIR="/etc/apache2/sites-enabled"
        fi
    else
        if [ -d "/etc/httpd/conf.d" ]; then
            HTTPD_CONF_DIR="/etc/httpd/conf.d"
        else
            if [ -d "/usr/local/apache/conf/extra" ]; then
                HTTPD_CONF_DIR="/usr/local/apache/conf/extra"
            fi
        fi
    fi
}

nginx_lb() {
    nginx_conf

    if [ "${NGINX_CONF_DIR}" == "" ]; then
        return
    fi

    TEMP_FILE="${TEMP_DIR}/toast-lb.tmp"
    TARGET="${NGINX_CONF_DIR}/nginx.conf"

    echo_bar
    echo "nginx lb..."

    LB_CONF="${TEMP_DIR}/${FLEET}"

    URL="${TOAST_URL}/fleet/lb/${FLEET}"
    wget -q -N --post-data "org=${ORG}&token=${TOKEN}" -P "${TEMP_DIR}" "${URL}"

    if [ -f ${LB_CONF} ]; then
        cat ${LB_CONF}

        TEMP_HTTP="${TEMP_DIR}/toast-lb-http.tmp"
        TEMP_SSL="${TEMP_DIR}/toast-lb-ssl.tmp"
        TEMP_TCP="${TEMP_DIR}/toast-lb-tcp.tmp"

        rm -rf ${TEMP_FILE} ${TEMP_HTTP} ${TEMP_SSL} ${TEMP_TCP}

        while read line
        do
            ARR=(${line})

            if [ "${ARR[0]}" == "NO" ]; then
                FNO="${ARR[1]}"
            fi

            if [ "${ARR[0]}" == "SSL" ]; then
                init_certificate "${ARR[1]}"
            fi

            if [ "${ARR[0]}" == "HOST" ]; then
                HOST_ARR=(${line:5})
            fi

            if [ "${ARR[0]}" == "CUSTOM" ]; then
                URL="${TOAST_URL}/fleet/custom/${FNO}"
                RES=`curl -s --data "org=${ORG}&token=${TOKEN}" ${URL}`

                if [ "${RES}" != "" ]; then
                    CUSTOM="${RES}"
                fi
            fi

            if [ "${ARR[0]}" == "HTTP" ]; then
                PORT="${ARR[1]}"

                echo "    upstream yanolja {" >> ${TEMP_HTTP}

                for i in "${HOST_ARR[@]}"
                do
                   echo "        server ${i}:${PORT} max_fails=3 fail_timeout=10s;" >> ${TEMP_HTTP}
                done

                echo "    }" >> ${TEMP_HTTP}

                TEMPLATE="${SHELL_DIR}/package/nginx/nginx-http-server.conf"
                if [ "${CUSTOM}" == "" ]; then
                    sed "s/PORT/$PORT/g" ${TEMPLATE} > ${TEMP_HTTP}
                else
                    sed "s/PORT/$PORT/;5q;" ${TEMPLATE} >> ${TEMP_HTTP}
                    echo "${CUSTOM}" >> ${TEMP_HTTP}
                    sed "1,9d" ${TEMPLATE} >> ${TEMP_HTTP}
                fi
            fi

            if [ "${ARR[0]}" == "HTTPS" ]; then
                PORT="${ARR[1]}"

                TEMPLATE="${SHELL_DIR}/package/nginx/nginx-http-ssl.conf"
                if [ "${CUSTOM}" == "" ]; then
                    sed "s/PORT/$PORT/g" ${TEMPLATE} > ${TEMP_SSL}
                else
                    sed "s/PORT/$PORT/;4q;" ${TEMPLATE} >> ${TEMP_SSL}
                    echo "${CUSTOM}" >> ${TEMP_SSL}
                    sed "1,8d" ${TEMPLATE} >> ${TEMP_SSL}
                fi
            fi

            if [ "${ARR[0]}" == "TCP" ]; then
                PORT="${ARR[1]}"

                echo "    upstream yanolja_${PORT} {" >> ${TEMP_TCP}

                for i in "${HOST_ARR[@]}"
                do
                   echo "        server ${i}:${PORT} max_fails=3 fail_timeout=10s;" >> ${TEMP_TCP}
                done

                echo "    }" >> ${TEMP_TCP}

                TEMPLATE="${SHELL_DIR}/package/nginx/nginx-tcp-server.conf"
                sed "s/PORT/$PORT/g" ${TEMPLATE} >> ${TEMP_TCP}
            fi
        done < ${LB_CONF}

        echo "assemble..."

        # default
        TEMPLATE="${SHELL_DIR}/package/nginx/nginx-default.conf"
        cat ${TEMPLATE} >> ${TEMP_FILE}

        # http
        if [ -f ${TEMP_HTTP} ]; then
            echo "" >> ${TEMP_FILE}
            echo "http {" >> ${TEMP_FILE}

            TEMPLATE="${SHELL_DIR}/package/nginx/nginx-http-default.conf"
            cat ${TEMPLATE} >> ${TEMP_FILE}

            # http
            echo "" >> ${TEMP_FILE}
            cat ${TEMP_HTTP} >> ${TEMP_FILE}

            # https
            if [ -f ${TEMP_SSL} ]; then
                echo "" >> ${TEMP_FILE}
                cat ${TEMP_SSL} >> ${TEMP_FILE}
            fi

            echo "}" >> ${TEMP_FILE}
        fi

        # tcp
        if [ -f ${TEMP_TCP} ]; then
            echo "stream {" >> ${TEMP_FILE}

            TEMPLATE="${SHELL_DIR}/package/nginx/nginx-tcp-default.conf"
            cat ${TEMPLATE} >> ${TEMP_FILE}

            echo "" >> ${TEMP_FILE}
            cat ${TEMP_TCP} >> ${TEMP_FILE}

            echo "}" >> ${TEMP_FILE}
        fi

        # done
        copy ${TEMP_FILE} ${TARGET} 644

        ${SUDO} nginx -s reload
    fi

    echo_bar
}

vhost_domain() {
    httpd_conf

    if [ "${HTTPD_CONF_DIR}" == "" ]; then
        return
    fi

    echo_bar
    echo "apache..."

    # localhost
    TEMPLATE="${SHELL_DIR}/package/apache/${HTTPD_VERSION}/localhost.conf"
    if [ -f "${TEMPLATE}" ]; then
        copy ${TEMPLATE} "${HTTPD_CONF_DIR}/localhost.conf" 644
    fi

    TEMPLATE="${SHELL_DIR}/package/apache/${HTTPD_VERSION}/vhost.conf"
    TEMP_FILE="${TEMP_DIR}/toast-vhost.tmp"

    DOM="${PARAM2}"

    make_dir "${SITE_DIR}/${DOM}"

    DEST_FILE="${HTTPD_CONF_DIR}/toast-${DOM}.conf"

    echo "--> ${DEST_FILE}"

    sed "s/DOM/$DOM/g" ${TEMPLATE} > ${TEMP_FILE} && copy ${TEMP_FILE} ${DEST_FILE} 644

    if [ "${OS_TYPE}" == "Ubuntu" ]; then
        service_ctl apache2 graceful
    else
        service_ctl httpd graceful
    fi

    echo_bar
}

vhost_fleet() {
    httpd_conf

    if [ "${HTTPD_CONF_DIR}" == "" ]; then
        return
    fi

    echo_bar
    echo "apache fleet..."

    ${SUDO} rm -rf ${HTTPD_CONF_DIR}/localhost*
    ${SUDO} rm -rf ${HTTPD_CONF_DIR}/toast*

    # localhost
    TEMPLATE="${SHELL_DIR}/package/apache/${HTTPD_VERSION}/localhost.conf"
    if [ -f "${TEMPLATE}" ]; then
        copy ${TEMPLATE} "${HTTPD_CONF_DIR}/localhost.conf" 644
    fi

    VHOST_LIST="${TEMP_DIR}/${FLEET}"
    rm -rf ${VHOST_LIST}

    URL="${TOAST_URL}/target/vhost/${PHASE}/${FLEET}"
    wget -q -N --post-data "org=${ORG}&token=${TOKEN}" -P "${TEMP_DIR}" "${URL}"

    if [ -f ${VHOST_LIST} ]; then
        echo "placement apache..."

        TEMPLATE="${SHELL_DIR}/package/apache/${HTTPD_VERSION}/vhost.conf"
        TEMP_FILE="${TEMP_DIR}/toast-vhost.tmp"

        while read line
        do
            ARR=(${line})

            DOM="${ARR[0]}"

            make_dir "${SITE_DIR}/${DOM}"

            DEST_FILE="${HTTPD_CONF_DIR}/toast-${DOM}.conf"

            echo "--> ${DEST_FILE}"

            sed "s/DOM/$DOM/g" ${TEMPLATE} > ${TEMP_FILE} && copy ${TEMP_FILE} ${DEST_FILE} 644
        done < ${VHOST_LIST}
    fi

    if [ "${OS_TYPE}" == "Ubuntu" ]; then
        service_ctl apache2 restart
    else
        service_ctl httpd restart
    fi

    echo_bar
}

repo_path() {
    # repo_path
    URL="${TOAST_URL}/config/key/repo_path"
    RES=`curl -s --data "org=${ORG}&token=${TOKEN}" ${URL}`

    if [ "${RES}" != "" ]; then
        REPO_PATH="${RES}"
    fi
}

deploy_project() {
    echo "deploy project..."

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
    echo_bar
    echo "deploy fleet..."

    TARGET_FILE="${TEMP_DIR}/${FLEET}"
    rm -rf ${TARGET_FILE}

    URL="${TOAST_URL}/target/deploy/${PHASE}/${FLEET}"
    wget -q -N --post-data "org=${ORG}&token=${TOKEN}" -P "${TEMP_DIR}" "${URL}"

    if [ -f ${TARGET_FILE} ]; then
        echo "download..."

        while read line
        do
            ARR=(${line})

            deploy_value

            download
        done < ${TARGET_FILE}

        tomcat_stop
        process_stop_all

        echo "placement..."

        while read line
        do
            ARR=(${line})

            deploy_value

            placement
        done < ${TARGET_FILE}

        tomcat_start
    fi

    echo_bar
}

deploy_value() {
    RANDOM="${ARR[0]}"
    GROUP_ID="${ARR[1]}"
    ARTIFACT_ID="${ARR[2]}"
    VERSION="${ARR[3]}"
    TYPE="${ARR[4]}"
    DOMAIN="${ARR[5]}"

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

    aws s3 cp "${SOURCE}" "${TEMP_DIR}" --quiet

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
    RES=`curl -s --data "org=${ORG}&token=${TOKEN}" ${URL}`
    ARR=(${RES})

    if [ "${ARR[0]}" != "OK" ]; then
        warning "Server Error. [${URL}][${RES}]"
    fi
}

connect() {
    PHASE="${PARAM1}"
    FLEET="${PARAM2}"

    # phase
    if [ "${PHASE}" == "" ]; then
        URL="${TOAST_URL}/phase/conn"
        wget -q -N --post-data "org=${ORG}&token=${TOKEN}" -P "${TEMP_DIR}" "${URL}"

        CONN_LIST="${TEMP_DIR}/conn"

        if [ ! -f ${CONN_LIST} ]; then
            warning "Not exist file. [${CONN_LIST}]"
            exit 1
        fi

        echo_bar
        echo "# phase list"
        cat ${CONN_LIST}
        echo_bar

        if [ `cat ${CONN_LIST} | wc -l` -lt 2 ]; then
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
        wget -q -N --post-data "org=${ORG}&token=${TOKEN}" -P "${TEMP_DIR}" "${URL}"

        CONN_LIST="${TEMP_DIR}/${PHASE}"

        if [ ! -f ${CONN_LIST} ]; then
            warning "Not exist file. [${CONN_LIST}]"
            exit 1
        fi

        echo_bar
        echo "# fleet list"
        cat ${CONN_LIST}
        echo_bar

        if [ `cat ${CONN_LIST} | wc -l` -lt 2 ]; then
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
    wget -q -N --post-data "org=${ORG}&token=${TOKEN}" -P "${TEMP_DIR}" "${URL}"

    CONN_LIST="${TEMP_DIR}/${FLEET}"
    CONN_PARAM=""

    if [ ! -f ${CONN_LIST} ]; then
        warning "Not exist file. [${CONN_LIST}]"
        exit 1
    fi

    echo_bar
    echo "# server list"
    cat ${CONN_LIST}
    echo_bar

    if [ `cat ${CONN_LIST} | wc -l` -lt 2 ]; then
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
    echo_bar

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
    find ${LOGS_DIR}/** -type f -mtime +5 | xargs gzip
    find ${LOGS_DIR}/** -type f -mtime +9 | xargs rm -rf
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
    if [ "${OS_TYPE}" == "Ubuntu" ]; then
        ${SUDO} apt-get install -y $1
    else
        ${SUDO} yum install -y $1
    fi
}

service_remove() {
    if [ "${OS_TYPE}" == "Ubuntu" ]; then
        ${SUDO} apt-get remove -y $1
    else
        ${SUDO} yum remove -y $1
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

add_path() {
    TARGET="${HOME}/.bashrc"
    touch ${TARGET}

    VAL=$1

    echo "" >> ${TARGET}
    echo "export PATH=\"\$PATH:${VAL}\"" >> ${TARGET}

    . ${HOME}/.bash_profile
}

add_env() {
    TARGET="${HOME}/.bashrc"
    touch ${TARGET}

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
        echo "" >> ${TARGET}
        echo "export ${KEY}=\"${VAL}\"" >> ${TARGET}
    fi

    . ${HOME}/.bash_profile
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

new_file() {
    ${SUDO} rm -rf $1
    ${SUDO} touch $1

    if [ "$2" != "" ]; then
        ${SUDO} chmod $2 $1
    fi

    if [ "${USER}" != "" ]; then
        ${SUDO} chown ${USER}.${USER} $1
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

not_darwin() {
    if [ "${OS_TYPE}" == "Darwin" ]; then
        warning "Not supported OS - ${OS_TYPE}"
        exit 1
    fi
}

echo_() {
    echo ""
}

echo_bar() {
    echo "================================================================================"
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

################################################################################

toast

# done
success "done."
