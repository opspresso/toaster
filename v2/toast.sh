#!/bin/bash

echo_() {
    echo -e "$1"
    echo "$1" >> /tmp/toast.log
}

success() {
    echo -e "$(tput setaf 2)$1$(tput sgr0)"
    echo "$1" >> /tmp/toast.log
}

warning() {
    echo -e "$(tput setaf 1)$1$(tput sgr0)"
    echo "$1" >> /tmp/toast.log
}

################################################################################

# linux
OS_NAME="$(uname)"
OS_FULL="$(uname -a)"
if [ "${OS_NAME}" == "Linux" ]; then
    if [ $(echo "${OS_FULL}" | grep -c "amzn1") -gt 0 ]; then
        OS_TYPE="amzn1"
    elif [ $(echo "${OS_FULL}" | grep -c "el6") -gt 0 ]; then
        OS_TYPE="el6"
    elif [ $(echo "${OS_FULL}" | grep -c "el7") -gt 0 ]; then
        OS_TYPE="el7"
    elif [ $(echo "${OS_FULL}" | grep -c "Ubuntu") -gt 0 ]; then
        OS_TYPE="Ubuntu"
    elif [ $(echo "${OS_FULL}" | grep -c "generic") -gt 0 ]; then
        OS_TYPE="generic"
    elif [ $(echo "${OS_FULL}" | grep -c "coreos") -gt 0 ]; then
        OS_TYPE="coreos"
    fi
elif [ "${OS_NAME}" == "Darwin" ]; then
    OS_TYPE="${OS_NAME}"
fi

if [ "${OS_TYPE}" == "" ]; then
    warning "${OS_FULL}"
    warning "Not supported OS. [${OS_NAME}][${OS_TYPE}]"
    exit 1
fi

# root
if [ "${HOME}" == "/root" ]; then
    warning "ROOT account is not supported."
    #exit 1
fi

SUDO=""
if [ "${HOME}" != "/root" ]; then
    SUDO="sudo"
fi

################################################################################

SHELL_DIR=$(dirname "$0")

TOAST_URL=
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

HEALTH=

REPO_BUCKET=
REPO_PATH=

EMAIL=

JAR_OPTS=

CONFIG="${HOME}/.toast"
if [ -f "${CONFIG}" ]; then
    source "${CONFIG}"
fi

if [ "${ORG}" != "" ]; then
    TOAST_URL="http://${ORG}.toast.sh"
fi

UUID="$(curl -s http://instance-data/latest/meta-data/instance-id)"
USER="$(whoami)"

################################################################################

CMD=$1

PARAM1=$2
PARAM2=$3
PARAM3=$4
PARAM4=$5
PARAM5=$6
PARAM6=$7
PARAM7=$8

HAS_WAR="FALSE"
HAS_JAR="FALSE"

DATA_DIR="/data"
APPS_DIR="${DATA_DIR}/apps"
LOGS_DIR="${DATA_DIR}/logs"
SITE_DIR="${DATA_DIR}/site"
TEMP_DIR="/tmp"

HTTPD_VERSION="24"

HTTPD_CONF_DIR=
NGINX_CONF_DIR=

TOMCAT_DIR="${APPS_DIR}/tomcat8"
WEBAPP_DIR="${TOMCAT_DIR}/webapps"

TEMP_FILE="${TEMP_DIR}/toast.tmp"

################################################################################

toast() {
    toast_url

    case ${CMD} in
        a|auto)
            auto
            ;;
        u|update)
            update
            ;;
        p|prepare)
            prepare
            ;;
        c|config)
            config
            ;;
        i|init|install)
            init
            ;;
        b|build|version)
            build
            ;;
        v|vhost)
            vhost
            ;;
        d|deploy)
            deploy
            ;;
        k|bucket)
            bucket
            ;;
        t|certbot)
            certbot
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
        reset)
            reset
            ;;
        *)
            usage
    esac
}

auto() {
    not_darwin

    echo_toast

    config_auto
    config_cron

    self_info

    prepare

    repo_path

    init_hosts
    init_profile
    init_email

    init_aws
    init_slave
    init_epel
    init_auto

    #init_startup

    deploy_fleet
    vhost_fleet
    nginx_lb
}

config() {
    echo_toast

    config_auto
    config_cron

    self_info

    prepare
}

update() {
    #config_save

    self_info
    self_update

    certbot_renew

    #service_update
}

init() {
    repo_path

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
        eb)
            init_eb
            ;;
        certbot)
            init_certbot
            ;;
        certificate)
            init_certificate
            ;;
        startup)
            init_startup
            ;;
        httpd)
            init_httpd
            ;;
        nginx)
            init_nginx
            ;;
        php55)
            init_php 55
            ;;
        php56)
            init_php 56
            ;;
        php70)
            init_php 70
            ;;
        node|node4)
            init_node
            ;;
        java|java8)
            init_java 8
            ;;
        java9)
            init_java 9
            ;;
        maven|maven3)
            init_maven 3
            ;;
        tomcat|tomcat8)
            init_tomcat 8
            ;;
        elasticsearch)
            init_elasticsearch
            ;;
        kibana)
            init_kibana
            ;;
        logstash)
            init_logstash
            ;;
        filebeat)
            init_filebeat
            ;;
        mysql)
            init_mysql 55
            ;;
        redis)
            init_redis
            ;;
        docker)
            init_docker
            ;;
        jenkins)
            init_jenkins
            ;;
        *)
            self_info
            init_auto
    esac
}

build() {
    repo_path

    build_parse

    case ${PARAM1} in
        version|next)
            build_version
            ;;
        package)
            build_package
            ;;
        save)
            build_save
            ;;
        lambda)
            build_lambda
            ;;
        bucket)
            build_bucket
            ;;
        docker)
            build_docker
            ;;
        eb)
            build_eb
            ;;
    esac
}

vhost() {
    not_darwin

    self_info

    repo_path

    init_hosts
    init_profile

    case ${PARAM1} in
        lb)
            nginx_lb
            ;;
        dom)
            vhost_dom
            ;;
        *)
            vhost_fleet
    esac
}

deploy() {
    not_darwin

    self_info

    repo_path

    init_hosts
    init_profile

    case ${PARAM1} in
        p|project)
            deploy_project
            ;;
        t|target)
            deploy_target
            ;;
        toast)
            deploy_toast
            ;;
        *)
            deploy_fleet
            vhost_fleet
    esac
}

bucket() {
    not_darwin

    self_info

    repo_path

    deploy_bucket
}

certbot() {
    not_darwin

    case ${PARAM1} in
        a|apache)
            certbot_apache
            ;;
        n|nginx)
            certbot_nginx
            ;;
        d|delete)
            certbot_delete
            ;;
        r|renew)
            certbot_renew
            ;;
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
            log_reduce
    esac
}

################################################################################

self_info() {
    echo_bar
    echo_ "OS    : ${OS_NAME} ${OS_TYPE}"
    echo_ "HOME  : ${HOME}"
    echo_bar
    echo_ "ORG   : ${ORG}"
    echo_ "PHASE : ${PHASE}"
    echo_ "FLEET : ${FLEET}"
    echo_ "NAME  : ${NAME}"
    echo_bar
}

self_update() {
    curl -s toast.sh/install | bash
}

prepare() {
    if [ "${PHASE}" == "local" ]; then
        TARGET="${HOME}/.toast_profile"
        add_source "${TARGET}"

        cp -rf ${SHELL_DIR}/package/default/profile ${TARGET}
        source ${TARGET}

        return
    fi

    command -v git   > /dev/null || service_install git
    command -v curl  > /dev/null || service_install curl
    command -v wget  > /dev/null || service_install wget
    command -v unzip > /dev/null || service_install unzip
    command -v jq    > /dev/null || service_install jq

    # i18n
    language

    # time
    localtime

    # /data
    make_dir "${DATA_DIR}"

    # /data/apps
    make_dir "${APPS_DIR}"

    # /data/logs
    make_dir "${LOGS_DIR}" 777

    # /data/site
    make_dir "${SITE_DIR}"
    make_dir "${SITE_DIR}/localhost"
    make_dir "${SITE_DIR}/cache" 777
    make_dir "${SITE_DIR}/files" 777
    make_dir "${SITE_DIR}/upload" 777
    make_dir "${SITE_DIR}/session" 777
}

