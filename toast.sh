#!/bin/bash

VERSION=4.0.0

CMD=$1
SUB=$2

SHELL_DIR=$(dirname "$0")

BUCKET=${AWS_DEFAULT_BUCKET:-repo.toast.sh}
REGION=${AWS_DEFAULT_REGION:-ap-northeast-2}

################################################################################

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
        VER="v4"
    fi

    #figlet toast
    bar
    print "  _                  _    "
    print " | |_ ___   __ _ ___| |_  "
    print " | __/ _ \ / _' / __| __| "
    print " | || (_) | (_| \__ \ |_  "
    print "  \__\___/ \__,_|___/\__|  (${VER}) "
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

toast() {
    case ${CMD} in
        update)
            update
            ;;
        bastion)
            bastion
            ;;
        init)
            init
            ;;
        draft)
            draft
            ;;
        helm)
            helm
            ;;
        *)
            usage
    esac
}

update() {
    curl -sL toast.sh/install | bash
}

bastion() {
    curl -sL toast.sh/helper/bastion.sh | bash
}
