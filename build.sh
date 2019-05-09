#!/bin/bash

OS_NAME="$(uname | awk '{print tolower($0)}')"

SHELL_DIR=$(dirname $0)

CMD=${1:-${CIRCLE_JOB}}

USERNAME=${CIRCLE_PROJECT_USERNAME:-opspresso}
REPONAME=${CIRCLE_PROJECT_REPONAME:-toaster}

BRANCH=${CIRCLE_BRANCH:-master}

PR_NUM=${CIRCLE_PR_NUMBER}
PR_URL=${CIRCLE_PULL_REQUEST}

################################################################################

# command -v tput > /dev/null && TPUT=true
TPUT=

_echo() {
    if [ "${TPUT}" != "" ] && [ "$2" != "" ]; then
        echo -e "$(tput setaf $2)$1$(tput sgr0)"
    else
        echo -e "$1"
    fi
}

_result() {
    echo
    _echo "# $@" 4
}

_command() {
    echo
    _echo "$ $@" 3
}

_success() {
    echo
    _echo "+ $@" 2
    exit 0
}

_error() {
    echo
    _echo "- $@" 1
    exit 1
}

_replace() {
    if [ "${OS_NAME}" == "darwin" ]; then
        sed -i "" -e "$1" $2
    else
        sed -i -e "$1" $2
    fi
}

_prepare() {
    # target
    mkdir -p ${SHELL_DIR}/target/publish
    mkdir -p ${SHELL_DIR}/target/release

    # 755
    find ./** | grep [.]sh | xargs chmod 755
}

_package() {
    if [ ! -f ${SHELL_DIR}/target/VERSION ]; then
        _error
    fi

    VERSION=$(cat ${SHELL_DIR}/target/VERSION | xargs)
    _result "VERSION=${VERSION}"

    # release
    cp -rf ${SHELL_DIR}/alias.sh   ${SHELL_DIR}/target/release/alias
    cp -rf ${SHELL_DIR}/toaster.sh ${SHELL_DIR}/target/release/toaster

    # publish
    cp -rf ${SHELL_DIR}/alias.sh   ${SHELL_DIR}/target/release/alias
    cp -rf ${SHELL_DIR}/builder.sh ${SHELL_DIR}/target/publish/builder
    cp -rf ${SHELL_DIR}/install.sh ${SHELL_DIR}/target/publish/install
    cp -rf ${SHELL_DIR}/toaster.sh ${SHELL_DIR}/target/release/toaster
    cp -rf ${SHELL_DIR}/tools.sh   ${SHELL_DIR}/target/publish/tools

    # publish web
    cp -rf ${SHELL_DIR}/web/* ${SHELL_DIR}/target/publish/

    # replace
    _replace "s/THIS_VERSION=.*/THIS_VERSION=${VERSION}/g" ${SHELL_DIR}/target/release/toaster
}

################################################################################

_prepare

_package
