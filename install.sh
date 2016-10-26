#!/bin/bash

success() {
    echo "$(tput setaf 2)$1$(tput sgr0)"
}

warning() {
    echo "$(tput setaf 1)$1$(tput sgr0)"
}

# root
if [ "${HOME}" == "/root" ]; then
    warning "Not supported ROOT."
    exit 1
fi

# git
if [ ! -x "/usr/bin/git" ]; then
    # linux
    OS_NAME=`uname`
    if [ ${OS_NAME} != "Linux" ]; then
        warning "Not supported OS - [${OS_NAME}]"
        exit 1
    fi

    # el or ubuntu
    OS_FULL=`uname -a`
    if [ `echo ${OS_FULL} | grep -c "Ubuntu"` -gt 0 ]; then
        OS_TYPE="Ubuntu"
    else
        if [ `echo ${OS_FULL} | grep -c "el7"` -gt 0 ]; then
            OS_TYPE="el7"
        else
            OS_TYPE="el6"
        fi
    fi

    if [ "${OS_TYPE}" == "Ubuntu" ]; then
        sudo apt-get install -y git
    else
        sudo yum install -y git
    fi
fi

if [ -d "${HOME}/toaster" ]; then
    warning "Already exists toast.sh - [${HOME}/toaster]"

    if [ -f "${HOME}/toaster/toast.sh" ]; then
        ${HOME}/toaster/toast.sh u
    fi

    exit 1
fi

USER=$1
if [ "${USER}" == "" ]; then
    USER="yanolja"
fi

pushd ${HOME}

# git clone
git clone "https://github.com/${USER}/toaster.git"

popd

# done
success "done."