config_auto() {
    # port
    if [ -r /etc/ssh/sshd_config ]; then
        SSH=$(cat /etc/ssh/sshd_config | grep -E ^\#?Port)
        if [ "${SSH}" != "" ]; then
            ARR=(${SSH})
            PORT="${ARR[1]}"
        fi
    fi

    # ssh config
    make_dir ${HOME}/.ssh
    copy "${SHELL_DIR}/package/ssh/config.conf" "${HOME}/.ssh/config" 600

    # aws config
    make_dir ${HOME}/.aws
    copy "${SHELL_DIR}/package/aws/config.conf" "${HOME}/.aws/config" 600

    # .toast
    if [ ! -f "${CONFIG}" ]; then
        cp -rf "${SHELL_DIR}/package/toast.conf" "${CONFIG}"
        source "${CONFIG}"
    fi

    #  fleet phase org token
    if [ "${PARAM1}" != "" ]; then
        FLEET="${PARAM1}"
    fi
    if [ "${PARAM2}" != "" ]; then
        PHASE="${PARAM2}"
    fi
    if [ "${PARAM3}" != "" ]; then
        ORG="${PARAM3}"
    fi
    if [ "${PARAM4}" != "" ]; then
        TOKEN="${PARAM4}"
    fi

    if [ "${ORG}" != "" ]; then
        TOAST_URL="http://${ORG}.toast.sh"
    fi

    config_save
    config_info
}

config_save() {
    echo_bar

    if [ "${PHASE}" != "local" ]; then
        if [ "${HEALTH}" == "200" ]; then
            echo_ "config save... [${UUID}][${SNO}]"

            URL="${TOAST_URL}/server/config"
            RES=$(curl -s --data "org=${ORG}&token=${TOKEN}&phase=${PHASE}&fleet=${FLEET}&id=${UUID}&name=${NAME}&host=${HOST}&port=${PORT}&user=${USER}&no=${SNO}" "${URL}")
            ARR=(${RES})

            if [ "${ARR[0]}" != "OK" ]; then
                warning "Server Error. [${URL}][${RES}]"
            else
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
                if [ "${ARR[5]}" != "" ]; then
                    if [ "${ARR[5]}" != "${NAME}" ]; then
                        config_name "${ARR[5]}"
                    fi
                fi
            fi
        fi
    fi

    config_local

    echo_bar
}

config_local() {
    echo_ "config local... [${SNO}][${NAME}]"

    echo "# toast config" > "${CONFIG}"
    echo "TOAST_URL=\"${TOAST_URL}\"" >> "${CONFIG}"
    echo "ORG=\"${ORG}\"" >> "${CONFIG}"
    echo "PHASE=\"${PHASE}\"" >> "${CONFIG}"
    echo "FLEET=\"${FLEET}\"" >> "${CONFIG}"
    echo "UUID=\"${UUID}\"" >> "${CONFIG}"
    echo "NAME=\"${NAME}\"" >> "${CONFIG}"
    echo "HOST=\"${HOST}\"" >> "${CONFIG}"
    echo "PORT=\"${PORT}\"" >> "${CONFIG}"
    echo "USER=\"${USER}\"" >> "${CONFIG}"
    echo "TOKEN=\"${TOKEN}\"" >> "${CONFIG}"
    echo "SNO=\"${SNO}\"" >> "${CONFIG}"

    chmod 644 "${CONFIG}"
    source "${CONFIG}"
}

config_info() {
    if [ ! -f "${CONFIG}" ]; then
        warning "Not exist file. [${CONFIG}]"
        return
    fi
    if [ "${PHASE}" == "local" ]; then
        return
    fi

    echo_bar
    cat "${CONFIG}"
    echo_bar
}

config_name() {
    if [ "${OS_NAME}" != "Linux" ]; then
        return
    fi
    if [ "${PHASE}" == "local" ]; then
        return
    fi
    if [ "$1" == "" ]; then
        return
    fi

    NAME="$1"

    echo_ "hostname... [${NAME}]"

    if [ "${OS_TYPE}" == "el7" ]; then
        ${SUDO} hostnamectl set-hostname "${NAME}"
    elif [ "${OS_TYPE}" == "Ubuntu" ]; then
        ${SUDO} hostnamectl set-hostname "${NAME}"
    else
        ${SUDO} hostname "${NAME}"

        mod_conf /etc/sysconfig/network "HOSTNAME" "${NAME}"

        ${SUDO} /etc/init.d/rsyslog restart
    fi
}

config_cron() {
    if [ "${OS_NAME}" != "Linux" ]; then
        return
    fi
    if [ "${PHASE}" == "local" ]; then
        return
    fi

    TEMP_FILE="${TEMP_DIR}/toast-cron.tmp"

    echo "# toast cron" > ${TEMP_FILE}
    echo "* * * * * ${SHELL_DIR}/toast.sh health > /tmp/toast-cron-health.log " >> ${TEMP_FILE}
    echo "3 2 * * * ${SHELL_DIR}/toast.sh update > /tmp/toast-cron-update.log " >> ${TEMP_FILE}
    echo "6 3 * * * ${SHELL_DIR}/toast.sh log    > /tmp/toast-cron-log.log "    >> ${TEMP_FILE}

    crontab ${TEMP_FILE}

    echo_bar
    crontab -l
    echo_bar
}

init_hosts() {
    if [ "${HEALTH}" != "200" ]; then
        return
    fi

    echo_ "init hosts..."

    TARGET="/etc/hosts"
    TEMP_FILE="${TEMP_DIR}/toast-hosts.tmp"

    # hosts
    URL="${TOAST_URL}/server/hosts/${SNO}"
    RES=$(curl -s --data "org=${ORG}&token=${TOKEN}&no=${SNO}" "${URL}")

    if [ "${RES}" == "" ]; then
        warning "empty hosts. [${URL}]"
        return
    fi

    echo "${RES}" > ${TEMP_FILE}
    copy ${TEMP_FILE} ${TARGET}
}

init_profile() {
    if [ "${HEALTH}" != "200" ]; then
        return
    fi

    echo_ "init profile..."

    TARGET="${HOME}/.toast_profile"
    add_source "${TARGET}"

    # profile
    URL="${TOAST_URL}/server/profile/${SNO}"
    RES=$(curl -s --data "org=${ORG}&token=${TOKEN}&no=${SNO}" "${URL}")

    if [ "${RES}" == "" ]; then
        warning "empty profile. [${URL}]"
        return
    fi

    echo "${RES}" > ${TARGET}
    source ${TARGET}
}

init_email() {
    if [ "${HEALTH}" != "200" ]; then
        return
    fi

    echo_ "init email..."

    URL="${TOAST_URL}/config/key/email"
    RES=$(curl -s --data "org=${ORG}&token=${TOKEN}&no=${SNO}" "${URL}")

    if [ "${RES}" != "" ]; then
        EMAIL="${RES}"
    else
        EMAIL="toast@${ORG}.com"
    fi

    echo "EMAIL=${EMAIL}" > "${SHELL_DIR}/.config_email"
}

init_master() {
    if [ "${HEALTH}" != "200" ]; then
        return
    fi

    echo_ "init master..."

    # .ssh/id_rsa
    URL="${TOAST_URL}/config/key/aws_key_pem"
    RES=$(curl -s --data "org=${ORG}&token=${TOKEN}&no=${SNO}" "${URL}")

    if [ "${RES}" != "" ]; then
        TARGET="${HOME}/.ssh/id_rsa"
        echo "${RES}" > ${TARGET}
        chmod 600 ${TARGET}
    else
        # .ssh/id_rsa
        URL="${TOAST_URL}/config/key/rsa_private_key"
        RES=$(curl -s --data "org=${ORG}&token=${TOKEN}&no=${SNO}" "${URL}")

        if [ "${RES}" != "" ]; then
            TARGET="${HOME}/.ssh/id_rsa"
            echo "${RES}" > ${TARGET}
            chmod 600 ${TARGET}
        fi

        # .ssh/id_rsa.pub
#        URL="${TOAST_URL}/config/key/rsa_public_key"
#        RES=$(curl -s --data "org=${ORG}&token=${TOKEN}&no=${SNO}" "${URL}")
#
#        if [ "${RES}" != "" ]; then
#            TARGET="${HOME}/.ssh/id_rsa.pub"
#            echo "${RES}" > ${TARGET}
#            chmod 644 ${TARGET}
#        fi
    fi

    # .aws/config
    URL="${TOAST_URL}/config/key/aws_config"
    RES=$(curl -s --data "org=${ORG}&token=${TOKEN}&no=${SNO}" "${URL}")

    if [ "${RES}" != "" ]; then
        TARGET="${HOME}/.aws/config"
        echo "${RES}" > ${TARGET}
        chmod 600 ${TARGET}
    fi

    # .aws/credentials
    URL="${TOAST_URL}/config/key/aws_master"
    RES=$(curl -s --data "org=${ORG}&token=${TOKEN}&no=${SNO}" "${URL}")

    if [ "${RES}" != "" ]; then
        TARGET="${HOME}/.aws/credentials"
        echo "${RES}" > ${TARGET}
        chmod 600 ${TARGET}
    fi
}

init_slave() {
    if [ "${HEALTH}" != "200" ]; then
        return
    fi

    echo_ "init slave..."

    # .ssh/id_rsa
    TARGET="${HOME}/.ssh/id_rsa"
    rm -rf ${TARGET}

    # .ssh/id_rsa.pub
    TARGET="${HOME}/.ssh/id_rsa.pub"
    rm -rf ${TARGET}

    # .ssh/authorized_keys
#    TARGET="${HOME}/.ssh/authorized_keys"
#    touch ${TARGET}
#
#    if [ $(cat ${TARGET} | grep -c "admin@toast.sh") -eq 0 ]; then
#        URL="${TOAST_URL}/config/key/rsa_public_key"
#        RES=$(curl -s --data "org=${ORG}&token=${TOKEN}&no=${SNO}" "${URL}")
#
#        if [ "${RES}" != "" ]; then
#            echo "${RES}" >> ${TARGET}
#            chmod 700 ${TARGET}
#        fi
#    fi

    # .aws/config
    URL="${TOAST_URL}/config/key/aws_config"
    RES=$(curl -s --data "org=${ORG}&token=${TOKEN}&no=${SNO}" "${URL}")

    if [ "${RES}" != "" ]; then
        TARGET="${HOME}/.aws/config"
        echo "${RES}" > ${TARGET}
        chmod 600 ${TARGET}
    fi

    # .aws/credentials
    URL="${TOAST_URL}/config/key/aws_slave"
    RES=$(curl -s --data "org=${ORG}&token=${TOKEN}&no=${SNO}" "${URL}")

    if [ "${RES}" != "" ]; then
        TARGET="${HOME}/.aws/credentials"
        echo "${RES}" > ${TARGET}
        chmod 600 ${TARGET}
    fi

    # master
    if [ "${PHASE}" == "build" ]; then
        init_master
    fi
}

init_aws() {
    echo_ "init aws..."

    # aws cli
    if [ ! -f "${SHELL_DIR}/.config_aws" ]; then
        echo_ "init aws cli..."

        wget -q -N https://s3.amazonaws.com/aws-cli/awscli-bundle.zip

        if [ -f "${HOME}/awscli-bundle.zip" ]; then
            unzip -q awscli-bundle.zip

            AWS_HOME="/usr/local/aws"

            ${SUDO} ./awscli-bundle/install -i ${AWS_HOME} -b /usr/bin/aws

            add_path "${AWS_HOME}/bin"

            rm -rf awscli-bundle
            rm -rf awscli-bundle.zip

            touch "${SHELL_DIR}/.config_aws"
        fi
    fi

    echo_bar
    echo_ "$(/usr/bin/aws --version)"
    echo_bar
}

init_eb() {
    echo_ "init eb..."

    # /data
    make_dir "${DATA_DIR}"

    # /data/apps
    make_dir "${APPS_DIR}"

    # /data/logs
    make_dir "${LOGS_DIR}" 777

    init_logstash
}

init_certbot() {
    echo_ "init certbot..."

    BOT_URL="https://dl.eff.org/certbot-auto"
    BOT_DIR="${HOME}/certbot"
    BOT_BIN="${BOT_DIR}/certbot-auto"

    if [ ! -d ${BOT_DIR} ]; then
        mkdir "${BOT_DIR}"
    fi

    curl -s -o "${BOT_BIN}" "${BOT_URL}"

    if [ -f ${BOT_BIN} ]; then
        chmod a+x ${BOT_BIN}
        touch "${SHELL_DIR}/.config_certbot"
    fi
}

init_certificate() {
    if [ "${HEALTH}" != "200" ]; then
        return
    fi

    if [ "$1" == "" ]; then
        CERT_NAME="${PARAM2}"
    else
        CERT_NAME="$1"
    fi

    if [ "${CERT_NAME}" == "" ]; then
        warning "Not set CERT_NAME."
        return
    fi

    echo_ "init certificate... [${CERT_NAME}]"

    SSL_DIR="/data/conf"
    make_dir "${SSL_DIR}"

    SSL_NAME=
    SSL_INFO="${SSL_DIR}/info"

    if [ -f ${SSL_INFO} ]; then
        source ${SSL_INFO}
    fi

    CERTIFICATE="${TEMP_DIR}/${CERT_NAME}"

    URL="${TOAST_URL}/certificate/name/${CERT_NAME}"
    wget -q -N --post-data "org=${ORG}&token=${TOKEN}&no=${SNO}" -P "${TEMP_DIR}" "${URL}"

    if [ -f ${CERTIFICATE} ]; then
        echo_ "save certificate..."

        SSL_TARGET=

        while read LINE; do
            ARR=(${LINE})

            if [ "${ARR[0]}" == "#" ]; then
                SSL_TARGET="${SSL_DIR}/${ARR[1]}"
                new_file ${SSL_TARGET} 600
            else
                if [ -w ${SSL_TARGET} ]; then
                    echo "${LINE}" >> ${SSL_TARGET}
                fi
            fi
        done < ${CERTIFICATE}

        echo "SSL_NAME=${CERT_NAME}" > ${SSL_INFO}
    fi
}

init_startup() {
    TARGET="/etc/rc.d/rc.local"

    RC_HEAD="# toast auto"

    HAS_LINE="false"

    while read LINE; do
        if [ "${LINE}" == "${RC_HEAD}" ]; then
            HAS_LINE="true"
        fi
    done < ${TARGET}

    if [ "${HAS_LINE}" == "false" ]; then
        TEMP_FILE="${TEMP_DIR}/toast-service.tmp"

        copy ${TARGET} ${TEMP_FILE}

        echo "" >> ${TEMP_FILE}
        echo "${RC_HEAD}" >> ${TEMP_FILE}
        echo "/sbin/runuser -l ${USER} -c '/home/${USER}/toaster/toast.sh update'" >> ${TEMP_FILE}
        echo "/sbin/runuser -l ${USER} -c '/home/${USER}/toaster/toast.sh auto'" >> ${TEMP_FILE}
        echo "" >> ${TEMP_FILE}

        copy ${TEMP_FILE} ${TARGET} 755
    fi
}

init_auto() {
    if [ "${HEALTH}" != "200" ]; then
        return
    fi

    URL="${TOAST_URL}/server/apps/${SNO}"
    RES=$(curl -s --data "org=${ORG}&token=${TOKEN}&no=${SNO}" "${URL}")
    ARR=(${RES})

    for VAL in "${ARR[@]}"; do
        case "${VAL}" in
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
                init_java 8
                ;;
            java9)
                init_java 9
                ;;
            tomcat|tomcat8)
                init_tomcat 8
                ;;
            mysql55)
                init_mysql 55
                ;;
            mysql|mysql56)
                init_mysql 56
                ;;
            redis)
                init_redis
                ;;
        esac
    done
}

init_script() {
    if [ "${HEALTH}" != "200" ]; then
        return
    fi

    TARGET="${HOME}/.toast_script"

    # script
    URL="${TOAST_URL}/server/script/${SNO}"
    RES=$(curl -s --data "org=${ORG}&token=${TOKEN}&no=${SNO}" "${URL}")

    if [ "${RES}" != "" ]; then
        echo "${RES}" > ${TARGET}
        chmod 755 ${TARGET}
    fi
}

