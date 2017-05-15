#!/bin/bash

success() {
    echo -e "$(tput setaf 2)$1$(tput sgr0)"
}

inform() {
    echo -e "$(tput setaf 6)$1$(tput sgr0)"
}

warning() {
    echo -e "$(tput setaf 1)$1$(tput sgr0)"
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
    if [ `echo ${OS_FULL} | grep -c "amzn1"` -gt 0 ]; then
        OS_TYPE="amzn1"
    elif [ `echo ${OS_FULL} | grep -c "el6"` -gt 0 ]; then
        OS_TYPE="el6"
    elif [ `echo ${OS_FULL} | grep -c "el7"` -gt 0 ]; then
        OS_TYPE="el7"
    elif [ `echo ${OS_FULL} | grep -c "generic"` -gt 0 ]; then
        OS_TYPE="generic"
    fi
else
    if [ "${OS_NAME}" == "Darwin" ]; then
        OS_TYPE="${OS_NAME}"
    fi
fi

if [ "${OS_TYPE}" == "" ]; then
    uname -a
    warning "Not supported OS - [${OS_NAME}][${OS_TYPE}]"
    exit 1
fi

# sudo
SUDO="sudo"

REPO="http://repo.toast.sh"

################################################################################

pushd ${HOME}

# version
wget -q -N -P /tmp ${REPO}/release/toaster.txt

if [ ! -f /tmp/toaster.txt ]; then
    warning "Can not download. [version]"
    exit 1
fi

MSG="Toast.sh installed."

if [ -f toaster/.version.txt ]; then
    NEW="`cat /tmp/toaster.txt`"
    OLD="`cat toaster/.version.txt`"

    if [ "${NEW}" == "${OLD}" ]; then
        success "Already have latest version. [${OLD}]"
        exit 0
    fi

    MSG="Latest version updated. [${OLD}]"
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
