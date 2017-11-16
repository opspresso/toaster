#!/bin/bash

echo_() {
    echo -e "$1"
    echo "$1" >> /tmp/toast.log
}

success() {
    echo -e "$(tput setaf 2)$1$(tput sgr0)"
    echo "$1" >> /tmp/toast.log
}

error() {
    echo -e "$(tput setaf 1)$1$(tput sgr0)"
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

update() {
    curl -s toast.sh/install-v3 | bash
}

config() {
    config_save
}

install() {
    case ${PARAM1} in
        java|java8)
            install_java8
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
        *)
            build_maven
    esac
}

publish() {
    pom_parse

    case ${PARAM1} in
        eb|beanstalk)
            publish_beanstalk
            ;;
        *)
            publish_bucket
    esac
}

deploy() {
    pom_parse

    case ${PARAM1} in
        eb|beanstalk)
            deploy_beanstalk
            ;;
        bk|bucket)
            deploy_bucket
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

    if [ "${KEY}" == "REGION" ]; then
        aws configure set default.region ${VAL}
    fi
}

install_java8() {
    echo_ "install java..."

    ${SHELL_DIR}/install/java8.sh "${BUCKET}"

    echo_bar
    echo_ "$(java -version)"
    echo_bar
}

install_elasticsearch() {
    echo_ "install elasticsearch..."

    ${SHELL_DIR}/install/elasticsearch.sh

    echo_bar
}

install_kibana() {
    echo_ "install kibana..."

    ${SHELL_DIR}/install/kibana.sh

    echo_bar
}

install_logstash() {
    echo_ "install logstash..."

    ${SHELL_DIR}/install/logstash.sh

    echo_bar
}

install_filebeat() {
    echo_ "install filebeat..."

    ${SHELL_DIR}/install/filebeat.sh

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

pom_replace() {
    POM_FILE="pom.xml"

    if [ ! -f "${POM_FILE}" ]; then
        error "Not exist file. [${POM_FILE}]"
    fi

    # TODO get new version

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

version_branch() {
    BRANCH="${PARAM1}"

    if [ "${BRANCH}" == "" ]; then
        BRANCH="master"
    fi

    echo "${BRANCH}" > .branch
    echo_ "branch=${BRANCH}"

    if [ "${BRANCH}" == "master" ]; then
        pom_replace
    fi
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

    zip -q -r ../../../target/${ARTIFACT_ID}-${VERSION} *

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

deploy_beanstalk() {
    STAMP="$(cat .stamp)"

    BRANCH="$(cat .branch)"

    echo_ "deploy to beanstalk... [${ARTIFACT_ID}-${BRANCH}]"

    aws elasticbeanstalk update-environment \
     --application-name "${ARTIFACT_ID}" \
     --environment-name "${ARTIFACT_ID}-${BRANCH}" \
     --version-label "${VERSION}-${STAMP}"
}

deploy_bucket() {
    if [ "${PARAM2}" == "" ]; then
        warning "Not set BUCKET."
        return
    fi

    PACKAGE_PATH="target/${ARTIFACT_ID}-${VERSION}"

    if [ ! -d ${PACKAGE_PATH} ]; then
        unzip -q "${PACKAGE_PATH}.${PACKAGING}" -d "${PACKAGE_PATH}"

        if [ ! -d ${PACKAGE_PATH} ]; then
            warning "Not set PACKAGE_PATH."
            return
        fi
    fi

    echo_ "deploy to bucket... [${PARAM2}]"

    DEPLOY_PATH="s3://${PARAM2}"

    OPTION="--acl public-read"

    aws s3 sync "${PACKAGE_PATH}" "${DEPLOY_PATH}" ${OPTION}
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
    echo_ "                                               by nalbam (${VER})       "
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
