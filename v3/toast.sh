#!/bin/bash

print() {
    echo -e "$@"
}

success() {
    echo -e "$(tput setaf 2)$@$(tput sgr0)"
    exit 0
}

error() {
    echo -e "$(tput setaf 1)$@$(tput sgr0)"
    exit 1
}

logo() {
    if [ -r /tmp/toaster.old ]; then
        VER="$(cat /tmp/toaster.old)"
    else
        VER="v3"
    fi

    #figlet toast
    bar
    print "  _                  _    "
    print " | |_ ___   __ _ ___| |_  "
    print " | __/ _ \ / _' / __| __| "
    print " | || (_) | (_| \__ \ |_  "
    print "  \__\___/ \__,_|___/\__|  by nalbam (${VER}) "
    bar
}

working() {
    logo
    print " Not Implemented. "
    bar
}

usage() {
    logo
    print " Usage: toast.sh {update|config|install|build|release|deploy} "
    bar
}

bar() {
    print "================================================================================"
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

OS_NAME="$(uname | awk '{print tolower($0)}')"
OS_FULL="$(uname -a)"
OS_TYPE=

if [ "${OS_NAME}" == "linux" ]; then
    if [ $(echo "${OS_FULL}" | grep -c "amzn1") -gt 0 ]; then
        OS_TYPE="yum"
    elif [ $(echo "${OS_FULL}" | grep -c "amzn2") -gt 0 ]; then
        OS_TYPE="yum"
    elif [ $(echo "${OS_FULL}" | grep -c "el6") -gt 0 ]; then
        OS_TYPE="yum"
    elif [ $(echo "${OS_FULL}" | grep -c "el7") -gt 0 ]; then
        OS_TYPE="yum"
    elif [ $(echo "${OS_FULL}" | grep -c "Ubuntu") -gt 0 ]; then
        OS_TYPE="apt"
    elif [ $(echo "${OS_FULL}" | grep -c "coreos") -gt 0 ]; then
        OS_TYPE="apt"
    fi
elif [ "${OS_NAME}" == "darwin" ]; then
    OS_TYPE="brew"
fi

if [ "${OS_TYPE}" == "" ]; then
    error "Not supported OS. [${OS_NAME}]"
fi

if [ "${OS_TYPE}" == "brew" ]; then
    # brew for mac
    command -v brew > /dev/null || ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
else
    # localtime
    sudo ln -sf "/usr/share/zoneinfo/Asia/Seoul" "/etc/localtime"

    # for ubuntu
    if [ "${OS_TYPE}" == "apt" ]; then
        export LC_ALL=C
    fi
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

BUCKET=${AWS_DEFAULT_BUCKET:-repo.toast.sh}
REGION=${AWS_DEFAULT_REGION:-ap-northeast-2}

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
        bastion)
            bastion
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

    command -v git   > /dev/null || service_install git
    command -v zip   > /dev/null || service_install zip
    command -v unzip > /dev/null || service_install unzip
}

update() {
    curl -sL toast.sh/install-v3 | bash
}

bastion() {
    curl -sL toast.sh/helper/bastion.sh | bash
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

    print "${KEY}=${VAL}"

    if [ "${KEY}" == "REGION" ]; then
        aws configure set default.region ${VAL}
    fi
}

install_aws() {
    print "install aws cli..."

    pip install --upgrade --user awscli

    bar
    print "$(aws --version)"
    bar
}

install_java() {
    VERSION="$1"

    if [ "${VERSION}" == "" ]; then
        VERSION="8"
    fi

    print "install java${VERSION}..."

    ${SHELL_DIR}/extra/install/java${VERSION}.sh "${BUCKET}"

    bar
    print "$(java -version)"
    bar
}

install_elasticsearch() {
    print "install elasticsearch..."

    ${SHELL_DIR}/extra/install/elasticsearch.sh "${BUCKET}"

    bar
}

install_kibana() {
    print "install kibana..."

    ${SHELL_DIR}/extra/install/kibana.sh "${BUCKET}"

    bar
}

install_logstash() {
    print "install logstash..."

    ${SHELL_DIR}/extra/install/logstash.sh "${BUCKET}"

    bar
}

install_filebeat() {
    print "install filebeat..."

    ${SHELL_DIR}/extra/install/filebeat.sh "${BUCKET}"

    bar
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

    print "groupId=${GROUP_ID}"
    print "artifactId=${ARTIFACT_ID}"
    print "version=${VERSION}"
    print "packaging=${PACKAGING}"

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
    print "build version... [${BRANCH}] [${BUILD}]"

    if [ "${BRANCH}" == "master" ] && [ "${BUILD}" != "" ]; then
        VERSION="${VERSION}-${BUILD}"
    fi

    if [ "${VERSION}" == "" ]; then
        error "Not set VERSION."
    fi

    print "version=${VERSION}"

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

    print "build filebeat... [${ARTIFACT_ID}] [${VERSION}]"

    TEMP_FILE="/tmp/${FILE}"

    sed "s/PRODUCT/$ARTIFACT_ID/g" ${FILEBEAT} > ${TEMP_FILE}
    cp -rf ${TEMP_FILE} ${FILEBEAT}

    sed "s/VERSION/$VERSION/g" ${FILEBEAT} > ${TEMP_FILE}
    cp -rf ${TEMP_FILE} ${FILEBEAT}
}