init_epel() {
    if [ -f "${SHELL_DIR}/.config_epel" ]; then
        return 1
    fi

    service_install yum-utils

    if [ "${OS_TYPE}" == "el7" ]; then
        ${SUDO} rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
    else
        ${SUDO} rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm
    fi

    ${SUDO} yum-config-manager --enable epel

    touch "${SHELL_DIR}/.config_epel"
}

init_webtatic() {
    if [ -f "${SHELL_DIR}/.config_webtatic" ]; then
        return 1
    fi

    status=$(${SUDO} yum list | grep php56 | wc -l | awk '{print $1}')

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
        echo_ "init httpd..."

        service_install "openssl openssl-devel"

        status=$(${SUDO} yum list | grep httpd24 | wc -l | awk '{print $1}')

        if [ ${status} -ge 1 ]; then
            service_install "httpd24"
        else
            service_install "httpd"
        fi

        VERSION=$(httpd -version | grep -o "Apache\/2.4")

        if [ "${VERSION}" != "" ]; then
            HTTPD_VERSION="24"
        else
            HTTPD_VERSION="22"
        fi

        touch "${SHELL_DIR}/.config_httpd"

        custom_httpd_conf

        vhost_local

        echo_ "httpd start..."
        service_ctl httpd start on

        echo "HTTPD_VERSION=${HTTPD_VERSION}" >> "${SHELL_DIR}/.config_httpd"
        echo "HTTPD_CONF_DIR=${HTTPD_CONF_DIR}" >> "${SHELL_DIR}/.config_httpd"
    fi

    echo_bar
    echo_ "$(httpd -version)"
    echo_bar
}

init_nginx() {
    if [ ! -f "${SHELL_DIR}/.config_nginx" ]; then
        echo_ "init nginx..."

        ${SHELL_DIR}/install/nginx.sh "${REPO_PATH}"

        NGINX_HOME="/usr/local/nginx"

        if [ ! -d ${NGINX_HOME} ]; then
            warning "Can not found : NGINX_HOME=${NGINX_HOME}"
            exit 1
        fi

        touch "${SHELL_DIR}/.config_nginx"

        nginx_local

        echo_ "nginx start..."
        ${SUDO} nginx

        echo "NGINX_CONF_DIR=${NGINX_CONF_DIR}" >> "${SHELL_DIR}/.config_nginx"
    fi

    echo_bar
    echo_ "$(nginx -v)"
    echo_bar
}

init_php() {
    if [ ! -f "${SHELL_DIR}/.config_php" ]; then
        init_webtatic

        VERSION="$1"

        if [ "${VERSION}" == "" ]; then
            VERSION="56"
        fi

        echo_ "init php${VERSION}..."

        status=$(${SUDO} yum list | grep php${VERSION}w | wc -l | awk '{print $1}')

        if [ ${status} -ge 1 ]; then
            service_install "php${VERSION}w php${VERSION}w-mysqlnd php${VERSION}w-mcrypt php${VERSION}w-gd php${VERSION}w-mbstring php${VERSION}w-bcmath"
        else
            service_install "php${VERSION} php${VERSION}-mysqlnd php${VERSION}-mcrypt php${VERSION}-gd php${VERSION}-mbstring php${VERSION}-bcmath"
        fi

        custom_php_ini

        httpd_restart

        echo "PHP_VERSION=${VERSION}" > "${SHELL_DIR}/.config_php"
    fi

    echo_bar
    echo_ "$(php -version)"
    echo_bar
}

init_node() {
    if [ ! -f "${SHELL_DIR}/.config_node" ]; then
        echo_ "init node..."

        ${SHELL_DIR}/install/node.sh "${REPO_PATH}"

        NODE_HOME="/usr/local/node"

        if [ ! -d ${NODE_HOME} ]; then
            warning "Can not found : NODE_HOME=${NODE_HOME}"
            exit 1
        fi

        add_path "${NODE_HOME}/bin"
        mod_env "NODE_HOME" "${NODE_HOME}"

        echo "NODE_HOME=${NODE_HOME}"
        echo "NODE_HOME=${NODE_HOME}" > "${SHELL_DIR}/.config_node"
    fi

    echo_bar
    echo_ "node version $(node -v)"
    echo_ "npm version $(npm -v)"
    echo_bar
}

init_java() {
    make_dir "${APPS_DIR}"

    if [ ! -f "${SHELL_DIR}/.config_java" ]; then
        VERSION="$1"

        if [ "${VERSION}" == "" ]; then
            VERSION="8"
        fi

        echo_ "init java${VERSION}..."

        ${SHELL_DIR}/install/java${VERSION}.sh

        JAVA_HOME="/usr/java/default"

        #add_path "${JAVA_HOME}/bin"
        #mod_env "JAVA_HOME" "${JAVA_HOME}"

        echo "JAVA_HOME=${JAVA_HOME}"
        echo "JAVA_HOME=${JAVA_HOME}" > "${SHELL_DIR}/.config_java"
    fi

    echo_bar
    echo_ "$(java -version)"
    echo_bar
}

init_maven() {
    make_dir "${APPS_DIR}"

    if [ ! -f "${SHELL_DIR}/.config_maven" ]; then
        VERSION="$1"

        if [ "${VERSION}" == "" ]; then
            VERSION="3"
        fi

        echo_ "init maven${VERSION}..."

        ${SHELL_DIR}/install/maven${VERSION}.sh "${REPO_PATH}"

        MAVEN_HOME="${APPS_DIR}/maven${VERSION}"

        if [ ! -d ${MAVEN_HOME} ]; then
            warning "Can not found : MAVEN_HOME=${MAVEN_HOME}"
            exit 1
        fi

        add_path "${MAVEN_HOME}/bin"
        mod_env "MAVEN_HOME" "${MAVEN_HOME}"

        echo "MAVEN_HOME=${MAVEN_HOME}"
        echo "MAVEN_HOME=${MAVEN_HOME}" > "${SHELL_DIR}/.config_maven"
    fi
}

init_tomcat() {
    make_dir "${APPS_DIR}"

    if [ ! -f "${SHELL_DIR}/.config_tomcat" ]; then
        VERSION="$1"

        if [ "${VERSION}" == "" ]; then
            VERSION="8"
        fi

        echo_ "init tomcat${VERSION}..."

        ${SHELL_DIR}/install/tomcat${VERSION}.sh "${REPO_PATH}"

        CATALINA_HOME="${APPS_DIR}/tomcat${VERSION}"

        if [ ! -d ${CATALINA_HOME} ]; then
            warning "Can not found : CATALINA_HOME=${CATALINA_HOME}"
            exit 1
        fi

        mod_env "CATALINA_HOME" "${CATALINA_HOME}"

        cp -rf "${CATALINA_HOME}/conf/web.xml" "${CATALINA_HOME}/conf/web.org.xml"
        cp -rf "${SHELL_DIR}/package/tomcat/web.xml" "${CATALINA_HOME}/conf/web.xml"

        echo "CATALINA_HOME=${CATALINA_HOME}"
        echo "CATALINA_HOME=${CATALINA_HOME}" > "${SHELL_DIR}/.config_tomcat"
    fi
}

init_elasticsearch() {
    echo_ "init elasticsearch..."

    ${SHELL_DIR}/install/elasticsearch.sh

    echo_bar
}

init_kibana() {
    echo_ "init kibana..."

    ${SHELL_DIR}/install/kibana.sh

    echo_bar
}

init_logstash() {
    echo_ "init logstash..."

    ${SHELL_DIR}/install/logstash.sh

    echo_bar
}

init_filebeat() {
    echo_ "init filebeat..."

    ${SHELL_DIR}/install/filebeat.sh

    echo_bar
}

init_mysql() {
    if [ ! -f "${SHELL_DIR}/.config_mysql" ]; then
        VERSION="$1"

        if [ "${VERSION}" == "" ]; then
            VERSION="56"
        fi

        echo_ "init mysql${VERSION}..."

        service_install mysql${VERSION}-server

        service_ctl mysqld start on

        touch "${SHELL_DIR}/.config_mysql"
    fi
}

init_redis() {
    if [ ! -f "${SHELL_DIR}/.config_redis" ]; then
        echo_ "init redis..."

        service_install redis

        service_ctl redis start on

        touch "${SHELL_DIR}/.config_redis"
    fi
}

init_docker() {
    if [ ! -f "${SHELL_DIR}/.config_docker" ]; then
        echo_ "init docker..."

        service_install docker

        service_ctl docker start on

        touch "${SHELL_DIR}/.config_docker"
    fi
}

init_jenkins() {
    if [ ! -f "${SHELL_DIR}/.config_tomcat" ]; then
        warning "Not set Tomcat."
        return 1
    fi

    HAS_WAR="TRUE"

    tomcat_stop

    rm -rf "${WEBAPP_DIR}/jenkins.war"
    rm -rf "${WEBAPP_DIR}/jenkins"

    echo_ "download jenkins..."

    # jenkins
    URL="http://mirrors.jenkins.io/war/latest/jenkins.war"
    wget -q -N -P "${WEBAPP_DIR}" "${URL}"

    cp -rf "${CATALINA_HOME}/conf/web.org.xml" "${CATALINA_HOME}/conf/web.xml"

    # composer
    if ! command -v composer > /dev/null; then
        curl -sS https://getcomposer.org/installer | php
        sudo mv composer.phar /usr/local/bin/composer
    fi
    # swagger
    if command -v composer > /dev/null; then
        composer global require zircote/swagger-php
    fi

    tomcat_start
}

custom_httpd_conf() {
    if [ -f "/etc/httpd/conf/httpd.conf" ]; then
        HTTPD_CONF="/etc/httpd/conf/httpd.conf"
    else
        if [ -f "/usr/local/apache/conf/httpd.conf" ]; then
            HTTPD_CONF="/usr/local/apache/conf/httpd.conf"
        fi
    fi

    if [ -f ${HTTPD_CONF} ]; then
        echo_ "${HTTPD_CONF}"

        TEMP_FILE="${TEMP_DIR}/toast-httpd-conf.tmp"

        # User apache
        sed "s/User\ apache/User\ $USER/g" ${HTTPD_CONF} > ${TEMP_FILE}
        copy ${TEMP_FILE} ${HTTPD_CONF}

        # Group apache
        sed "s/Group\ apache/Group\ $USER/g" ${HTTPD_CONF} > ${TEMP_FILE}
        copy ${TEMP_FILE} ${HTTPD_CONF}
    fi
}

custom_php_ini() {
    if [ -f "/etc/php.ini" ]; then
        PHP_INI="/etc/php.ini"
    fi

    if [ -f ${PHP_INI} ]; then
        echo_ "${PHP_INI}"

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

        # upload_max_filesize = 20M
        sed "s/\;upload\_max\_filesize\ \=\ 2M/upload\_max\_filesize\ \=\ 20M/g" ${PHP_INI} > ${TEMP_FILE}
        copy ${TEMP_FILE} ${PHP_INI} 644
    fi
}

build_parse() {
    POM_FILE="pom.xml"

    if [ ! -f "${POM_FILE}" ]; then
        warning "Not exist file. [${POM_FILE}]"
        return
    fi

    ARR_GROUP=($(cat ${POM_FILE} | grep -oP '(?<=groupId>)[^<]+'))
    ARR_ARTIFACT=($(cat ${POM_FILE} | grep -oP '(?<=artifactId>)[^<]+'))
    ARR_VERSION=($(cat ${POM_FILE} | grep -oP '(?<=version>)[^<]+'))
    ARR_PACKAGING=($(cat ${POM_FILE} | grep -oP '(?<=packaging>)[^<]+'))

    if [ "${ARR_GROUP[0]}" == "" ]; then
        warning "Not set groupId."
        exit 1
    fi
    if [ "${ARR_ARTIFACT[0]}" == "" ]; then
        warning "Not set artifactId."
        exit 1
    fi

    GROUP_ID="${ARR_GROUP[0]}"
    ARTIFACT_ID="${ARR_ARTIFACT[0]}"
    VERSION="${ARR_VERSION[0]}"
    PACKAGING="${ARR_PACKAGING[0]}"
    PACKAGE="${PARAM2}"

    echo_ "groupId=${GROUP_ID}"
    echo_ "artifactId=${ARTIFACT_ID}"
    echo_ "version=${VERSION}"
    echo_ "packaging=${PACKAGING}"

    GROUP_PATH=$(echo "${GROUP_ID}" | sed "s/\./\//")
}

