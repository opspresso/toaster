#!/bin/bash

echo_() {
    echo -e "$1"
    echo "$1" >> /tmp/toast.log
}

success() {
    echo_ "$1"
    exit 0
}

error() {
    echo_ "$1"
    exit 1
}

nothing() {
    USERID=

    # build
    BRANCH=
    BUILD=

    # docker
    REGISTRY=

    # aws
    AWS_DEFAULT_REGION=
    AWS_DEFAULT_BUCKET=

    # circle ci
    CIRCLE_BRANCH=
    CIRCLE_BUILD_NUM=

    # gitlab ci
    CI_COMMIT_REF_SLUG=
}

################################################################################

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
    error "Not supported OS. [${OS_FULL}]"
fi

################################################################################

CMD=$1

PARAM1=$2
PARAM2=$3
PARAM3=$4
PARAM4=$5
PARAM5=$6
PARAM6=$7

SHELL_DIR=$(dirname "$0")

TEMP_DIR="/tmp"

SUDO=""
if [ "${HOME}" != "/root" ]; then
    SUDO="sudo"
fi

################################################################################

BUCKET="repo.toast.sh"
if [ "${AWS_DEFAULT_BUCKET}" != "" ]; then
    BUCKET="${AWS_DEFAULT_BUCKET}"
fi

REGION="ap-northeast-2"
if [ "${AWS_DEFAULT_REGION}" != "" ]; then
    REGION="${AWS_DEFAULT_REGION}"
fi

################################################################################

CONFIG="${HOME}/.toast"
if [ -f "${CONFIG}" ]; then
    source "${CONFIG}"
fi

################################################################################

toast() {
    case ${CMD} in
        prepare)
            prepare
            ;;
        update)
            update
            ;;
        config)
            config
            ;;
        install)
            install
            ;;
        build)
            build
            ;;
        releases)
            releases
            ;;
        deploy)
            deploy
            ;;
        *)
            usage
    esac
}

################################################################################

prepare() {
    service_update
    service_install "git zip unzip"

#    command -v git   > /dev/null || service_install git
#    command -v zip   > /dev/null || service_install zip
#    command -v unzip > /dev/null || service_install unzip
}

update() {
    curl -s toast.sh/install-v3 | bash
}

config() {
    config_save
}

install() {
    case ${PARAM1} in
        aws)
            install_aws
            ;;
        java8)
            install_java 8
            ;;
        java9)
            install_java 9
            ;;
        elasticsearch)
            install_elasticsearch
            ;;
        kibana)
            install_kibana
            ;;
        logstash)
            install_logstash
            ;;
        filebeat)
            install_filebeat
            ;;
    esac
}

build() {
    parse_version

    build_version

    case ${PARAM1} in
        beanstalk)
            build_beanstalk
            ;;
        webapp)
            build_webapp
            ;;
        php)
            build_php
            ;;
        node)
            build_node
            ;;
    esac
}

releases() {
    parse_version

    case ${PARAM1} in
        bucket)
            releases_bucket
            ;;
        beanstalk)
            releases_beanstalk
            ;;
        docker)
            releases_docker
            ;;
    esac
}

deploy() {
    parse_version

    case ${PARAM1} in
        webapp)
            deploy_bucket
            ;;
        beanstalk)
            deploy_beanstalk
            ;;
        lambda)
            deploy_lambda
            ;;
    esac
}

################################################################################

config_save() {
    KEY="${PARAM1}"
    VAL="${PARAM2}"

    if [ "${KEY}" == "" ]; then
        error "Not set KEY."
    fi

    echo "${KEY}=${VAL}" >> "${CONFIG}"

    echo_ "${KEY}=${VAL}"
}

install_aws() {
    echo_ "install aws cli..."

    curl -s -o ${TEMP_DIR}/awscli-bundle.zip https://s3.amazonaws.com/aws-cli/awscli-bundle.zip

    if [ -f "${TEMP_DIR}/awscli-bundle.zip" ]; then
        pushd ${TEMP_DIR}

        unzip -q awscli-bundle.zip

        ${SUDO} ./awscli-bundle/install -i /usr/local/aws -b /usr/bin/aws

        popd
    fi

    echo_bar
    echo_ "$(aws --version)"
    echo_bar
}

install_java() {
    VERSION="$1"

    if [ "${VERSION}" == "" ]; then
        VERSION="8"
    fi

    echo_ "install java${VERSION}..."

    ${SHELL_DIR}/install/java${VERSION}.sh "${BUCKET}"

    echo_bar
    echo_ "$(java -version)"
    echo_bar
}

