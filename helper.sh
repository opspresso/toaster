#!/bin/bash

success() {
    echo -e "$(tput setaf 2)$@$(tput sgr0)"
    exit 0
}

error() {
    echo -e "$(tput setaf 1)$@$(tput sgr0)"
    exit 1
}

################################################################################

REPO="repo.toast.sh"

VERSION=$(curl -s https://api.github.com/repos/nalbam/toaster/releases/latest | grep tag_name | cut -d'"' -f4)

################################################################################

mkdir -p ${SHELL_DIR}/conf

# version
curl -sL -o ${SHELL_DIR}/conf/ver.new ${REPO}/toaster.txt

if [ ! -f ${SHELL_DIR}/conf/ver.new ]; then
    error "Can not download. [${REPO}]"
fi

NEW="$(cat ${SHELL_DIR}/conf/ver.new)"

if [ -f ${SHELL_DIR}/conf/ver.now ]; then
    OLD="$(cat ${SHELL_DIR}/conf/ver.now)"

    if [ "${NEW}" == "${OLD}" ]; then
        success "Already have latest version. [${NEW}]"
    fi

    MSG="Latest version updated. [${OLD} -> ${NEW}]"
else
    MSG="Toast.sh installed. [${NEW}]"
fi

DIST=/tmp/toaster.tar.gz

# download
curl -sL -o ${DIST} ${REPO}/dist/toaster.tar.gz

if [ ! -f ${DIST} ]; then
    error "Can not download. [${REPO}]"
fi

# install
tar -zxf ${DIST} -C ${SHELL_DIR}

# cp version
cp -rf ${SHELL_DIR}/conf/ver.new ${SHELL_DIR}/conf/ver.now

# alias
if [ -f ${SHELL_DIR}/helper/alias.sh ]; then
    cp -rf ${SHELL_DIR}/helper/alias.sh ${ALIAS}
    chmod 644 ${ALIAS}
fi

if [ -f ${ALIAS} ]; then
    touch ~/.bashrc
    HAS_ALIAS="$(cat ~/.bashrc | grep bash_aliases | wc -l)"

    if [ "${HAS_ALIAS}" == "0" ]; then
        echo "if [ -f ~/.bash_aliases ]; then" >> ~/.bashrc
        echo "  . ~/.bash_aliases" >> ~/.bashrc
        echo "fi" >> ~/.bashrc
    fi

    . ${ALIAS}
fi

# chmod 755
find ${SHELL_DIR}/** | grep [.]sh | xargs chmod 755

# done
success "${MSG}"
