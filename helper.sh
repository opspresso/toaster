#!/bin/bash

# curl -sL toast.sh/helper | bash

OS_NAME="$(uname | awk '{print tolower($0)}')"

ANSWER=

################################################################################

TPUT=
command -v tput > /dev/null || TPUT=false

_echo() {
    if [ -z ${TPUT} ] && [ ! -z $2 ]; then
        echo -e "$(tput setaf $2)$1$(tput sgr0)"
    else
        echo -e "$1"
    fi
}

_read() {
    if [ -z ${TPUT} ]; then
        read -p "$(tput setaf 6)$1$(tput sgr0)" ANSWER
    else
        read -p "$1" ANSWER
    fi
}

_result() {
    _echo "# $@" 4
}

_command() {
    _echo "$ $@" 3
}

_success() {
    _echo "+ $@" 2
    exit 0
}

_error() {
    _echo "- $@" 1
    exit 1
}

################################################################################

VERSION=$(curl -s https://api.github.com/repos/nalbam/toaster/releases/latest | grep tag_name | cut -d'"' -f4)

_result "helper package version: ${VERSION}"

_read "Do you really want to apply? (YES/[no]) : "

if [ "${ANSWER}" != "YES" ]; then
    exit 0
fi

DIST=/tmp/helper.tar.gz

# download
curl -sL -o ${DIST} https://github.com/nalbam/toaster/releases/download/${VERSION}/helper.tar.gz

if [ ! -f ${DIST} ]; then
    _error "Can not download. [${REPO}]"
fi

_result "helper package downloaded."

SHELL_DIR="${HOME}/helper"
ALIAS="${HOME}/.bash_aliases"

mkdir -p ${SHELL_DIR}/conf

# install
tar -zxf ${DIST} -C ${SHELL_DIR}

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
_success "done."
