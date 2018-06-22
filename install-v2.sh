#!/bin/bash

success() {
    echo -e "$1"
    exit 0
}

error() {
    echo -e "$1"
    exit 1
}

################################################################################

REPO="https://repo.toast.sh"

CONFIG="${HOME}/.toast"
if [ -f "${CONFIG}" ]; then
    source "${CONFIG}"
fi

SHELL_DIR="${HOME}/toaster"
ALIAS="${HOME}/.bash_aliases"

################################################################################

mkdir -p ${SHELL_DIR}/.version

# version
curl -sL -o ${SHELL_DIR}/.version/.toaster.new ${REPO}/toaster-v2.txt

if [ ! -f ${SHELL_DIR}/.version/.toaster.new ]; then
    error "Can not download. [${REPO}]"
fi

NEW="$(cat ${SHELL_DIR}/.version/.toaster.new)"

if [ -f ${SHELL_DIR}/.version/.toaster.old ]; then
    OLD="$(cat ${SHELL_DIR}/.version/.toaster.old)"

    if [ "${NEW}" == "${OLD}" ]; then
        success "Already have latest version. [${NEW}]"
    fi

    MSG="Latest version updated. [${OLD} -> ${NEW}]"
else
    MSG="Toast.sh installed. [${NEW}]"
fi

# download
curl -sL -o /tmp/toaster.tar.gz ${REPO}/toaster-v2.tar.gz

if [ ! -f /tmp/toaster.tar.gz ]; then
    error "Can not download. [${REPO}]"
fi

# install
tar -zxf /tmp/toaster.tar.gz -C ${SHELL_DIR}

# cp version
cp -rf ${SHELL_DIR}/.version/.toaster.new ${SHELL_DIR}/.version/.toaster.old

# alias
if [ -f ${SHELL_DIR}/helper/alias.sh ]; then
    cp -rf ${SHELL_DIR}/helper/alias.sh ${ALIAS}
    chmod 644 ${ALIAS}
fi

if [ -f ${ALIAS} ]; then
    . ${ALIAS}
fi

# chmod 755
find ${SHELL_DIR}/** | grep [.]sh | xargs chmod 755

# done
success "${MSG}"
