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
    # toast-v2
    TOAST=
    TOKEN=

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
    CI_COMMIT_SHA=
}

################################################################################

OS_NAME="$(uname)"
OS_FULL="$(uname -a)"

if [ "${OS_NAME}" == "Linux" ]; then
    if [ $(echo "${OS_FULL}" | grep -c "amzn1") -gt 0 ]; then
        OS_TYPE="amzn"
    elif [ $(echo "${OS_FULL}" | grep -c "amzn2") -gt 0 ]; then
        OS_TYPE="amzn"
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
        release)
            release
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
    curl -s repo.toast.sh/install-v3 | bash
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

    case ${PARAM1} in
        version)
            build_version
            ;;
        beanstalk)
            build_beanstalk
            ;;
        webapp)
            build_webapp
            ;;
        node)
            build_node
            ;;
    esac
}

release() {
    parse_version

    case ${PARAM1} in
        bucket)
            release_bucket
            ;;
        beanstalk)
            release_beanstalk
            ;;
        docker)
            release_docker
            ;;
        toast)
            release_toast
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

    if [ -f target/${POM_FILE} ]; then
        cp -rf target/${POM_FILE} ${POM_FILE}
    fi
    if [ ! -f ${POM_FILE} ]; then
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

    # branch
    if [ "${CIRCLE_BRANCH}" != "" ]; then
        BRANCH="${CIRCLE_BRANCH}"
    elif [ "${CI_COMMIT_REF_SLUG}" != "" ]; then
        BRANCH="${CI_COMMIT_REF_SLUG}"
    else
        BRANCH="master"
    fi

    # build no
    if [ "${CIRCLE_BUILD_NUM}" != "" ]; then
        BUILD="${CIRCLE_BUILD_NUM}"
    elif [ -d .git ]; then
        BUILD="$(git rev-parse --short HEAD)"
    elif [ "${CI_COMMIT_SHA}" != "" ]; then
        BUILD="${CI_COMMIT_SHA:0:6}"
    else
        #BUILD="$(date "+%y%m%d-%H%M")"
        BUILD=""
    fi
}

build_version() {
    echo_ "build version... [${BRANCH}] [${BUILD}]"

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

    mkdir -p target

    cp -rf ${TEMP_FILE} target/${POM_FILE}
    cp -rf ${TEMP_FILE} target/${ARTIFACT_ID}-${VERSION}.pom
}

build_filebeat() {
    FILE="01-filebeat.config"

    FILEBEAT=".ebextensions/${FILE}"

    if [ ! -f "${FILEBEAT}" ]; then
        return
    fi

    echo_ "build filebeat... [${ARTIFACT_ID}] [${VERSION}]"

    TEMP_FILE="/tmp/${FILE}"

    sed "s/PRODUCT/$ARTIFACT_ID/g" ${FILEBEAT} > ${TEMP_FILE}
    cp -rf ${TEMP_FILE} ${FILEBEAT}

    sed "s/VERSION/$VERSION/g" ${FILEBEAT} > ${TEMP_FILE}
    cp -rf ${TEMP_FILE} ${FILEBEAT}
}

build_webapp() {
    echo_ "build for webapp..."

    mkdir -p target

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

    mkdir -p target

    pushd src/main/node

    if [ -f package.json ]; then
        npm install -s
    fi

    zip -q -r ../../../target/${ARTIFACT_ID}-${VERSION}.zip *

    popd
}