install_elasticsearch() {
    echo_ "install elasticsearch..."

    ${SHELL_DIR}/install/elasticsearch.sh "${BUCKET}"

    echo_bar
}

install_kibana() {
    echo_ "install kibana..."

    ${SHELL_DIR}/install/kibana.sh "${BUCKET}"

    echo_bar
}

install_logstash() {
    echo_ "install logstash..."

    ${SHELL_DIR}/install/logstash.sh "${BUCKET}"

    echo_bar
}

install_filebeat() {
    echo_ "install filebeat..."

    ${SHELL_DIR}/install/filebeat.sh "${BUCKET}"

    echo_bar
}

parse_version() {
    POM_FILE="pom.xml"

    if [ ! -f "${POM_FILE}" ]; then
        error "Not exist file. [${POM_FILE}]"
    fi

    ARR_GROUP=($(cat ${POM_FILE} | grep -oP '(?<=groupId>)[^<]+'))
    ARR_ARTIFACT=($(cat ${POM_FILE} | grep -oP '(?<=artifactId>)[^<]+'))
    ARR_VERSION=($(cat ${POM_FILE} | grep -oP '(?<=version>)[^<]+'))
    ARR_PACKAGING=($(cat ${POM_FILE} | grep -oP '(?<=packaging>)[^<]+'))

    if [ "${ARR_GROUP[0]}" == "" ]; then
        error "Not set groupId."
    fi
    if [ "${ARR_ARTIFACT[0]}" == "" ]; then
        error "Not set artifactId."
    fi

    GROUP_ID="${ARR_GROUP[0]}"
    ARTIFACT_ID="${ARR_ARTIFACT[0]}"
    VERSION="${ARR_VERSION[0]}"
    PACKAGING="${ARR_PACKAGING[0]}"

    GROUP_PATH=$(echo "${GROUP_ID}" | sed "s/\./\//")

    echo_ "groupId=${GROUP_ID}"
    echo_ "artifactId=${ARTIFACT_ID}"
    echo_ "version=${VERSION}"
    echo_ "packaging=${PACKAGING}"

    if [ "${CIRCLE_BRANCH}" != "" ]; then
        BRANCH="${CIRCLE_BRANCH}"
    elif [ "${CI_COMMIT_REF_SLUG}" != "" ]; then
        BRANCH="${CI_COMMIT_REF_SLUG}"
    else
        BRANCH="master"
    fi

    if [ "${CIRCLE_BUILD_NUM}" != "" ]; then
        BUILD="${CIRCLE_BUILD_NUM}"
    else
        BUILD=""
    fi
}

build_version() {
    echo_ "version branch... [${BRANCH}] [${BUILD}]"

    if [ "${BRANCH}" == "master" ] && [ "${BUILD}" != "" ]; then
        VERSION="${VERSION}-${BUILD}"
    fi

    if [ "${VERSION}" == "" ]; then
        error "Not set VERSION."
    fi

    echo_ "version=${VERSION}"

    VER1="<version>[0-9a-zA-Z\.\-]\+<\/version>"
    VER2="<version>${VERSION}<\/version>"

    TEMP_FILE="${TEMP_DIR}/toast-pom.tmp"

    sed "s/$VER1/$VER2/;10q;" ${POM_FILE} > ${TEMP_FILE}
    sed "1,10d" ${POM_FILE} >> ${TEMP_FILE}

    cp -rf ${TEMP_FILE} ${POM_FILE}
}

build_filebeat() {
    FILE="01-filebeat.config"

    FILEBEAT=".ebextensions/${FILE}"

    if [ ! -f "${FILEBEAT}" ]; then
        return
    fi

    echo_ "version filebeat... [${ARTIFACT_ID}] [${VERSION}]"

    TEMP_FILE="/tmp/${FILE}"

    sed "s/PRODUCT/$ARTIFACT_ID/g" ${FILEBEAT} > ${TEMP_FILE}
    cp -rf ${TEMP_FILE} ${FILEBEAT}

    sed "s/VERSION/$VERSION/g" ${FILEBEAT} > ${TEMP_FILE}
    cp -rf ${TEMP_FILE} ${FILEBEAT}
}