build_webapp() {
    print "build for webapp..."

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
    print "build for node..."

    mkdir -p target

    pushd src/main/node

    if [ -f package.json ]; then
        npm install
    fi

    zip -q -r ../../../target/${ARTIFACT_ID}-${VERSION}.zip *

    popd
}

build_beanstalk() {
    print "build for beanstalk..."

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

    print "--> from: ${PACKAGE_PATH}"
    print "--> to  : ${UPLOAD_PATH}"

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

    print "release to bucket... [${BUCKET}]"

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

    print "release to toast... [${TOAST}]"

    # version save
    URL="${TOAST}/version/build/${ARTIFACT_ID}/${VERSION}"
    RES=$(curl -sL --data "token=${TOKEN}&groupId=${GROUP_ID}&artifactId=${ARTIFACT_ID}&packaging=${PACKAGE}&branch=${BRANCH}" "${URL}")
    ARR=(${RES})

    if [ "${ARR[0]}" != "OK" ]; then
        print "Server Error. [${URL}][${RES}]"
    fi

    # get version
#    URL="${TOAST}/version/latest/${ARTIFACT_ID}"
#    RES=$(curl -sL --data "token=${TOKEN}&groupId=${GROUP_ID}&artifactId=${ARTIFACT_ID}&packaging=${PACKAGING}&branch=${BRANCH}" "${URL}")
#    ARR=(${RES})
#
#    if [ "${ARR[0]}" != "OK" ]; then
#        print "Server Error. [${URL}][${RES}]"
#    fi
}

release_beanstalk() {
    build_beanstalk

    release_bucket

    print "release to beanstalk versions... [${ARTIFACT_ID}] [${VERSION}]"

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

    print ">> docker registry... [${REGISTRY}]"

    IMAGE="${ARTIFACT_ID}:${VERSION}"

    pushd target

    cp -rf "${ARTIFACT_ID}-${VERSION}.${PACKAGING}" "ROOT.${PACKAGING}"
    cp -rf "../Dockerfile" "Dockerfile"

    docker version

    print ">> docker build... [${IMAGE}]"

    docker build --rm=false -t ${REGISTRY}/${IMAGE} .

    docker images

    if [ "${PARAM2}" == "ECR" ]; then
        print ">> docker login..."

        ECR_LOGIN=$(aws ecr get-login --region ${REGION})
        eval ${ECR_LOGIN}
    else
        print ">> docker login..."

        docker login REGISTRY
    fi

    print ">> docker push... [${IMAGE}]"

    docker push ${REGISTRY}/${IMAGE}

    print ">> docker tag... [${ARTIFACT_ID}:latest]"

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

    print "deploy to bucket... [${DEPLOY_PATH}]"

    OPTION="--quiet --acl public-read"

    aws s3 sync "${PACKAGE_PATH}" "${DEPLOY_PATH}" ${OPTION}
}

deploy_beanstalk() {
    if [ "${PARAM2}" == "" ]; then
        ENV_NAME="${ARTIFACT_ID}-${BRANCH}"
    else
        ENV_NAME="${PARAM2}"
    fi

    build_beanstalk

    release_bucket

    print "release to beanstalk versions... [${ENV_NAME}] [${VERSION}]"

    S3_KEY="maven2/${GROUP_PATH}/${ARTIFACT_ID}/${VERSION}/${ARTIFACT_ID}-${VERSION}.zip"

    aws elasticbeanstalk delete-application-version \
        --application-name "${ARTIFACT_ID}" \
        --version-label "${ENV_NAME}" \

    aws elasticbeanstalk create-application-version \
        --application-name "${ARTIFACT_ID}" \
        --version-label "${ENV_NAME}" \
        --source-bundle S3Bucket="${BUCKET}",S3Key="${S3_KEY}"

    print "deploy to beanstalk... [${ENV_NAME}] [${VERSION}]"

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

    print "deploy to lambda... [${FUNCTION_NAME}] [${VERSION}]"

    #PACKAGE_PATH="target/${ARTIFACT_ID}-${VERSION}.zip"
    S3_KEY="maven2/${GROUP_PATH}/${ARTIFACT_ID}/${VERSION}/${ARTIFACT_ID}-${VERSION}.zip"

    aws lambda update-function-code \
        --function-name "${FUNCTION_NAME}" \
        --s3-bucket "${BUCKET}" \
        --s3-key "${S3_KEY}"
        #--zip-file "fileb://${PACKAGE_PATH}"
}

service_update() {
    if [ "${OS_TYPE}" == "apt" ]; then
        ${SUDO} apt update && ${SUDO} apt upgrade -y
    elif [ "${OS_TYPE}" == "yum" ]; then
        ${SUDO} yum update -y
    elif [ "${OS_TYPE}" == "brew" ]; then
        brew update && brew upgrade
    fi
}

service_install() {
    if [ "${OS_TYPE}" == "apt" ]; then
        ${SUDO} apt install -y $1
    elif [ "${OS_TYPE}" == "yum" ]; then
        ${SUDO} yum install -y $1
    fi
}

service_remove() {
    if [ "${OS_TYPE}" == "apt" ]; then
        ${SUDO} apt remove -y $1
    elif [ "${OS_TYPE}" == "yum" ]; then
        ${SUDO} yum remove -y $1
    elif [ "${OS_TYPE}" == "brew" ]; then
        brew install $1
    fi
}

################################################################################

self_info() {
    bar
    print "OS    : ${OS_FULL}"
    print "HOME  : ${HOME}"
    bar
}

################################################################################

toast

################################################################################

# done
success "done."
