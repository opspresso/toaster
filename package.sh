#!/bin/bash

OS_NAME="$(uname | awk '{print tolower($0)}')"

SHELL_DIR=$(dirname $0)

RUN_PATH=${SHELL_DIR}

CMD=${1:-$CIRCLE_JOB}

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
    mkdir -p ${RUN_PATH}/target/publish
    mkdir -p ${RUN_PATH}/target/release

    # 755
    find ./** | grep [.]sh | xargs chmod 755
}

_package() {
    if [ ! -f ${RUN_PATH}/target/VERSION ]; then
        _error
    fi

    VERSION=$(cat ${RUN_PATH}/target/VERSION | xargs)
    _result "VERSION=${VERSION}"

    # release
    cp -rf ${RUN_PATH}/alias.sh   ${RUN_PATH}/target/release/alias
    cp -rf ${RUN_PATH}/toaster.sh ${RUN_PATH}/target/release/toaster

    # publish
    cp -rf ${RUN_PATH}/actions.sh ${RUN_PATH}/target/publish/actions
    cp -rf ${RUN_PATH}/alias.sh   ${RUN_PATH}/target/publish/alias
    cp -rf ${RUN_PATH}/builder.sh ${RUN_PATH}/target/publish/builder
    cp -rf ${RUN_PATH}/install.sh ${RUN_PATH}/target/publish/install
    cp -rf ${RUN_PATH}/toaster.sh ${RUN_PATH}/target/publish/toaster
    cp -rf ${RUN_PATH}/tools.sh   ${RUN_PATH}/target/publish/tools

    # publish web
    cp -rf ${RUN_PATH}/web/* ${RUN_PATH}/target/publish/

    # replace
    _replace "s/THIS_VERSION=.*/THIS_VERSION=${VERSION}/g" ${RUN_PATH}/target/release/toaster
    _replace "s/THIS_VERSION=.*/THIS_VERSION=${VERSION}/g" ${RUN_PATH}/target/publish/toaster
}

################################################################################

_prepare

case ${CMD} in
    build|package)
        _package
        ;;
esac

_success