build_beanstalk() {
    echo_ "build for beanstalk..."

    if [ ! -d "target/docker" ]; then
        mkdir "target/docker"
    fi

    # ROOT.${packaging}
    cp -rf "target/${ARTIFACT_ID}-${VERSION}.${PACKAGING}" "target/docker/ROOT.${PACKAGING}"

    FILES="ROOT.${PACKAGING}"

    # Dockerfile
    if [ -f "Dockerfile" ]; then
        cp -rf "Dockerfile" "target/docker/Dockerfile"

        FILES="${FILES} Dockerfile"
    fi

    # Dockerrun
    if [ -f "Dockerrun.aws.json" ]; then
        cp -rf "Dockerrun.aws.json" "target/docker/Dockerrun.aws.json"

        FILES="${FILES} Dockerrun.aws.json"
    fi

    # Procfile
    if [ -f "Procfile" ]; then
        cp -rf "Procfile" "target/docker/Procfile"

        FILES="${FILES} Procfile"
    fi

    # .ebextensions
    if [ -d ".ebextensions" ]; then
        cp -rf ".ebextensions" "target/docker/.ebextensions"

        FILES="${FILES} .ebextensions"
    fi

    pushd target/docker

    zip -q -r ../${ARTIFACT_ID}-${VERSION}.zip ${FILES}

    popd
}

build_webapp() {
    echo_ "build for webapp..."

    if [ -d target ]; then
        rm -rf target
    fi

    mkdir target

    pushd src/main/webapp

    zip -q -r ../../../target/${ARTIFACT_ID}-${VERSION}.${PACKAGING} *

    popd
}

build_php() {
    echo_ "build for php..."

    if [ -d target ]; then
        rm -rf target
    fi

    mkdir target

    pushd src/main/webapp

    if [ -f composer.json ]; then
        curl -s https://getcomposer.org/installer | php

        php composer.phar install

        rm -rf composer.phar
    fi

    zip -q -r ../../../target/${ARTIFACT_ID}-${VERSION}.${PACKAGING} *

    popd
}

build_node() {
    echo_ "build for node..."

    if [ -d target ]; then
        rm -rf target
    fi

    mkdir target

    pushd src/main/node

    if [ -f package.json ]; then
        npm install -s
    fi

    zip -q -r ../../../target/${ARTIFACT_ID}-${VERSION}.zip *

    popd
}

upload_bucket() {
    EXT="$1"

    PACKAGE_PATH="target/${ARTIFACT_ID}-${VERSION}.${EXT}"

    if [ ! -f "${PACKAGE_PATH}" ]; then
        return
    fi

    UPLOAD_PATH="s3://${BUCKET}/maven2/${GROUP_PATH}/${ARTIFACT_ID}/${VERSION}/"

    echo_ "--> from: ${PACKAGE_PATH}"
    echo_ "--> to  : ${UPLOAD_PATH}"

    if [ "${PARAM2}" == "public" ]; then
        OPTION="--quiet --acl public-read"
    else
        OPTION="--quiet"
    fi

    aws s3 cp "${PACKAGE_PATH}" "${UPLOAD_PATH}" ${OPTION}
}

releases_bucket() {
    POM_FILE="pom.xml"

    if [ -f "${POM_FILE}" ]; then
        cp -rf "${POM_FILE}" "target/${ARTIFACT_ID}-${VERSION}.pom"
    fi

    echo_ "releases to bucket... [${BUCKET}]"

    upload_bucket "pom"
    upload_bucket "war"
    upload_bucket "jar"
    upload_bucket "zip"
}

releases_beanstalk() {
    if [ ! -d "target/docker" ]; then
        build_beanstalk
    fi

    releases_bucket

    STAMP=$(date "+%y%m%d-%H%M")

    S3_KEY="maven2/${GROUP_PATH}/${ARTIFACT_ID}/${VERSION}/${ARTIFACT_ID}-${VERSION}.zip"

    echo_ "releases to beanstalk versions..."

    aws elasticbeanstalk create-application-version \
        --application-name "${ARTIFACT_ID}" \
        --version-label "${VERSION}-${STAMP}" \
        --description "${BRANCH}" \
        --source-bundle S3Bucket="${BUCKET}",S3Key="${S3_KEY}" \
        --auto-create-application
}

