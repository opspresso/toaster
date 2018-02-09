#!/bin/bash

echo_() {
    echo -e "$1"
    echo "$1" >> /tmp/toast.log
}

success() {
    echo -e "$1"
    echo "$1" >> /tmp/toast.log
    exit 0
}

error() {
    echo -e "$1"
    echo "$1" >> /tmp/toast.log
    exit 1
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

BUCKET="repo.toast.sh"

################################################################################

CONFIG="${HOME}/.toast"
if [ -f "${CONFIG}" ]; then
    source "${CONFIG}"
fi

################################################################################

toast() {
    #prepare

    case ${CMD} in
        u|update)
            update
            ;;
        c|config)
            config
            ;;
        i|install)
            install
            ;;
        v|version)
            version
            ;;
        b|build)
            build
            ;;
        p|publish)
            publish
            ;;
        d|deploy)
            deploy
            ;;
        *)
            usage
    esac
}

################################################################################

nothing() {
    REGION=
    BUCKET=
    USERID=
    REPOSITORY=
    LOGZIO_TOKEN=
}

prepare() {
    command -v git   > /dev/null || service_install git
    command -v curl  > /dev/null || service_install curl
    command -v wget  > /dev/null || service_install wget
    command -v unzip > /dev/null || service_install unzip
    command -v jq    > /dev/null || service_install jq
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

version() {
    pom_parse

    version_branch
    version_filebeat
}

build() {
    pom_parse

    case ${PARAM1} in
        docker)
            build_docker
            ;;
        lambda)
            build_lambda
            ;;
        maven)
            build_maven
            ;;
    esac
}

publish() {
    pom_parse

    case ${PARAM1} in
        bk|bucket)
            publish_bucket
            ;;
        eb|beanstalk)
            publish_beanstalk
            ;;
        docker)
            publish_docker
            ;;
    esac
}

deploy() {
    pom_parse

    case ${PARAM1} in
        bk|bucket)
            deploy_bucket
            ;;
        eb|beanstalk)
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

    if [ "${KEY}" == "REGION" ]; then
        aws configure set default.region ${VAL}
    fi
}

