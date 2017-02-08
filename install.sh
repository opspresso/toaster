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

# git
if [ "${OS_NAME}" == "Linux" ]; then
    if [ "${OS_TYPE}" == "Ubuntu" ]; then
        ${SUDO} apt-get install -y git wget zip
    else
        ${SUDO} yum install -y git wget zip
    fi
fi

pushd ${HOME}

# download
wget -q -N -P /tmp http://repo.toast.sh/release/toaster.txt
wget -q -N -P /tmp http://repo.toast.sh/release/toaster.zip

# unzip
unzip -q -o /tmp/toaster.zip -d toaster

# cp version
cp -rf /tmp/toaster.txt toaster/.version.txt

# user
#USER=$1
#if [ "${USER}" == "" ]; then
#    USER="yanolja"
#fi

# git clone
#git clone "https://github.com/${USER}/toaster.git"

popd

# done
success "done."