releases_docker() {
    if [ ! -d "target/docker" ]; then
        build_docker
    fi

    if [ "${USERID}" != "" ]; then
        REGISTRY="${USERID}.dkr.ecr.${REGION}.amazonaws.com"
    fi

    if [ "${REGISTRY}" == "" ]; then
        error "Not set REGISTRY."
    fi

    NAME="${ARTIFACT_ID}:${VERSION}"

    echo_ ">> docker... [${REGISTRY}]"

    docker version

    pushd target/docker

    echo_ ">> docker build... [${NAME}]"

    docker build --rm=false -t ${REGISTRY}/${NAME} .

    docker images

    if [ "${PARAM2}" == "ECR" ]; then
        echo_ ">> docker login..."

        ECR_LOGIN=$(aws ecr get-login --region ${REGION})
        eval ${ECR_LOGIN}
    fi

    echo_ ">> docker push... [${NAME}]"

    docker push ${REGISTRY}/${NAME}

    echo_ ">> docker tag... [${ARTIFACT_ID}:latest]"

    docker tag ${REGISTRY}/${NAME} ${REGISTRY}/${ARTIFACT_ID}:latest
    docker push ${REGISTRY}/${ARTIFACT_ID}:latest

    #ECR_TAG=$(aws ecr batch-get-image --repository-name ${ARTIFACT_ID} --image-ids imageTag=${VERSION} --query images[].imageManifest --output text)
    #aws ecr put-image --repository-name ${ARTIFACT_ID} --image-tag latest --image-manifest "${ECR_TAG}"

    popd
}

deploy_bucket() {
    if [ "${PARAM2}" != "" ]; then
        BUCKET="${PARAM2}"
    fi

    PACKAGE_PATH="src/main/webapp"

    DEPLOY_PATH="s3://${BUCKET}"

    echo_ "deploy webapp... [${DEPLOY_PATH}]"

    OPTION="--quiet --acl public-read"

    aws s3 sync "${PACKAGE_PATH}" "${DEPLOY_PATH}" ${OPTION}
}

deploy_beanstalk() {
    STAMP="$(cat .stamp)"

    BRANCH="$(cat .branch)"

    echo_ "deploy to beanstalk... [${ARTIFACT_ID}-${BRANCH}]"

    if [ "${PARAM2}" == "" ]; then
        ENV_NAME="${ARTIFACT_ID}-${BRANCH}"
    else
        ENV_NAME="${PARAM2}"
    fi

    aws elasticbeanstalk update-environment \
        --application-name "${ARTIFACT_ID}" \
        --environment-name "${ENV_NAME}" \
        --version-label "${VERSION}-${STAMP}"
}

deploy_lambda() {
    BRANCH="$(cat .branch)"

    echo_ "deploy to lambda... [${ARTIFACT_ID}-${BRANCH}]"

    PACKAGE_PATH="target/${ARTIFACT_ID}-${VERSION}.zip"

    if [ "${PARAM2}" == "" ]; then
        FUNCTION_NAME="${ARTIFACT_ID}-${BRANCH}"
    else
        FUNCTION_NAME="${PARAM2}"
    fi

    aws lambda update-function-code \
        --function-name "${FUNCTION_NAME}" \
        --zip-file "fileb://${PACKAGE_PATH}"
}

service_update() {
    if [ "${OS_TYPE}" == "Ubuntu" ] || [ "${OS_TYPE}" == "coreos" ]; then
        ${SUDO} apt-get update
    else
        ${SUDO} yum update -y
    fi
}

service_install() {
    if [ "${OS_TYPE}" == "Ubuntu" ] || [ "${OS_TYPE}" == "coreos" ]; then
        ${SUDO} apt-get install -y $1
    else
        ${SUDO} yum install -y $1
    fi
}

service_remove() {
    if [ "${OS_TYPE}" == "Ubuntu" ] || [ "${OS_TYPE}" == "coreos" ]; then
        ${SUDO} apt-get remove -y $1
    else
        ${SUDO} yum remove -y $1
    fi
}

################################################################################

self_info() {
    echo_bar
    echo_ "OS    : ${OS_NAME} ${OS_TYPE}"
    echo_ "HOME  : ${HOME}"
    echo_bar
}

echo_bar() {
    echo_ "================================================================================"
}

echo_toast() {
    if [ -r /tmp/toaster.old ]; then
        VER="$(cat /tmp/toaster.old)"
    else
        VER="v3"
    fi

    echo_bar
    echo_ "      _                  _        "
    echo_ "     | |_ ___   __ _ ___| |_      "
    echo_ "     | __/ _ \ / _\` / __| __|    "
    echo_ "     | || (_) | (_| \__ \ |_      "
    echo_ "      \__\___/ \__,_|___/\__|     "
    echo_ "                                  "
    echo_ "        by nalbam (${VER})    "
    echo_bar
}

working() {
    echo_toast
    echo_ " Not Implemented."
    echo_bar
}

usage() {
    echo_toast
    echo_ " Usage: toast {update|config|install|version|build|releases|deploy}"
    echo_bar
}

################################################################################

toast

################################################################################

# done
success "done."