build_beanstalk() {
    echo_ "build for beanstalk..."

    mkdir -p target

    FILES=

    # ROOT.${packaging}
    if [ -f "target/${ARTIFACT_ID}-${VERSION}.${PACKAGING}" ]; then
        cp -rf "target/${ARTIFACT_ID}-${VERSION}.${PACKAGING}" "target/ROOT.${PACKAGING}"

        FILES="${FILES} ROOT.${PACKAGING}"
    fi

    # Dockerfile
    if [ -f "Dockerfile" ]; then
        cp -rf "Dockerfile" "target/Dockerfile"

        FILES="${FILES} Dockerfile"
    fi

    # Dockerrun
    if [ -f "Dockerrun.aws.json" ]; then
        cp -rf "Dockerrun.aws.json" "target/Dockerrun.aws.json"

        FILES="${FILES} Dockerrun.aws.json"
    fi

    # .ebextensions
    if [ -d ".ebextensions" ]; then
        cp -rf ".ebextensions" "target/.ebextensions"

        FILES="${FILES} .ebextensions"
    fi

    pushd target

    zip -q -r ${ARTIFACT_ID}-${VERSION}.zip ${FILES}

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

release_bucket() {
    if [ -f pom.xml ] && [ ! -f target/${ARTIFACT_ID}-${VERSION}.pom ]; then
        cp -rf pom.xml target/${ARTIFACT_ID}-${VERSION}.pom
    fi

    echo_ "release to bucket... [${BUCKET}]"

    upload_bucket "pom"
    upload_bucket "war"
    upload_bucket "jar"
    upload_bucket "zip"
    upload_bucket "tar.gz"
}

release_toast() {
    if [ "${TOAST}" == "" ] || [ "${TOKEN}" == "" ]; then
        error "Not set TOAST or TOKEN."
    fi

    if [ "${PARAM2}" == "" ]; then
        PACKAGE="${PACKAGING}"
    else
        PACKAGE="${PARAM2}"
    fi

    echo_ "release to toast... [${TOAST}]"

    # version save
    URL="${TOAST}/version/build/${ARTIFACT_ID}/${VERSION}"
    RES=$(curl -s --data "token=${TOKEN}&groupId=${GROUP_ID}&artifactId=${ARTIFACT_ID}&packaging=${PACKAGE}&branch=${BRANCH}" "${URL}")
    ARR=(${RES})

    if [ "${ARR[0]}" != "OK" ]; then
        echo_ "Server Error. [${URL}][${RES}]"
    fi

    # get version
#    URL="${TOAST}/version/latest/${ARTIFACT_ID}"
#    RES=$(curl -s --data "token=${TOKEN}&groupId=${GROUP_ID}&artifactId=${ARTIFACT_ID}&packaging=${PACKAGING}&branch=${BRANCH}" "${URL}")
#    ARR=(${RES})
#
#    if [ "${ARR[0]}" != "OK" ]; then
#        echo_ "Server Error. [${URL}][${RES}]"
#    fi
}

release_beanstalk() {
    build_beanstalk

    release_bucket

    echo_ "release to beanstalk versions..."

    S3_KEY="maven2/${GROUP_PATH}/${ARTIFACT_ID}/${VERSION}/${ARTIFACT_ID}-${VERSION}.zip"

    aws elasticbeanstalk create-application-version \
        --application-name "${ARTIFACT_ID}" \
        --version-label "${VERSION}" \
        --description "${BRANCH}" \
        --source-bundle S3Bucket="${BUCKET}",S3Key="${S3_KEY}"
}

release_docker() {
    if [ "${REGISTRY}" == "" ]; then
        error "Not set REGISTRY."
    fi

    echo_ ">> docker registry... [${REGISTRY}]"

    IMAGE="${ARTIFACT_ID}:${VERSION}"

    pushd target

    cp -rf "${ARTIFACT_ID}-${VERSION}.${PACKAGING}" "ROOT.${PACKAGING}"
    cp -rf "../Dockerfile" "Dockerfile"

    docker version

    echo_ ">> docker build... [${IMAGE}]"

    docker build --rm=false -t ${REGISTRY}/${IMAGE} .

    docker images

    if [ "${PARAM2}" == "ECR" ]; then
        echo_ ">> docker login..."

        ECR_LOGIN=$(aws ecr get-login --region ${REGION})
        eval ${ECR_LOGIN}
    else
        echo_ ">> docker login..."

        docker login REGISTRY
    fi

    echo_ ">> docker push... [${IMAGE}]"

    docker push ${REGISTRY}/${IMAGE}

    echo_ ">> docker tag... [${ARTIFACT_ID}:latest]"

    docker tag ${REGISTRY}/${IMAGE} ${REGISTRY}/${ARTIFACT_ID}:latest
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

    echo_ "deploy to bucket... [${DEPLOY_PATH}]"

    OPTION="--quiet --acl public-read"

    aws s3 sync "${PACKAGE_PATH}" "${DEPLOY_PATH}" ${OPTION}
}

deploy_beanstalk() {
    if [ "${PARAM2}" == "" ]; then
        ENV_NAME="${ARTIFACT_ID}-${BRANCH}"
    else
        ENV_NAME="${PARAM2}"
    fi

    S3_KEY="maven2/${GROUP_PATH}/${ARTIFACT_ID}/${VERSION}/${ARTIFACT_ID}-${VERSION}.zip"

    echo_ "release to beanstalk versions... [${ENV_NAME}] [${VERSION}]"

    aws elasticbeanstalk delete-application-version \
        --application-name "${ARTIFACT_ID}" \
        --version-label "${ENV_NAME}" \

    aws elasticbeanstalk create-application-version \
        --application-name "${ARTIFACT_ID}" \
        --version-label "${ENV_NAME}" \
        --source-bundle S3Bucket="${BUCKET}",S3Key="${S3_KEY}"

    echo_ "deploy to beanstalk... [${ENV_NAME}] [${VERSION}]"

    aws elasticbeanstalk update-environment \
        --application-name "${ARTIFACT_ID}" \
        --environment-name "${ENV_NAME}" \
        --version-label "${ENV_NAME}"
}

deploy_lambda() {
    if [ "${PARAM2}" == "" ]; then
        FUNCTION_NAME="${ARTIFACT_ID}-${BRANCH}"
    else
        FUNCTION_NAME="${PARAM2}"
    fi

    echo_ "deploy to lambda... [${FUNCTION_NAME}] [${VERSION}]"

    #PACKAGE_PATH="target/${ARTIFACT_ID}-${VERSION}.zip"
    S3_KEY="maven2/${GROUP_PATH}/${ARTIFACT_ID}/${VERSION}/${ARTIFACT_ID}-${VERSION}.zip"

    aws lambda update-function-code \
        --function-name "${FUNCTION_NAME}" \
        --s3-bucket "${BUCKET}" \
        --s3-key "${S3_KEY}"
        #--zip-file "fileb://${PACKAGE_PATH}"
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

    #figlet toast
    echo_bar
    echo_ "      _                  _     "
    echo_ "     | |_ ___   __ _ ___| |_   "
    echo_ "     | __/ _ \ / _\` / __| __| "
    echo_ "     | || (_) | (_| \__ \ |_   "
    echo_ "      \__\___/ \__,_|___/\__|  by nalbam (${VER}) "
    echo_bar
}

working() {
    echo_toast
    echo_ " Not Implemented."
    echo_bar
}

usage() {
    echo_toast
    echo_ " Usage: toast {update|config|install|version|build|release|deploy}"
    echo_bar
}

################################################################################

toast

################################################################################

# done
success "done."