build_version() {
    if [ "${ARTIFACT_ID}" == "" ]; then
        warning "Not set ARTIFACT_ID."
        return
    fi

    BRANCH="${PARAM2}"

    if [ "${BRANCH}" == "" ]; then
        BRANCH="master"
    fi

    echo "${BRANCH}" > .git_branch
    echo_ "branch... [${BRANCH}]"

    if [ "${HEALTH}" != "200" ]; then
        return
    fi

    URL="${TOAST_URL}/version/latest/${ARTIFACT_ID}"
    RES=$(curl -s --data "org=${ORG}&token=${TOKEN}&groupId=${GROUP_ID}&artifactId=${ARTIFACT_ID}&packaging=${PACKAGE}&no=${SNO}&branch=${BRANCH}" "${URL}")
    ARR=(${RES})

    if [ "${ARR[0]}" != "OK" ]; then
        warning "Server Error. [${URL}][${RES}]"
        return
    fi

    if [ "${BRANCH}" == "master" ]; then
        VERSION="${ARR[1]}"

        replace_version
    fi

    if [ "${ARR[2]}" != "" ]; then
        echo "${ARR[2]}" > .git_id
        echo_ "git id... [${ARR[2]}]"
    fi
}

build_package() {
    if [ "${ARTIFACT_ID}" == "" ]; then
        warning "Not set ARTIFACT_ID."
        return
    fi
    if [ ! -d src/main/webapp ]; then
        warning "Not set SOURCE_DIR."
        return
    fi

    if [ ! -d "target" ]; then
        mkdir "target"
    fi

    pushd src/main/webapp

    COUNT1=($(ls -l | wc -l))
    COUNT2=($(ls -al | wc -l))
    COUNT0=$(expr ${COUNT2[0]} - ${COUNT1[0]})

    if [ "${COUNT0}" != "2" ]; then
        zip -q -r ../../../target/${ARTIFACT_ID}-${VERSION}.${PACKAGING} * .*
    else
        zip -q -r ../../../target/${ARTIFACT_ID}-${VERSION}.${PACKAGING} *
    fi

    popd
}

build_save() {
    if [ "${ARTIFACT_ID}" == "" ]; then
        warning "Not set ARTIFACT_ID."
        return
    fi

    POM_FILE="pom.xml"
    if [ -f "${POM_FILE}" ]; then
        cp -rf "${POM_FILE}" "target/${ARTIFACT_ID}-${VERSION}.pom"
    fi

    # upload
    if [ "${PARAM3}" != "none" ]; then
        echo_ "package upload..."

        upload_repo "zip"
        upload_repo "war"
        upload_repo "jar"
        upload_repo "pom"

        echo_ "package uploaded."
    fi

    BRANCH="$(cat .git_branch)"

    # tag
    if [ "${BRANCH}" == "master" ] && [ "${VERSION}" != "0.0.0" ]; then
        echo_ "version tag... [${VERSION}]"

        DATE=$(date "+%Y-%m-%d %H:%M")

        git config --global user.name  "toast"
        git config --global user.email "admin@toast.sh"

        git tag -a "${VERSION}" -m "at ${DATE} by toast"
        git push origin "${VERSION}"
    fi

    build_note

    if [ "${PHASE}" == "local" ]; then
        return
    fi

    GIT_ID="$(cat .git_id)"

    GIT_URL="$(git config --get remote.origin.url)"

    NOTE="$(cat target/.git_note)"

    if [ "${HEALTH}" != "200" ]; then
        return
    fi

    # version save
    URL="${TOAST_URL}/version/build/${ARTIFACT_ID}/${VERSION}"
    RES=$(curl -s --data "org=${ORG}&token=${TOKEN}&groupId=${GROUP_ID}&artifactId=${ARTIFACT_ID}&packaging=${PACKAGE}&no=${SNO}&url=${GIT_URL}&git=${GIT_ID}&branch=${BRANCH}&note=${NOTE}" "${URL}")
    ARR=(${RES})

    if [ "${ARR[0]}" != "OK" ]; then
        warning "Server Error. [${URL}][${RES}]"
    fi
}

build_lambda() {
    if [ "${ARTIFACT_ID}" == "" ]; then
        warning "Not set ARTIFACT_ID."
        return
    fi

    PACKAGE_PATH="target"

    UPLOAD_PATH="${REPO_PATH}/maven2/${GROUP_PATH}/${ARTIFACT_ID}/"

    echo_ "--> from: ${PACKAGE_PATH}"
    echo_ "--> to  : ${UPLOAD_PATH}"

    OPTION="--quiet"

    aws s3 sync "${PACKAGE_PATH}" "${UPLOAD_PATH}" ${OPTION}
}

build_bucket() {
    if [ "${ARTIFACT_ID}" == "" ]; then
        warning "Not set ARTIFACT_ID."
        return
    fi
    if [ "${PARAM2}" == "" ]; then
        warning "Not set BUCKET."
        return
    fi

    PACKAGE_PATH="target/${ARTIFACT_ID}-${VERSION}"

    unzip -q "${PACKAGE_PATH}.${PACKAGING}" -d "${PACKAGE_PATH}"

    if [ ! -d ${PACKAGE_PATH} ]; then
        warning "Not set PACKAGE_PATH."
        return
    fi

    DEPLOY_PATH="s3://${PARAM2}"

    OPTION="--quiet"

    aws s3 sync "${PACKAGE_PATH}" "${DEPLOY_PATH}" ${OPTION}
}

build_docker() {
    if [ "${ARTIFACT_ID}" == "" ]; then
        warning "Not set ARTIFACT_ID."
        return
    fi

    if [ ! -d "target/docker" ]; then
        mkdir "target/docker"
    fi

    # ROOT.${packaging}
    cp -rf "target/${ARTIFACT_ID}-${VERSION}.${PACKAGING}" "target/docker/ROOT.${PACKAGING}"

    # Dockerfile
    if [ -f "Dockerfile" ]; then
        cp -rf "Dockerfile" "target/docker/Dockerfile"
    else
        cp -rf "${SHELL_DIR}/package/docker/Dockerfile" "target/docker/Dockerfile"
    fi

    # Dockerrun
    if [ -f "Dockerrun.aws.json" ]; then
        cp -rf "Dockerrun.aws.json" "target/docker/Dockerrun.aws.json"
    else
        cp -rf "${SHELL_DIR}/package/docker/Dockerrun.aws.json" "target/docker/Dockerrun.aws.json"
    fi

    FILES="ROOT.${PACKAGING} Dockerfile Dockerrun.aws.json "

    # .ebextensions
    if [ -d ".ebextensions" ]; then
        cp -rf ".ebextensions" "target/docker/.ebextensions"
        FILES="${FILES} .ebextensions"
    fi

    pushd target/docker

    zip -q -r ../${ARTIFACT_ID}-${VERSION}.zip ${FILES}

    popd

    build_save
}

build_eb() {
    if [ "${ARTIFACT_ID}" == "" ]; then
        warning "Not set ARTIFACT_ID."
        return
    fi

    EB_PACK="${PARAM2}"
    if [ "${EB_PACK}" == "" ]; then
        EB_PACK="zip"
    fi

    if [ "${EB_PACK}" == "zip" ]; then
        if [ ! -d "target/docker" ]; then
            build_docker
        fi
    else
        build_save
    fi

    STAMP=$(date "+%y%m%d-%H%M")

    aws elasticbeanstalk create-application-version \
     --application-name "${ARTIFACT_ID}" \
     --version-label "${VERSION}-${STAMP}" \
     --description "${GIT_ID} (${BRANCH})" \
     --source-bundle S3Bucket="${REPO_BUCKET}",S3Key="maven2/${GROUP_PATH}/${ARTIFACT_ID}/${VERSION}/${ARTIFACT_ID}-${VERSION}.${EB_PACK}" \
     --auto-create-application
}

build_note() {
    NEW_ID=""
    OLD_ID=""

    if [ -r .git_id ]; then
        OLD_ID="$(cat .git_id)"
    fi

    > target/.git_note

    git log --pretty=format:"%h.- %s" --since=1week | grep -v "\- Merge pull request " | grep -v "\- Merge branch " | grep -v "\- Merge remote-tracking " > target/.git_log

    while read LINE; do
        GIT_ID=$(echo ${LINE} | cut -d'.' -f 1)

        if [ "${NEW_ID}" == "" ]; then
            NEW_ID="${GIT_ID}"
        fi

        if [ "${OLD_ID}" == "${GIT_ID}" ]; then
            break
        fi

        echo "${LINE#*.}" >> target/.git_note
    done < target/.git_log

    echo "${NEW_ID}" > .git_id
}

replace_version() {
    if [ "${VERSION}" == "" ]; then
        return
    fi

    echo_ "version=${VERSION}"

    VER1="<version>[0-9a-zA-Z\.\-]\+<\/version>"
    VER2="<version>${VERSION}<\/version>"

    TEMP_FILE="${TEMP_DIR}/toast-pom.tmp"

    if [ -f ${POM_FILE} ]; then
        sed "s/$VER1/$VER2/;10q;" ${POM_FILE} > ${TEMP_FILE}
        sed "1,10d" ${POM_FILE} >> ${TEMP_FILE}

        cp -rf ${TEMP_FILE} ${POM_FILE}
    fi
}

upload_repo() {
    EXT="$1"

    PACKAGE_PATH="target/${ARTIFACT_ID}-${VERSION}.${EXT}"

    if [ ! -f "${PACKAGE_PATH}" ]; then
        return
    fi

    UPLOAD_PATH="${REPO_PATH}/maven2/${GROUP_PATH}/${ARTIFACT_ID}/${VERSION}/"

    echo_ "--> from: ${PACKAGE_PATH}"
    echo_ "--> to  : ${UPLOAD_PATH}"

    if [ "${PARAM3}" == "public" ]; then
        OPTION="--quiet --acl public-read"
    else
        OPTION="--quiet"
    fi

    aws s3 cp "${PACKAGE_PATH}" "${UPLOAD_PATH}" ${OPTION}
}

nginx_dir() {
    TOAST_NGINX="${SHELL_DIR}/.config_nginx"
    if [ -f "${TOAST_NGINX}" ]; then
        source ${TOAST_NGINX}
    fi

    NGINX_BIN_PATH=""
    NGINX_CONF_DIR=""

    if [ -f "/usr/local/nginx/conf/nginx.conf" ]; then
        NGINX_BIN_PATH="/usr/sbin/nginx"
        NGINX_CONF_DIR="/usr/local/nginx/conf"
    fi
}

httpd_dir() {
    TOAST_APACHE="${SHELL_DIR}/.config_httpd"
    if [ -f "${TOAST_APACHE}" ]; then
        source ${TOAST_APACHE}
    fi

    if [ "${HTTPD_VERSION}" == "" ]; then
        HTTPD_VERSION="24"
    fi

    HTTPD_BIN_PATH=""
    HTTPD_CONF_DIR=""

    if [ -d "/etc/httpd/conf.d" ]; then
        HTTPD_CONF_DIR="/etc/httpd/conf.d"
    else
        if [ -d "/usr/local/apache/conf/conf.d" ]; then
            HTTPD_CONF_DIR="/usr/local/apache/conf/conf.d"
        else
            if [ -d "/usr/local/apache/conf/extra" ]; then
                HTTPD_CONF_DIR="/usr/local/apache/conf/extra"
            fi
        fi
        if [ "${HTTPD_CONF_DIR}" != "" ]; then
            HTTPD_BIN_PATH="/usr/local/apache/bin/apachectl"
        fi
    fi
}

