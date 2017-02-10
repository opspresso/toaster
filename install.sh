#!/bin/bash

success() {
    echo "$(tput setaf 2)$1$(tput sgr0)"
}

warning() {
    echo "$(tput setaf 1)$1$(tput sgr0)"
}

################################################################################

# root
if [ "${HOME}" == "/root" ]; then
    warning "Not supported ROOT."
    exit 1
fi

# linux
OS_NAME=`uname`
if [ "${OS_NAME}" == "Linux" ]; then
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
else
    if [ "${OS_NAME}" == "Darwin" ]; then
        OS_TYPE="${OS_NAME}"
    else
        warning "Not supported OS - ${OS_NAME}"
        exit 1
    fi
fi

# sudo
SUDO="sudo"

################################################################################

pushd ${HOME}

REPO="http://repo.toast.sh"

# version
wget -q -N -P /tmp ${REPO}/release/toaster.txt

if [ ! -f /tmp/toaster.txt ]; then
    warning "Can not download. [version]"
    exit 1
fi

MSG="installed."

if [ -f toaster/.version.txt ]; then
    NEW="`cat /tmp/toaster.txt`"
    OLD="`cat toaster/.version.txt`"

    if [ "${NEW}" == "${OLD}" ]; then
        success "latest. [${OLD}]"
        exit 0
    fi

    MSG="updated."
fi

# download
wget -q -N -P /tmp ${REPO}/release/toaster.zip

if [ ! -f /tmp/toaster.zip ]; then
    warning "Can not download. [toast.sh]"
    exit 1
fi

# unzip
unzip -q -o /tmp/toaster.zip -d toaster

# cp version
cp -rf /tmp/toaster.txt toaster/.version.txt

popd

# done
success "${MSG}"
