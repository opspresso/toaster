#!/bin/bash

OS_NAME="$(uname | awk '{print tolower($0)}')"

SHELL_DIR=$(dirname $0)

RUN_PATH=${SHELL_DIR}

REPOSITORY=${GITHUB_REPOSITORY}

USERNAME=${GITHUB_ACTOR}
REPONAME=$(echo "${REPOSITORY}" | cut -d'/' -f2)

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
    # chmod 755
    find ./** | grep [.]sh | xargs chmod 755

    # mkdir target
    mkdir -p ${RUN_PATH}/target/publish/tools
    mkdir -p ${RUN_PATH}/target/release
}

################################################################################

_package_sh() {
    TARGET_PATH=$1

    LIST=/tmp/list
    ls ${TARGET_PATH} | grep '[.]sh' | sort > ${LIST}

    while read FILENAME; do
        DESTNAME=$(echo "${FILENAME}" | cut -d'.' -f1)
        cp ${TARGET_PATH}/${FILENAME} ${SHELL_DIR}/target/${DESTNAME}
    done < ${LIST}
}

_package() {
    if [ ! -f ${RUN_PATH}/VERSION ]; then
        _error
    fi

    VERSION=$(cat ${RUN_PATH}/VERSION | xargs)
    _result "VERSION=${VERSION}"

    # release
    cp -rf ${RUN_PATH}/alias.sh   ${RUN_PATH}/target/release/alias
    cp -rf ${RUN_PATH}/toaster.sh ${RUN_PATH}/target/release/toaster

    # publish sh
    _package_sh ${RUN_PATH} ${RUN_PATH}/target/publish
    _package_sh ${RUN_PATH}/tools ${RUN_PATH}/target/publish/tools

    # publish web
    cp -rf ${RUN_PATH}/web/* ${RUN_PATH}/target/publish/

    # replace
    _replace "s/THIS_VERSION=.*/THIS_VERSION=${VERSION}/g" ${RUN_PATH}/target/release/toaster
    _replace "s/THIS_VERSION=.*/THIS_VERSION=${VERSION}/g" ${RUN_PATH}/target/publish/toaster

    ls -al ${RUN_PATH}/target/release
    ls -al ${RUN_PATH}/target/publish

    cat <<EOF > ${RUN_PATH}/target/slack_message.json
{
    "username": "${USERNAME}",
    "attachments": [{
        "color": "good",
        "footer": "<https://github.com/${REPOSITORY}/releases/tag/${VERSION}|${REPOSITORY}>",
        "footer_icon": "https://repo.opspresso.com/favicon/github.png",
        "title": "${REPONAME}",
        "text": "\`${VERSION}\`"
    }]
}
EOF
}

################################################################################

_prepare

_package

_success
