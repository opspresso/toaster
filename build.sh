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

SUDO=""
if [ "${HOME}" != "/root" ]; then
    SUDO="sudo"
fi

USER="$(whoami)"

SHELL_DIR=$(dirname "$0")

################################################################################

CMD=$1

PARAM1=$2
PARAM2=$3
PARAM3=$4
PARAM4=$5
PARAM5=$6
PARAM6=$7

TEMP_DIR="/tmp"

TEMP_FILE="${TEMP_DIR}/toast.tmp"

REPO_PATH=""

################################################################################

toast() {
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
        r|reset)
            reset
            ;;
        l|log)
            log
            ;;
        *)
            usage
    esac
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
        certbot)
            init_certbot
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
            init_java8
            ;;
        maven|maven3)
            init_maven3
            ;;
        tomcat|tomcat8)
            init_tomcat8
            ;;
        mysql)
            init_mysql55
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
    esac
}

build() {
    repo_path

    build_parse

    case ${PARAM1} in
        version|next)
            build_version
            ;;
        save)
            build_save
            ;;
        package)
            build_package
            ;;
        docker)
            build_docker
            ;;
        eb)
            build_eb
            ;;
    esac
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

################################################################################

self_info() {
    echo_bar
    echo_ "OS    : ${OS_NAME} ${OS_TYPE}"
    echo_ "HOME  : ${HOME}"
    echo_bar
}

self_update() {
    curl -s toast.sh/install | bash
}

init_profile() {
    echo_ "init profile..."

    TARGET="${HOME}/.toast_profile"
    add_source "${TARGET}"
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

init_java8() {
    make_dir "${APPS_DIR}"

    if [ ! -f "${SHELL_DIR}/.config_java" ]; then
        echo_ "init java..."

        service_remove "java-1.7.0-openjdk java-1.7.0-openjdk-headless"
        service_remove "java-1.8.0-openjdk java-1.8.0-openjdk-headless java-1.8.0-openjdk-devel"

        ${SHELL_DIR}/install/java.sh "${REPO_PATH}"

        JAVA_HOME="/usr/local/java"

        if [ ! -d ${JAVA_HOME} ]; then
            warning "Can not found : JAVA_HOME=${JAVA_HOME}"
            exit 1
        fi

        add_path "${JAVA_HOME}/bin"
        mod_env "JAVA_HOME" "${JAVA_HOME}"

        echo "JAVA_HOME=${JAVA_HOME}"
        echo "JAVA_HOME=${JAVA_HOME}" > "${SHELL_DIR}/.config_java"
    fi

    echo_bar
    echo_ "$(java -version)"
    echo_bar
}

init_maven3() {
    make_dir "${APPS_DIR}"

    if [ ! -f "${SHELL_DIR}/.config_maven" ]; then
        echo_ "init maven..."

        ${SHELL_DIR}/install/maven.sh "${REPO_PATH}"

        MAVEN_HOME="${APPS_DIR}/maven3"

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

init_tomcat8() {
    make_dir "${APPS_DIR}"

    if [ ! -f "${SHELL_DIR}/.config_tomcat" ]; then
        echo_ "init tomcat..."

        ${SHELL_DIR}/install/tomcat.sh "${REPO_PATH}"

        CATALINA_HOME="${APPS_DIR}/tomcat8"

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

init_mysql55() {
    if [ ! -f "${SHELL_DIR}/.config_mysql" ]; then
        echo_ "init mysql55..."

        service_install mysql55-server

        service_ctl mysqld start on

        touch "${SHELL_DIR}/.config_mysql"
    fi
}

init_mysql56() {
    if [ ! -f "${SHELL_DIR}/.config_mysql" ]; then
        echo_ "init mysql56..."

        service_install mysql56-server

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

    if [ "${PHASE}" != "local" ]; then
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
    fi
}

build_package() {
    if [ "${ARTIFACT_ID}" == "" ]; then
        warning "Not set ARTIFACT_ID."
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

    if [ "${VERSION}" != "0.0.0" ]; then
        echo_ "version tag... [${VERSION}]"

        DATE=$(date "+%Y-%m-%d %H:%M")

        git config --global user.email "toast@yanolja.com"
        git config --global user.name "toast"

        git tag -a "${VERSION}" -m "at ${DATE} by toast"
        git push origin "${VERSION}"
    fi

    if [ "${PARAM3}" != "none" ]; then
        echo_ "package upload..."

        upload_repo "zip"
        upload_repo "war"
        upload_repo "jar"
        upload_repo "pom"

        echo_ "package uploaded."
    fi

    build_note

    GIT_ID="$(cat .git_id)"
    BRANCH="$(cat .git_branch)"

    if [ "${PHASE}" == "local" ]; then
        return
    fi

    GIT_URL="$(git config --get remote.origin.url)"

    NOTE="$(cat target/.git_note)"

    URL="${TOAST_URL}/version/build/${ARTIFACT_ID}/${VERSION}"
    RES=$(curl -s --data "org=${ORG}&token=${TOKEN}&groupId=${GROUP_ID}&artifactId=${ARTIFACT_ID}&packaging=${PACKAGE}&no=${SNO}&url=${GIT_URL}&git=${GIT_ID}&branch=${BRANCH}&note=${NOTE}" "${URL}")
    ARR=(${RES})

    if [ "${ARR[0]}" != "OK" ]; then
        warning "Server Error. [${URL}][${RES}]"
    fi
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

    # deploy
    if [ -d "deploy" ]; then
        cp -rf "deploy" "target/docker/deploy"
        FILES="${FILES} deploy"
    fi

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
        OPTION="--quiet --acl public-read" # --quiet
    else
        OPTION="--quiet" # --quiet
    fi

    aws s3 cp "${PACKAGE_PATH}" "${UPLOAD_PATH}" ${OPTION}
}

repo_path() {
    if [ "${TOAST_URL}" == "" ]; then
        warning "Not set TOAST_URL."
        exit 1
    fi
    if [ "${REPO_PATH}" != "" ]; then
        return
    fi

    if [ "${PHASE}" != "local" ]; then
        # repo_bucket
        URL="${TOAST_URL}/config/key/repo_bucket"
        RES=$(curl -s --data "org=${ORG}&token=${TOKEN}&no=${SNO}" "${URL}")

        if [ "${RES}" != "" ]; then
            REPO_BUCKET="${RES}"
            REPO_PATH="s3://${REPO_BUCKET}"
            return
        fi
    fi

    REPO_BUCKET="repo.${ORG}.com"
    REPO_PATH="s3://${REPO_BUCKET}"
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
    echo_ "                                               by nalbam (${VER})      "
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