install_aws() {
    echo_ "install aws cli..."

    wget -q -N -P "${TEMP_DIR}" https://s3.amazonaws.com/aws-cli/awscli-bundle.zip

    if [ -f "${TEMP_DIR}/awscli-bundle.zip" ]; then
        pushd ${TEMP_DIR}

        unzip -q awscli-bundle.zip

        sudo ./awscli-bundle/install -i /usr/local/aws -b /usr/bin/aws

        popd
    fi

    echo_bar
    echo_ "$(/usr/bin/aws --version)"
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

pom_parse() {
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
}

version_branch() {
    BRANCH="${PARAM1}"
    BUILD="${PARAM2}"

    echo_ "version branch... [${BRANCH}] [${BUILD}]"

    if [ "${BRANCH}" == "" ]; then
        BRANCH="master"
    fi

    echo "${BRANCH}" > .branch
    echo_ "branch=${BRANCH}"

    if [ "${BRANCH}" == "master" ]; then
        if [ "${BUILD}" != "" ]; then
            VERSION="${VERSION}-${BUILD}"
        fi
    else
        VERSION="${VERSION}-SNAPSHOT"
    fi

    pom_replace
}

version_filebeat() {
    FILEBEAT=".ebextensions/01-filebeat.config"

    if [ ! -f "${FILEBEAT}" ]; then
        return
    fi

    echo_ "version filebeat... [${ARTIFACT_ID}] [${VERSION}]"

    TEMP_FILE="/tmp/01-filebeat.config"

    sed "s/PRODUCT/$ARTIFACT_ID/g" ${FILEBEAT} > ${TEMP_FILE}
    cp -rf ${TEMP_FILE} ${FILEBEAT}

    sed "s/VERSION/$VERSION/g" ${FILEBEAT} > ${TEMP_FILE}
    cp -rf ${TEMP_FILE} ${FILEBEAT}

    if [ "${LOGZIO_TOKEN}" != "" ]; then
        sed "s/LOGZIO_TOKEN/$LOGZIO_TOKEN/g" ${FILEBEAT} > ${TEMP_FILE}
        cp -rf ${TEMP_FILE} ${FILEBEAT}
    fi
}

pom_replace() {
    POM_FILE="pom.xml"

    if [ ! -f "${POM_FILE}" ]; then
        error "Not exist file. [${POM_FILE}]"
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

upload_repo() {
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

build_docker() {
    echo_ "build for docker..."

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

build_lambda() {
    echo_ "build for lambda... [${PARAM2}]"

    if [ "${PARAM2}" == "" ]; then
        error "Not set TARGET."
    fi
    if [ ! -d "src/main/${PARAM2}" ]; then
        error "Not set TARGET."
    fi

    if [ -d target ]; then
        rm -rf target
    fi

    mkdir target

    pushd src/main/${PARAM2}

    if [ "${PARAM2}" == "node" ]; then
        npm install -s
    fi

    zip -q -r ../../../target/${ARTIFACT_ID}-${VERSION}.zip *

    popd
}

build_maven() {
    echo_ "build for maven..."

    mvn clean package -DskipTests
}

publish_bucket() {
    POM_FILE="pom.xml"

    if [ -f "${POM_FILE}" ]; then
        cp -rf "${POM_FILE}" "target/${ARTIFACT_ID}-${VERSION}.pom"
    fi

    if [ "${PARAM2}" != "none" ]; then
        echo_ "publish to bucket... [${BUCKET}]"

        upload_repo "zip"
        upload_repo "war"
        upload_repo "jar"
        upload_repo "pom"
    fi
}

publish_beanstalk() {
    if [ ! -d "target/docker" ]; then
        build_docker
    fi

    publish_bucket

    STAMP=$(date "+%y%m%d-%H%M")
    echo "${STAMP}" > .stamp

    BRANCH="$(cat .branch)"
    GIT_ID="" # TODO "$(cat .git_id)"

    S3_KEY="maven2/${GROUP_PATH}/${ARTIFACT_ID}/${VERSION}/${ARTIFACT_ID}-${VERSION}.zip"

    echo_ "publish to beanstalk versions..."

    aws elasticbeanstalk create-application-version \
        --application-name "${ARTIFACT_ID}" \
        --version-label "${VERSION}-${STAMP}" \
        --description "${BRANCH} (${GIT_ID})" \
        --source-bundle S3Bucket="${BUCKET}",S3Key="${S3_KEY}" \
        --auto-create-application
}

publish_docker() {
    if [ ! -d "target/docker" ]; then
        build_docker
    fi

    if [ "${USERID}" != "" ]; then
        REPOSITORY="${USERID}.dkr.ecr.${REGION}.amazonaws.com"
    fi

    if [ "${REPOSITORY}" == "" ]; then
        error "Not set REPOSITORY."
    fi

    echo_ "publish to docker... [${REPOSITORY}]"

    if [ "${PARAM2}" == "ECR" ]; then
        ECR_LOGIN=$(aws ecr get-login --no-include-email --region ${REGION})
        eval ${ECR_LOGIN}
    fi

    pushd target/docker

    echo_ "docker build... [${ARTIFACT_ID}]"

    docker build --rm=false -t ${REPOSITORY}/${ARTIFACT_ID}:${VERSION} .

    docker images

    echo_ "docker push... [${ARTIFACT_ID}]"

    docker push ${REPOSITORY}/${ARTIFACT_ID}:${VERSION}

    popd
}

deploy_bucket() {
    if [ "${PARAM2}" == "" ]; then
        error "Not set BUCKET."
    fi

    PACKAGE_PATH="target/${ARTIFACT_ID}-${VERSION}"

    if [ ! -d ${PACKAGE_PATH} ]; then
        unzip -q "${PACKAGE_PATH}.${PACKAGING}" -d "${PACKAGE_PATH}"

        if [ ! -d ${PACKAGE_PATH} ]; then
            error "Not set PACKAGE_PATH."
        fi
    fi

    DEPLOY_PATH="s3://${PARAM2}"

    echo_ "deploy to bucket... [${DEPLOY_PATH}]"

    OPTION="--acl public-read"

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

package_check() {
    command -v aws > /dev/null || (echo "aws cli must be installed" && exit 1)
    command -v curl > /dev/null || (echo "curl must be installed" && exit 1)
    command -v wget > /dev/null || (echo "wget must be installed" && exit 1)
}

service_update() {
    if [ "${OS_TYPE}" == "Ubuntu" ]; then
        sudo apt-get update
    else
        sudo yum update -y
    fi
}

service_install() {
    if [ "${OS_TYPE}" == "Ubuntu" ]; then
        sudo apt-get install -y $1
    else
        sudo yum install -y $1
    fi
}

service_remove() {
    if [ "${OS_TYPE}" == "Ubuntu" ]; then
        sudo apt-get remove -y $1
    else
        sudo yum remove -y $1
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
    echo_ "                              _  _          _                  _        "
    echo_ "      _   _  __ _ _ __   ___ | |(_) __ _   | |_ ___   __ _ ___| |_      "
    echo_ "     | | | |/ _\` | '_ \ / _ \| || |/ _\` |  | __/ _ \ / _\` / __| __|  "
    echo_ "     | |_| | (_| | | | | (_) | || | (_| |  | || (_) | (_| \__ \ |_      "
    echo_ "      \__, |\__,_|_| |_|\___/|_|/ |\__,_|   \__\___/ \__,_|___/\__|     "
    echo_ "      |___/                   |__/                                      "
    echo_ "                                            by nalbam (${VER})       "
    echo_bar
}

working() {
    echo_toast
    echo_ " Not Implemented."
    echo_bar
}

usage() {
    echo_toast
    echo_ " Usage: toast {update|config|install|version|build|publish|deploy}"
    echo_bar
}

################################################################################

toast

################################################################################

# done
success "done."