nginx_lb() {
    if [ "${HEALTH}" != "200" ]; then
        return
    fi

    nginx_dir

    if [ "${NGINX_CONF_DIR}" == "" ]; then
        return
    fi

    TEMP_FILE="${TEMP_DIR}/toast-lb.tmp"
    TARGET="${NGINX_CONF_DIR}/nginx.conf"

    echo_bar
    echo_ "nginx lb... [${SNO}]"

    TARGET_DIR="${TEMP_DIR}/conf"
    mkdir -p ${TARGET_DIR}

    LB_CONF="${TARGET_DIR}/${SNO}"
    rm -rf ${LB_CONF}

    URL="${TOAST_URL}/server/lb/${SNO}"
    wget -q -N --post-data "org=${ORG}&token=${TOKEN}&no=${SNO}" -P "${TARGET_DIR}" "${URL}"

    if [ -f ${LB_CONF} ]; then
        echo_ "$(cat ${LB_CONF})"

        TEMP_TEMP1="${TARGET_DIR}/toast-lb-temp1.tmp"
        TEMP_TEMP2="${TARGET_DIR}/toast-lb-temp2.tmp"

        TEMP_HTTP="${TARGET_DIR}/toast-lb-http.tmp"
        TEMP_SSL="${TARGET_DIR}/toast-lb-ssl.tmp"
        TEMP_TCP="${TARGET_DIR}/toast-lb-tcp.tmp"

        TEMP_CUSTOM="${TARGET_DIR}/toast-lb-custom.tmp"

        rm -rf "${TEMP_FILE}" "${TEMP_HTTP}" "${TEMP_SSL}" "${TEMP_TCP}" "${TEMP_CUSTOM}"

        while read LINE; do
            ARR=(${LINE})

            if [ "${ARR[0]}" == "NO" ]; then
                FNO="${ARR[1]}"
                continue
            fi

            if [ "${ARR[0]}" == "SSL" ]; then
                SSL="${ARR[1]}"

                if [ "${SSL}" != "" ]; then
                    init_certificate "${SSL}"
                fi

                continue
            fi

            if [ "${ARR[0]}" == "CUSTOM" ]; then
                CUSTOM="${ARR[1]}"

                if [ "${CUSTOM}" != "" ]; then
                    URL="${TOAST_URL}/fleet/custom/${FNO}"
                    RES=$(curl -s --data "org=${ORG}&token=${TOKEN}&no=${SNO}" "${URL}")

                    if [ "${RES}" != "" ]; then
                        echo "${RES}" > ${TEMP_CUSTOM}
                    fi
                fi

                continue
            fi

            if [ "${ARR[0]}" == "FLEET" ]; then
                TNO="${ARR[1]}"
                HOST_ARR=
                DOM_ARR=
                continue
            fi

            if [ "${ARR[0]}" == "HOST" ]; then
                HOST_ARR=(${LINE:5})
                continue
            fi

            if [ "${ARR[0]}" == "DOM" ]; then
                DOM_ARR=(${LINE:4})
                continue
            fi

            if [ "${ARR[0]}" == "HTTP" ]; then
                PORT="${ARR[1]}"

                for DOMAIN in "${DOM_ARR[@]}"; do
                    SERVER=$(echo "${DOMAIN}" | sed "s/\./\_/g")

                    echo "    upstream ${SERVER} {" >> ${TEMP_HTTP}
                    for HOST in "${HOST_ARR[@]}"; do
                       echo "        server ${HOST}:${PORT} max_fails=3 fail_timeout=10s;" >> ${TEMP_HTTP}
                    done
#                    echo "        keepalive 200;" >> ${TEMP_HTTP}
                    echo "    }" >> ${TEMP_HTTP}

                    if [ "${CUSTOM}" == "S" ]; then
                        TEMPLATE="${SHELL_DIR}/package/nginx/nginx-http-server-redirect.conf"
                        sed "s/SERVER/$SERVER/g" ${TEMPLATE} > ${TEMP_TEMP1}
                        sed "s/DOMAIN/$DOMAIN/g" ${TEMP_TEMP1} > ${TEMP_TEMP2}
                        sed "s/PORT/$PORT/g" ${TEMP_TEMP2} >> ${TEMP_HTTP}
                    else
                        TEMPLATE="${SHELL_DIR}/package/nginx/nginx-http-server-domain.conf"
                        if [ -f "${TEMP_CUSTOM}" ]; then
                            sed "s/SERVER/$SERVER/g" ${TEMPLATE} > ${TEMP_TEMP1}
                            sed "s/DOMAIN/$DOMAIN/g" ${TEMP_TEMP1} > ${TEMP_TEMP2}
                            sed "s/PORT/$PORT/;5q;" ${TEMP_TEMP2} >> ${TEMP_HTTP}
                            sed "s/SERVER/$SERVER/g" ${TEMP_CUSTOM} >> ${TEMP_HTTP}
                            echo "" >> ${TEMP_HTTP}
                            sed "1,9d" ${TEMP_TEMP2} >> ${TEMP_HTTP}
                        else
                            sed "s/SERVER/$SERVER/g" ${TEMPLATE} > ${TEMP_TEMP1}
                            sed "s/DOMAIN/$DOMAIN/g" ${TEMP_TEMP1} > ${TEMP_TEMP2}
                            sed "s/PORT/$PORT/g" ${TEMP_TEMP2} >> ${TEMP_HTTP}
                        fi
                    fi

                    # domain-in.com
                    IN="${DOMAIN}"
                    IN=$(echo "${IN}" | sed "s/yanolja\.com/yanolja-in\.com/")
                    IN=$(echo "${IN}" | sed "s/yanoljanow\.com/yanoljanow-in\.com/")

                    if [ "${DOMAIN}" != "${IN}" ]; then
                        DOMAIN="${IN}"

                        TEMPLATE="${SHELL_DIR}/package/nginx/nginx-http-server-domain.conf"
                        if [ -f "${TEMP_CUSTOM}" ]; then
                            sed "s/SERVER/$SERVER/g" ${TEMPLATE} > ${TEMP_TEMP1}
                            sed "s/DOMAIN/$DOMAIN/g" ${TEMP_TEMP1} > ${TEMP_TEMP2}
                            sed "s/PORT/$PORT/;5q;" ${TEMP_TEMP2} >> ${TEMP_HTTP}
                            sed "s/SERVER/$SERVER/g" ${TEMP_CUSTOM} >> ${TEMP_HTTP}
                            echo "" >> ${TEMP_HTTP}
                            sed "1,9d" ${TEMP_TEMP2} >> ${TEMP_HTTP}
                        else
                            sed "s/SERVER/$SERVER/g" ${TEMPLATE} > ${TEMP_TEMP1}
                            sed "s/DOMAIN/$DOMAIN/g" ${TEMP_TEMP1} > ${TEMP_TEMP2}
                            sed "s/PORT/$PORT/g" ${TEMP_TEMP2} >> ${TEMP_HTTP}
                        fi
                    fi

                    echo "" >> ${TEMP_HTTP}
                done

                continue
            fi

            if [ "${ARR[0]}" == "HTTPS" ]; then
                PORT="${ARR[1]}"

                for DOMAIN in "${DOM_ARR[@]}"; do
                    SERVER=$(echo "${DOMAIN}" | sed "s/\./\_/g")

                    TEMPLATE="${SHELL_DIR}/package/nginx/nginx-http-ssl-domain.conf"
                    if [ -f "${TEMP_CUSTOM}" ]; then
                        sed "s/SERVER/$SERVER/g" ${TEMPLATE} > ${TEMP_TEMP1}
                        sed "s/DOMAIN/$DOMAIN/g" ${TEMP_TEMP1} > ${TEMP_TEMP2}
                        sed "s/PORT/$PORT/;5q;" ${TEMP_TEMP2} >> ${TEMP_SSL}
                        sed "s/SERVER/$SERVER/g" ${TEMP_CUSTOM} >> ${TEMP_SSL}
                        echo "" >> ${TEMP_SSL}
                        sed "1,9d" ${TEMP_TEMP2} >> ${TEMP_SSL}
                    else
                        sed "s/SERVER/$SERVER/g" ${TEMPLATE} > ${TEMP_TEMP1}
                        sed "s/DOMAIN/$DOMAIN/g" ${TEMP_TEMP1} > ${TEMP_TEMP2}
                        sed "s/PORT/$PORT/g" ${TEMP_TEMP2} >> ${TEMP_SSL}
                    fi

                    echo "" >> ${TEMP_SSL}
                done

                continue
            fi

            if [ "${ARR[0]}" == "TCP" ]; then
                PORT="${ARR[1]}"

                echo "    upstream toast_${PORT} {" >> ${TEMP_TCP}

                for VAL in "${HOST_ARR[@]}"; do
                   echo "        server ${VAL}:${PORT} max_fails=3 fail_timeout=10s;" >> ${TEMP_TCP}
                done

                echo "    }" >> ${TEMP_TCP}

                TEMPLATE="${SHELL_DIR}/package/nginx/nginx-tcp-server.conf"
                sed "s/PORT/$PORT/g" ${TEMPLATE} >> ${TEMP_TCP}

                echo "" >> ${TEMP_TCP}

                continue
            fi
        done < ${LB_CONF}

        echo_ "assemble..."

        # default
        TEMPLATE="${SHELL_DIR}/package/nginx/nginx-default.conf"
        cat ${TEMPLATE} >> ${TEMP_FILE}

        # http
        if [ -f ${TEMP_HTTP} ]; then
            echo "" >> ${TEMP_FILE}
            echo "http {" >> ${TEMP_FILE}

            TEMPLATE="${SHELL_DIR}/package/nginx/nginx-http-default.conf"
            cat ${TEMPLATE} >> ${TEMP_FILE}
            echo "" >> ${TEMP_FILE}

            # http
            cat ${TEMP_HTTP} >> ${TEMP_FILE}

            # https
            if [ -f ${TEMP_SSL} ]; then
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

nginx_local() {
    nginx_dir

    if [ "${NGINX_CONF_DIR}" == "" ]; then
        return
    fi

    # health.html
    if [ -d "${SITE_DIR}/localhost" ]; then
        TEMP_FILE="${TEMP_DIR}/toast-health.tmp"
        echo "OK ${NAME}" > ${TEMP_FILE}
        copy ${TEMP_FILE} "/usr/local/nginx/html/index.html"
        copy ${TEMP_FILE} "/usr/local/nginx/html/health.html"
    fi
}

vhost_local() {
    httpd_dir

    if [ "${HTTPD_CONF_DIR}" == "" ]; then
        return
    fi

    # localhost
    TEMPLATE="${SHELL_DIR}/package/apache/${HTTPD_VERSION}/localhost.conf"
    if [ -f "${TEMPLATE}" ]; then
        copy ${TEMPLATE} "${HTTPD_CONF_DIR}/localhost.conf" 644
    fi

    # health.html
    if [ -d "${SITE_DIR}/localhost" ]; then
        TEMP_FILE="${TEMP_DIR}/toast-health.tmp"
        echo "OK ${NAME}" > ${TEMP_FILE}
        copy ${TEMP_FILE} "${SITE_DIR}/localhost/index.html"
        copy ${TEMP_FILE} "${SITE_DIR}/localhost/health.html"
    fi
}

vhost_replace() {
    DOM="$1"

    echo_ "--> ${DOM}"

    TEMPLATE="${SHELL_DIR}/package/apache/${HTTPD_VERSION}/vhost.conf"
    TEMP_FILE1="${TARGET_DIR}/toast-vhost1.tmp"
    TEMP_FILE2="${TARGET_DIR}/toast-vhost2.tmp"

    DIR="${DOM}"

    # gen vhost
    DEST_FILE="${HTTPD_CONF_DIR}/toast-${DOM}.conf"
    sed "s/DIR/$DIR/g" ${TEMPLATE}   > ${TEMP_FILE1}
    sed "s/DOM/$DOM/g" ${TEMP_FILE1} > ${TEMP_FILE2}
    copy ${TEMP_FILE2} ${DEST_FILE}

    # domain-in.com
    IN="${DOM}"
    IN=$(echo "${IN}" | sed "s/yanolja\.com/yanolja-in\.com/")
    IN=$(echo "${IN}" | sed "s/yanoljanow\.com/yanoljanow-in\.com/")

    if [ "${DOM}" == "${IN}" ]; then
        return
    fi

    DOM="${IN}"

    # gen vhost
    DEST_FILE="${HTTPD_CONF_DIR}/toast-${DOM}.conf"
    sed "s/DIR/$DIR/g" ${TEMPLATE}   > ${TEMP_FILE1}
    sed "s/DOM/$DOM/g" ${TEMP_FILE1} > ${TEMP_FILE2}
    copy ${TEMP_FILE2} ${DEST_FILE}
}

vhost_proxy() {
    DOM="$1"
    PORT="$2"

    echo_ "--> ${DOM}:${PORT}"

    TEMPLATE="${SHELL_DIR}/package/apache/${HTTPD_VERSION}/vhost-proxy.conf"
    TEMP_FILE1="${TARGET_DIR}/toast-vhost1.tmp"
    TEMP_FILE2="${TARGET_DIR}/toast-vhost2.tmp"
    TEMP_FILE3="${TARGET_DIR}/toast-vhost3.tmp"

    DIR="${DOM}"

    # gen vhost
    DEST_FILE="${HTTPD_CONF_DIR}/toast-${DOM}.conf"
    sed "s/PORT/$PORT/g" ${TEMPLATE} > ${TEMP_FILE1}
    sed "s/DIR/$DIR/g" ${TEMP_FILE1} > ${TEMP_FILE2}
    sed "s/DOM/$DOM/g" ${TEMP_FILE2} > ${TEMP_FILE3}
    copy ${TEMP_FILE3} ${DEST_FILE}

    # domain-in.com
    IN="${DOM}"
    IN=$(echo "${IN}" | sed "s/yanolja\.com/yanolja-in\.com/")
    IN=$(echo "${IN}" | sed "s/yanoljanow\.com/yanoljanow-in\.com/")

    if [ "${DOM}" == "${IN}" ]; then
        return
    fi

    DOM="${IN}"

    # gen vhost
    DEST_FILE="${HTTPD_CONF_DIR}/toast-${DOM}.conf"
    sed "s/PORT/$PORT/g" ${TEMPLATE} > ${TEMP_FILE1}
    sed "s/DIR/$DIR/g" ${TEMP_FILE1} > ${TEMP_FILE2}
    sed "s/DOM/$DOM/g" ${TEMP_FILE2} > ${TEMP_FILE3}
    copy ${TEMP_FILE3} ${DEST_FILE}
}

vhost_le_ssl() {
    DOM="$1"
    PORT="$2"

    echo_ "--> ${DOM}:443"

    TEMPLATE="${SHELL_DIR}/package/apache/${HTTPD_VERSION}/vhost-le-ssl.conf"
    TEMP_FILE1="${TARGET_DIR}/toast-vhost1.tmp"
    TEMP_FILE2="${TARGET_DIR}/toast-vhost2.tmp"

    DIR="${DOM}"

    # gen vhost
    DEST_FILE="${HTTPD_CONF_DIR}/toast-${DOM}-le-ssl.conf"
    sed "s/DIR/$DIR/g" ${TEMPLATE} > ${TEMP_FILE1}
    sed "s/DOM/$DOM/g" ${TEMP_FILE1} > ${TEMP_FILE2}
    copy ${TEMP_FILE2} ${DEST_FILE}
}

vhost_dom() {
    httpd_dir

    if [ "${HTTPD_CONF_DIR}" == "" ]; then
        return
    fi

    DOMAIN="${PARAM2}"

    if [ "${DOMAIN}" == "" ]; then
        warning "--> empty.domain.com"
        return
    fi

    echo_bar
    echo_ "apache domain... [${DOMAIN}]"

    echo_ "--> ${HTTPD_CONF_DIR}"

    vhost_local

    TARGET_DIR="${TEMP_DIR}/conf"
    mkdir -p ${TARGET_DIR}

    echo_ "placement apache..."

    make_dir "${SITE_DIR}/${DOMAIN}"

    vhost_replace "${DOMAIN}"

    httpd_graceful

    echo_bar
}

vhost_fleet() {
    if [ "${HEALTH}" != "200" ]; then
        return
    fi

    httpd_dir

    if [ "${HTTPD_CONF_DIR}" == "" ]; then
        return
    fi

    echo_bar
    echo_ "apache fleet... [${SNO}]"

    echo_ "--> ${HTTPD_CONF_DIR}"

    vhost_local

    ${SUDO} rm -rf ${HTTPD_CONF_DIR}/toast*

    TARGET_DIR="${TEMP_DIR}/conf"
    mkdir -p ${TARGET_DIR}

    HOST_LIST="${TARGET_DIR}/${SNO}"
    rm -rf ${HOST_LIST}

    URL="${TOAST_URL}/server/vhost/${SNO}"
    wget -q -N --post-data "org=${ORG}&token=${TOKEN}&no=${SNO}" -P "${TARGET_DIR}" "${URL}"

    if [ -f ${HOST_LIST} ]; then
        echo_ "placement apache..."

        while read LINE; do
            ARR=(${LINE})

            if [ "${ARR[0]}" == "" ]; then
                warning "--> empty.domain.com"
                continue
            fi

            make_dir "${SITE_DIR}/${ARR[0]}"

            if [ "${ARR[1]}" == "" ] || [ "${ARR[1]}" == "80" ]; then
                vhost_replace "${ARR[0]}"

                if [ "${ARR[2]}" == "Y" ]; then
                    vhost_le_ssl "${ARR[0]}"
                fi
            else
                vhost_proxy "${ARR[0]}" "${ARR[1]}"
            fi
        done < ${HOST_LIST}
    fi

    httpd_graceful

    echo_bar
}

repo_path() {
    if [ "${REPO_PATH}" != "" ]; then
        return
    fi

    REPO_BUCKET="repo.${ORG}.com"
    REPO_PATH="s3://${REPO_BUCKET}"
}

deploy_toast() {
    echo_ "deploy toast..."

    GROUP_ID="com.nalbam"
    ARTIFACT_ID="toast-web"
    VERSION="0.0.0"
    TYPE="web"
    DOMAIN="${PARAM2}.toast.sh"
    REPO="repo.toast.sh"

    GROUP_PATH="com/nalbam"

    PACKAGING="war"
    DEPLOY_PATH="${SITE_DIR}/${DOMAIN}"

    FILENAME="${ARTIFACT_ID}-${VERSION}.${PACKAGING}"
    FILEPATH="${TEMP_DIR}/${FILENAME}"

    UNZIP_DIR="${TEMP_DIR}/${ARTIFACT_ID}"

    echo_bar
    echo_ "download..."

    SOURCE="http://${REPO}/maven2/${GROUP_PATH}/${ARTIFACT_ID}/${VERSION}/${FILENAME}"
    echo_ "--> ${SOURCE}"

    wget -q -N -P "${TEMP_DIR}" "${SOURCE}"

    if [ -d "${UNZIP_DIR}" ] || [ -f "${UNZIP_DIR}" ]; then
        rm -rf "${UNZIP_DIR}"
    fi

    if [ -d "${UNZIP_DIR}" ] || [ -f "${UNZIP_DIR}" ]; then
        warning "deploy file can not unzip. [${UNZIP_DIR}]"
    else
        unzip -q "${FILEPATH}" -d "${UNZIP_DIR}"

        if [ ! -d "${UNZIP_DIR}" ]; then
            warning "deploy file can not unzip. [${UNZIP_DIR}]"
        fi

        if [ -d "${UNZIP_DIR}/application/logs" ]; then
            chmod 777 "${UNZIP_DIR}/application/logs"
        fi
        if [ -d "${UNZIP_DIR}/application/cache" ]; then
            chmod 777 "${UNZIP_DIR}/application/cache"
        fi
    fi

    echo_ "placement..."

    placement

    echo_bar
}

deploy_project() {
    echo_ "deploy project..."

    GROUP_ID="${PARAM2}"
    ARTIFACT_ID="${PARAM3}"
    VERSION="${PARAM4}"
    TYPE="${PARAM5}"
    DOMAIN="${PARAM6}"
    REPO="${PARAM7}"

    GROUP_PATH=$(echo "${GROUP_ID}" | sed "s/\./\//")

    PACKAGING="${TYPE}"
    if [ "${PACKAGING}" == "war" ]; then
        DEPLOY_PATH="${WEBAPP_DIR}"
    elif [ "${PACKAGING}" == "jar" ]; then
        DEPLOY_PATH="${APPS_DIR}"
    elif [ "${PACKAGING}" == "web" ] || [ "${PACKAGING}" == "php" ]; then
        PACKAGING="war"
        DEPLOY_PATH="${SITE_DIR}/${DOMAIN}"
    fi

    FILENAME="${ARTIFACT_ID}-${VERSION}.${PACKAGING}"
    FILEPATH="${TEMP_DIR}/${FILENAME}"

    UNZIP_DIR="${TEMP_DIR}/${ARTIFACT_ID}"

    if [ "${REPO}" != "" ]; then
        REPO_BUCKET="${REPO}"
        REPO_PATH="s3://${REPO_BUCKET}"
    fi

    echo_bar
    echo_ "download..."

    download

    tomcat_stop

    echo_ "placement..."

    placement

    tomcat_start

    echo_bar
}

deploy_fleet() {
    if [ "${HEALTH}" != "200" ]; then
        return
    fi

    echo_bar
    echo_ "deploy fleet... [${SNO}]"

    TARGET_DIR="${TEMP_DIR}/deploy"
    mkdir -p ${TARGET_DIR}

    TARGET_FILE="${TARGET_DIR}/${SNO}"
    rm -rf ${TARGET_FILE}

    URL="${TOAST_URL}/server/deploy/${SNO}"
    wget -q -N --post-data "org=${ORG}&token=${TOKEN}&no=${SNO}" -P "${TARGET_DIR}" "${URL}"

    if [ -f ${TARGET_FILE} ]; then
        echo_ "download..."

        while read LINE; do
            ARR=(${LINE})

            deploy_value

            download
        done < ${TARGET_FILE}

        tomcat_stop
        process_stop_all

        echo_ "placement..."

        while read LINE; do
            ARR=(${LINE})

            deploy_value

            placement
        done < ${TARGET_FILE}

        tomcat_start
    fi

    echo_bar
}

deploy_target() {
    if [ "${HEALTH}" != "200" ]; then
        return
    fi

    echo_bar
    echo_ "deploy target... [${SNO}][${PARAM2}]"

    if [ "${PARAM2}" == "" ]; then
        return
    fi

    TARGET_DIR="${TEMP_DIR}/deploy"
    mkdir -p ${TARGET_DIR}

    TARGET_FILE="${TARGET_DIR}/${PARAM2}"
    rm -rf ${TARGET_FILE}

    URL="${TOAST_URL}/server/deploy/${SNO}/${PARAM2}"
    wget -q -N --post-data "org=${ORG}&token=${TOKEN}&no=${SNO}&t_no=${PARAM2}" -P "${TARGET_DIR}" "${URL}"

    if [ -f ${TARGET_FILE} ]; then
        echo_ "download..."

        while read LINE; do
            ARR=(${LINE})

            deploy_value

            download
        done < ${TARGET_FILE}

        tomcat_stop

        echo_ "placement..."

        while read LINE; do
            ARR=(${LINE})

            deploy_value

            placement
        done < ${TARGET_FILE}

        tomcat_start
    fi

    echo_bar
}

deploy_bucket() {
    if [ "${HEALTH}" != "200" ]; then
        return
    fi

    echo_bar
    echo_ "deploy bucket... [${PARAM1}]"

    if [ "${PARAM1}" == "" ]; then
        return
    fi

    TARGET_DIR="${TEMP_DIR}/deploy"
    mkdir -p ${TARGET_DIR}

    TARGET_FILE="${TARGET_DIR}/${PARAM1}"
    rm -rf ${TARGET_FILE}

    URL="${TOAST_URL}/target/deploy/${PARAM1}"
    wget -q -N --post-data "org=${ORG}&token=${TOKEN}&no=${SNO}" -P "${TARGET_DIR}" "${URL}"

    if [ -f ${TARGET_FILE} ]; then
        echo_ "download..."

        while read LINE; do
            ARR=(${LINE})

            deploy_value

            download
        done < ${TARGET_FILE}

        tomcat_stop

        echo_ "placement..."

        while read LINE; do
            ARR=(${LINE})

            deploy_value

            placement
        done < ${TARGET_FILE}

        tomcat_start
    fi

    echo_bar
}

deploy_value() {
    TNO="${ARR[0]}"
    GROUP_ID="${ARR[1]}"
    ARTIFACT_ID="${ARR[2]}"
    VERSION="${ARR[3]}"
    TYPE="${ARR[4]}"
    DOMAIN="${ARR[5]}"
    DEPLOY_TYPE="${ARR[6]}"
    DEPLOY_PORT="${ARR[7]}"

    GROUP_PATH=$(echo "${GROUP_ID}" | sed "s/\./\//")

    PACKAGING="${TYPE}"

    if [ "${DEPLOY_TYPE}" == "s3" ]; then
        if [ "${DOMAIN}" == "" ]; then
            DEPLOY_PATH=""
        else
            DEPLOY_PATH="s3://${DOMAIN}"
        fi
        PACKAGING="war"
    else
        if [ "${PACKAGING}" == "war" ]; then
            DEPLOY_PATH="${WEBAPP_DIR}"
        elif [ "${PACKAGING}" == "jar" ]; then
            DEPLOY_PATH="${APPS_DIR}"
        elif [ "${PACKAGING}" == "web" ] || [ "${PACKAGING}" == "php" ]; then
            if [ "${DOMAIN}" == "" ]; then
                DEPLOY_PATH=""
            else
                DEPLOY_PATH="${SITE_DIR}/${DOMAIN}"
            fi
            PACKAGING="war"
        fi
    fi

    FILENAME="${ARTIFACT_ID}-${VERSION}.${PACKAGING}"
    FILEPATH="${TEMP_DIR}/${FILENAME}"

    UNZIP_DIR="${TEMP_DIR}/${TNO}"
}

download() {
    SOURCE="${REPO_PATH}/maven2/${GROUP_PATH}/${ARTIFACT_ID}/${VERSION}/${FILENAME}"
    echo_ "--> ${SOURCE}"
    aws s3 cp "${SOURCE}" "${TEMP_DIR}" --quiet

    if [ ! -f "${FILEPATH}" ]; then
        if [ "${ARTIFACT_ID}" == "toast-web" ]; then
            SOURCE="http://repo.toast.sh/maven2/${GROUP_PATH}/${ARTIFACT_ID}/${VERSION}/${FILENAME}"
            echo_ "--> ${SOURCE}"
            wget -q -N -P "${TEMP_DIR}" "${SOURCE}"
        fi
        if [ ! -f "${FILEPATH}" ]; then
            warning "deploy file does not exist. [${FILEPATH}]"
            return
        fi
    fi

    if [ "${TYPE}" == "jar" ]; then
        HAS_JAR="TRUE"
    elif [ "${TYPE}" == "war" ]; then
        HAS_WAR="TRUE"
    elif [ "${TYPE}" == "web" ] || [ "${TYPE}" == "php" ]; then
        if [ -d "${UNZIP_DIR}" ] || [ -f "${UNZIP_DIR}" ]; then
            rm -rf "${UNZIP_DIR}"
        fi

        if [ -d "${UNZIP_DIR}" ] || [ -f "${UNZIP_DIR}" ]; then
            warning "deploy file can not unzip. [${UNZIP_DIR}]"
        else
            unzip -q "${FILEPATH}" -d "${UNZIP_DIR}"

            if [ ! -d "${UNZIP_DIR}" ]; then
                warning "deploy file can not unzip. [${UNZIP_DIR}]"
            fi

            if [ -d "${UNZIP_DIR}/application/logs" ]; then
                chmod 777 "${UNZIP_DIR}/application/logs"
            fi
            if [ -d "${UNZIP_DIR}/application/cache" ]; then
                chmod 777 "${UNZIP_DIR}/application/cache"
            fi
        fi
    fi
}

placement() {
    if [ ! -f "${FILEPATH}" ]; then
        warning "deploy file does not exist. [${FILEPATH}]"
        return
    fi

    if [ "${DEPLOY_PATH}" == "" ]; then
        warning "--> empty DEPLOY_PATH [${DEPLOY_PATH}]"
        return
    fi

    echo_ "--> ${DEPLOY_PATH}"

    if [ "${DEPLOY_TYPE}" == "s3" ]; then
        if [ ! -d "${UNZIP_DIR}" ]; then
            warning "--> empty UNZIP_DIR [${UNZIP_DIR}]"
            return
        fi

        OPTION="--quiet --acl public-read"

        aws s3 sync "${UNZIP_DIR}" "${DEPLOY_PATH}" ${OPTION}
    else
        if [ "${TYPE}" == "web" ] || [ "${TYPE}" == "php" ]; then
            rm -rf "${DEPLOY_PATH}.backup"

            if [ -d "${DEPLOY_PATH}" ] || [ -f "${DEPLOY_PATH}" ]; then
                mv -f "${DEPLOY_PATH}" "${DEPLOY_PATH}.backup"
            fi

            if [ -d "${DEPLOY_PATH}" ] || [ -f "${DEPLOY_PATH}" ]; then
                warning "deploy dir can not copy. [${DEPLOY_PATH}]"
            else
                mv -f "${UNZIP_DIR}" "${DEPLOY_PATH}"
            fi
        elif [ "${TYPE}" == "war" ]; then
            DEST_WAR="${DEPLOY_PATH}/${ARTIFACT_ID}.${PACKAGING}"

            rm -rf "${DEPLOY_PATH}/${ARTIFACT_ID}"
            rm -rf "${DEST_WAR}"

            if [ -d "${DEST_WAR}" ] || [ -f "${DEST_WAR}" ]; then
                warning "deploy file can not copy. [${DEST_WAR}]"
            else
                cp -rf "${FILEPATH}" "${DEST_WAR}"
            fi
        elif [ "${TYPE}" == "jar" ]; then
            DEST_WAR="${DEPLOY_PATH}/${ARTIFACT_ID}.${PACKAGING}"

            rm -rf "${DEST_WAR}"

            if [ -d "${DEST_WAR}" ] || [ -f "${DEST_WAR}" ]; then
                warning "deploy file can not copy. [${DEST_WAR}]"
            else
                process_stop
                cp -rf "${FILEPATH}" "${DEST_WAR}"
                process_start
            fi
        fi
    fi

    # version status
    URL="${TOAST_URL}/version/deploy/${ARTIFACT_ID}/${VERSION}"
    RES=$(curl -s --data "org=${ORG}&token=${TOKEN}&phase=${PHASE}&fleet=${FLEET}&name=${NAME}&groupId=${GROUP_ID}&no=${SNO}&t_no=${TNO}" "${URL}")
    ARR=(${RES})

    if [ "${ARR[0]}" != "OK" ]; then
        warning "Server Error. [${URL}][${RES}]"
    fi
}

certbot_apache() {
    if [ ! -f "${SHELL_DIR}/.config_certbot" ]; then
        warning "Not set certbot."
        return
    fi

    if [ "$1" == "" ]; then
        CERT_NAME="${PARAM2}"
    else
        CERT_NAME="$1"
    fi

    if [ "${CERT_NAME}" == "" ]; then
        warning "Not set CERT_NAME."
        return
    fi

    echo_ "init certbot (apache)... [${CERT_NAME}]"

    init_email

    if [ OS_TYPE == "amzn1" ]; then
        PARAM="--agree-tos --no-redirect --debug"
    else
        PARAM="--agree-tos --no-redirect"
    fi

    ${SUDO} ${HOME}/certbot/certbot-auto --apache --email ${EMAIL} ${PARAM} -d ${CERT_NAME}
}

certbot_nginx() {
    if [ ! -f "${SHELL_DIR}/.config_certbot" ]; then
        warning "Not set certbot."
        return
    fi

    if [ "$1" == "" ]; then
        CERT_NAME="${PARAM2}"
    else
        CERT_NAME="$1"
    fi

    if [ "${CERT_NAME}" == "" ]; then
        warning "Not set CERT_NAME."
        return
    fi

    echo_ "init certbot (nginx)... [${CERT_NAME}]"

    init_email

    if [ OS_TYPE == "amzn1" ]; then
        PARAM="--agree-tos --no-redirect --debug"
    else
        PARAM="--agree-tos --no-redirect"
    fi

    ${SUDO} ${HOME}/certbot/certbot-auto --nginx --email ${EMAIL} ${PARAM} -d ${CERT_NAME}
}

certbot_delete() {
    if [ ! -f "${SHELL_DIR}/.config_certbot" ]; then
        warning "Not set certbot."
        return
    fi

    if [ OS_TYPE == "amzn1" ]; then
        PARAM="--debug"
    else
        PARAM=""
    fi

    ${SUDO} ${HOME}/certbot/certbot-auto delete ${PARAM}
}

certbot_renew() {
    if [ ! -f "${SHELL_DIR}/.config_certbot" ]; then
        #warning "Not set certbot."
        return
    fi

    if [ OS_TYPE == "amzn1" ]; then
        PARAM="--debug"
    else
        PARAM=""
    fi

    ${SUDO} ${HOME}/certbot/certbot-auto renew ${PARAM}
}

connect() {
    if [ "${HEALTH}" != "200" ]; then
        return
    fi

    PHASE="${PARAM1}"
    FLEET="${PARAM2}"

    # phase
    if [ "${PHASE}" == "" ]; then
        URL="${TOAST_URL}/phase/conn"
        wget -q -N --post-data "org=${ORG}&token=${TOKEN}&no=${SNO}" -P "${TEMP_DIR}" "${URL}"

        CONN_LIST="${TEMP_DIR}/conn"

        if [ ! -f ${CONN_LIST} ]; then
            warning "Not exist file. [${CONN_LIST}]"
            exit 1
        fi

        echo_bar
        echo_ "# phase list"
        cat ${CONN_LIST}
        echo_bar

        if [ $(cat ${CONN_LIST} | wc -l) -lt 2 ]; then
            while read LINE; do
                ARR=(${LINE})

                if [ "${ARR[0]}" != "" ]; then
                    PHASE="${ARR[1]}"
                fi
            done < ${CONN_LIST}
        else
            echo "Please input phase no."
            read READ_NO

            while read LINE; do
                ARR=(${LINE})

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
        wget -q -N --post-data "org=${ORG}&token=${TOKEN}&no=${SNO}" -P "${TEMP_DIR}" "${URL}"

        CONN_LIST="${TEMP_DIR}/${PHASE}"

        if [ ! -f ${CONN_LIST} ]; then
            warning "Not exist file. [${CONN_LIST}]"
            exit 1
        fi

        echo_bar
        echo_ "# fleet list"
        cat ${CONN_LIST}
        echo_bar

        if [ $(cat ${CONN_LIST} | wc -l) -lt 2 ]; then
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
    wget -q -N --post-data "org=${ORG}&token=${TOKEN}&no=${SNO}" -P "${TEMP_DIR}" "${URL}"

    CONN_LIST="${TEMP_DIR}/${FLEET}"
    CONN_PARAM=""

    if [ ! -f ${CONN_LIST} ]; then
        warning "Not exist file. [${CONN_LIST}]"
        exit 1
    fi

    echo_bar
    echo_ "# server list"
    cat ${CONN_LIST}
    echo_bar

    if [ $(cat ${CONN_LIST} | wc -l) -lt 2 ]; then
        while read LINE; do
            ARR=(${LINE})

            if [ "${ARR[0]}" != "" ]; then
                CONN_PARAM="${ARR[3]}@${ARR[1]} -p ${ARR[2]}"
            fi
        done < ${CONN_LIST}
    else
        echo "Please input server no."
        read READ_NO

        while read LINE; do
            ARR=(${LINE})

            if [ "${ARR[0]}" == "${READ_NO}" ]; then
                CONN_PARAM="${ARR[3]}@${ARR[1]} -p ${ARR[2]}"
            fi
        done < ${CONN_LIST}
    fi

    if [ "${CONN_PARAM}" == "" ]; then
        return 1
    fi

    echo_ "connect... ${CONN_PARAM}"
    echo_bar

    # ssh
    ssh ${CONN_PARAM}
}

health() {
    if [ "${HEALTH}" != "200" ]; then
        exit 0
    fi

    if [ "${SNO}" == "" ]; then
        warning "Not set SNO."
        exit 0
    fi

    if [ -f /tmp/toaster.old ]; then
        TOAST="$(cat /tmp/toaster.old)"
    else
        TOAST=""
    fi

    CPU="$(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print usage}')"

    DISK_TOT="$(df -P | grep -v ^Filesystem | grep -v ^tmpfs | awk '{sum += $2} END { print sum; }')"
    DISK_USE="$(df -P | grep -v ^Filesystem | grep -v ^tmpfs | awk '{sum += $3} END { print sum; }')"
    DISK_PER="$(echo "100 * $DISK_USE / $DISK_TOT" | bc -l)"

    UPTIME="$(uptime)"

    URL="${TOAST_URL}/server/health/${SNO}"
    RES=$(curl -s --data "org=${ORG}&token=${TOKEN}&id=${UUID}&cpu=${CPU}&hdd=${DISK_PER}&os=${OS_FULL}&uptime=${UPTIME}&toast=${TOAST}" "${URL}")
    ARR=(${RES})

    if [ "${ARR[0]}" == "OK" ]; then
        if [ "${ARR[2]}" != "" ]; then
            if [ "${ARR[2]}" != "${NAME}" ]; then
                config_name "${ARR[2]}"
                config_local
            fi
        fi
    fi

    exit 0
}

reset() {
    if [ "${HEALTH}" != "200" ]; then
        return
    fi

    if [ "${SNO}" == "" ]; then
        warning "Not set SNO."
        return
    fi

    URL="${TOAST_URL}/server/info/${SNO}"
    RES=$(curl -s --data "org=${ORG}&token=${TOKEN}&id=${UUID}" "${URL}")
    ARR=(${RES})

    if [ "${ARR[0]}" == "OK" ]; then
        if [ "${ARR[2]}" != "" ]; then
            if [ "${ARR[2]}" != "${NAME}" ]; then
                config_name "${ARR[2]}"
                config_local
            fi
        fi
    fi
}

toast_url() {
    if [ "${HEALTH}" != "" ]; then
        return
    fi

    if [ "${TOAST_URL}" == "" ]; then
        HEALTH="500"
        warning "Not set TOAST_URL."
        return
    fi

    URL="${TOAST_URL}/health"
    RES=$(curl -Is "${URL}" | grep HTTP)
    ARR=(${RES})

    if [ "${ARR[1]}" == "404" ]; then
        HEALTH="404"
        warning "Not available TOAST_WEB."
        return
    fi

    HEALTH="200"
}

log_tomcat() {
    tail -f -n 500 ${TOMCAT_DIR}/logs/catalina.out
}

log_webapp() {
    tail -f -n 500 ${LOGS_DIR}/*
}

log_reduce() {
    find ${LOGS_DIR}/** -type f -mtime +10 | xargs gzip
    find ${LOGS_DIR}/** -type f -mtime +15 | xargs rm -rf
}

service_update() {
    if [ "${OS_TYPE}" == "Ubuntu" ]; then
        ${SUDO} apt-get update
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

        if [ "${OS_TYPE}" != "Ubuntu" ]; then
            if [ "$3" == "on" ]; then
                ${SUDO} chkconfig $1 on
            fi
            if [ "$3" == "off" ]; then
                ${SUDO} chkconfig $1 off
            fi
        fi
    fi
}

language() {
    if [ -r /etc/sysconfig/i18n ]; then
        ${SUDO} cp -rf "${SHELL_DIR}/package/linux/i18n.conf" "/etc/sysconfig/i18n"
    fi
}

localtime() {
    date

    if [ -r /etc/localtime ]; then
        ${SUDO} rm -rf "/etc/localtime"
        ${SUDO} ln -sf "/usr/share/zoneinfo/Asia/Seoul" "/etc/localtime"
    fi

    date
}

httpd_graceful() {
    echo_ "httpd graceful..."

    if [ -f "${SHELL_DIR}/.config_httpd" ]; then
        if [ "${OS_TYPE}" == "el7" ]; then
            service_ctl httpd restart
        else
            service_ctl httpd graceful
        fi
    else
        if [ -x ${HTTPD_BIN_PATH} ]; then
            ${SUDO} ${HTTPD_BIN_PATH} -k graceful
        fi
    fi
}

httpd_restart() {
    echo_ "httpd restart..."

    if [ -f "${SHELL_DIR}/.config_httpd" ]; then
        service_ctl httpd restart
    else
        if [ -x ${HTTPD_BIN_PATH} ]; then
            ${SUDO} ${HTTPD_BIN_PATH} -k restart
        fi
    fi
}

tomcat_stop() {
    if [ "${HAS_WAR}" == "TRUE" ]; then
        status=$(ps -ef | grep catalina | grep java | grep -v grep | wc -l | awk '{print $1}')
        if [ ${status} -ge 1 ]; then
            echo_ "tomcat stop..."
            ${TOMCAT_DIR}/bin/shutdown.sh
            sleep 3
        fi
    fi
}

tomcat_start() {
    if [ "${HAS_WAR}" == "TRUE" ]; then
        status=$(ps -ef | grep catalina | grep java | grep -v grep | wc -l | awk '{print $1}')
        count=0
        while [ ${status} -ge 1 ]; do
            echo_ "wait tomcat..."
            sleep 3

            if [ ${count} -ge 5 ]; then
                pid=$(ps -ef | grep catalina | grep java | grep -v grep | awk '{print $2}')
                kill -9 ${pid}
                echo_ "tomcat (${pid}) was killed."
            fi

            sleep 2
            status=$(ps -ef | grep catalina | grep java | grep -v grep | wc -l | awk '{print $1}')
            count=$(expr ${count} + 1)
        done

        echo_ "tomcat start..."
        ${TOMCAT_DIR}/bin/startup.sh
    fi
}

process_stop_all() {
    if [ "${HAS_JAR}" == "TRUE" ]; then
        PID=$(ps -ef | grep "[j]ava" | grep "[-]jar" | awk '{print $2}')
        if [ "${PID}" != "" ]; then
            kill -9 ${PID}
            echo_ "killed (${PID})"
        fi
    fi
}

process_stop() {
    PID=$(ps -ef | grep "[${ARTIFACT_ID:0:1}]""${ARTIFACT_ID:1}" | grep "[-]jar" | awk '{print $2}')
    if [ "${PID}" != "" ]; then
        kill -9 ${PID}
        echo_ "killed (${PID})"
    fi
}

process_start() {
    if [ "${DEPLOY_PORT}" != "" ]; then
        java -jar ${JAR_OPTS} -Dserver.port=${DEPLOY_PORT} ${DEPLOY_PATH}/${ARTIFACT_ID}.${PACKAGING} >> /dev/null &
    else
        java -jar ${JAR_OPTS} ${DEPLOY_PATH}/${ARTIFACT_ID}.${PACKAGING} >> /dev/null &
    fi

    PID=$(ps -ef | grep "[${ARTIFACT_ID:0:1}]""${ARTIFACT_ID:1}" | grep "[-]jar" | awk '{print $2}')
    if [ "${PID}" != "" ]; then
        echo_ "startup (${PID})"
    fi
}

add_source() {
    if [ "$1" == "" ]; then
        return
    fi

    touch $1

    BASHRC="${HOME}/.bashrc"
    touch ${BASHRC}

    VAL="source $1"

    HAS_KEY="false"

    while read LINE
    do
        if [ "${LINE}" == "${VAL}" ]; then
            HAS_KEY="true"
        fi
    done < ${BASHRC}

    if [ "${HAS_KEY}" == "false" ]; then
        echo "${VAL}" >> ${BASHRC}
    fi
}

add_path() {
    if [ "$1" == "" ]; then
        return
    fi

    TARGET="${HOME}/.toast_base"

    add_source ${TARGET}

    echo "export PATH=\"\$PATH:$1\"" >> ${TARGET}

    source ${TARGET}
}

mod_env() {
    if [ "$1" == "" ]; then
        return
    fi

    TARGET="${HOME}/.toast_base"

    add_source ${TARGET}

    mod_conf ${TARGET} "export $1" "$2"

    source ${TARGET}
}

mod_conf() {
    TARGET=$1

    if [ ! -f ${TARGET} ]; then
        return
    fi

    if [ "$2" == "" ]; then
        return
    fi

    KEY=$2
    VAL=$3

    HAS_KEY="false"

    while read LINE; do
        KEY1=$(echo ${LINE} | cut -d "=" -f 1)

        if [ "${KEY1}" == "${KEY}" ]; then
            HAS_KEY="true"
        fi
    done < ${TARGET}

    if [ "${HAS_KEY}" == "true" ]; then
        TEMP_FILE="${TEMP_DIR}/toast-replace.tmp"

        sed "s/${KEY}\=/\#${KEY}\=/g" ${TARGET} > ${TEMP_FILE}
        copy ${TEMP_FILE} ${TARGET} 600
    fi

    echo "${KEY}=\"${VAL}\"" >> ${TARGET}
}

mod() {
    if [ "$1" == "" ]; then
        return
    fi
    if [ ! -d $1 ] && [ ! -f $1 ]; then
        return
    fi

    if [ "${USER}" != "" ]; then
        ${SUDO} chown ${USER}.${USER} $1
    fi

    if [ "$2" != "" ]; then
        ${SUDO} chmod $2 $1
    fi
}

copy() {
    if [ "$1" == "" ]; then
        return
    fi
    if [ "$2" == "" ]; then
        return
    fi

    ${SUDO} cp -rf $1 $2

    mod $2 $3
}

new_file() {
    if [ "$1" == "" ]; then
        return
    fi

    ${SUDO} echo -n "" > $1

    mod $1 $2
}

make_dir() {
    if [ "$1" == "" ]; then
        return
    fi

    if [ ! -d $1 ] && [ ! -f $1 ]; then
        mkdir -p $1

        if [ "$2" != "" ]; then
            chmod $2 $1
        fi
    fi

    if [ ! -d $1 ] && [ ! -f $1 ]; then
        ${SUDO} mkdir -p $1

        mod $1 $2
    fi
}

not_darwin() {
    if [ "${OS_TYPE}" == "Darwin" ]; then
        warning "Not supported OS - ${OS_TYPE}"
        exit 1
    fi
}

echo_bar() {
    echo_ "================================================================================"
}

echo_toast() {
    if [ -r /tmp/toaster.old ]; then
        VER="$(cat /tmp/toaster.old)"
    fi

    echo_bar
    echo_ "                              _  _          _                  _        "
    echo_ "      _   _  __ _ _ __   ___ | |(_) __ _   | |_ ___   __ _ ___| |_      "
    echo_ "     | | | |/ _\` | '_ \ / _ \| || |/ _\` |  | __/ _ \ / _\` / __| __|  "
    echo_ "     | |_| | (_| | | | | (_) | || | (_| |  | || (_) | (_| \__ \ |_      "
    echo_ "      \__, |\__,_|_| |_|\___/|_|/ |\__,_|   \__\___/ \__,_|___/\__|     "
    echo_ "      |___/                   |__/                                      "
    echo_ "                                            by nalbam (${VER})       "
    echo_bar
}

usage() {
    echo_toast
    echo_ " Usage: toast {auto|update|config|init|build|deploy|bucket|health|ssh}"
    echo_bar
    echo_
    echo_ " Usage: toast auto"
    echo_
    echo_ " Usage: toast update"
    echo_
    echo_ " Usage: toast config"
    echo_
    echo_ " Usage: toast init {package}"
    echo_
    echo_ " Usage: toast build version {branch}"
    echo_ " Usage: toast build save {package}"
    echo_
    echo_ " Usage: toast vhost"
    echo_ " Usage: toast vhost lb"
    echo_
    echo_ " Usage: toast deploy"
    echo_ " Usage: toast deploy fleet"
    echo_ " Usage: toast deploy target {no}"
    echo_
    echo_ " Usage: toast bucket {no}"
    echo_
    echo_ " Usage: toast health"
    echo_
    echo_ " Usage: toast ssh"
    echo_
    echo_bar
}

################################################################################

toast

# done
success "done."
