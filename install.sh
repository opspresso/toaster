#!/bin/bash

command -v tput > /dev/null && TPUT=true

_echo() {
    if [ "${TPUT}" != "" ] && [ "$2" != "" ]; then
        echo -e "$(tput setaf $2)$1$(tput sgr0)"
    else
        echo -e "$1"
    fi
}

_result() {
    _echo "# $@" 4
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

USERNAME="nalbam"
REPONAME="toaster"

VERSION=${1}

if [ -z ${VERSION} ]; then
    VERSION=$(curl -s https://api.github.com/repos/${USERNAME}/${REPONAME}/releases/latest | grep tag_name | cut -d'"' -f4)

    if [ -z ${VERSION} ]; then
        VERSION=$(curl -sL toast.sh/VERSION | xargs)
    fi
fi

_result "version: ${VERSION}"

if [ -z ${VERSION} ]; then
    _error
fi

# toaster
DIST=/tmp/toaster-${VERSION}
rm -rf ${DIST}

# download
curl -sL -o ${DIST} https://github.com/${USERNAME}/${REPONAME}/releases/download/${VERSION}/toaster
chmod +x ${DIST}

# copy
COPY_PATH=/usr/local/bin
if [ ! -z $HOME ]; then
    COUNT=$(echo "$PATH" | grep "$HOME/.local/bin" | wc -l | xargs)
    if [ "x${COUNT}" != "x0" ]; then
        COPY_PATH=$HOME/.local/bin
    else
        COUNT=$(echo "$PATH" | grep "$HOME/bin" | wc -l | xargs)
        if [ "x${COUNT}" != "x0" ]; then
            COPY_PATH=$HOME/bin
        fi
    fi
fi

mkdir -p ${COPY_PATH}
mv -f ${DIST} ${COPY_PATH}/toaster

# alias
ALIAS="${HOME}/.bash_aliases"

curl -sL -o ${ALIAS} https://github.com/${USERNAME}/${REPONAME}/releases/download/${VERSION}/alias

if [ -f ${ALIAS} ]; then
    touch ~/.bashrc
    HAS_ALIAS="$(cat ${HOME}/.bashrc | grep bash_aliases | wc -l | xargs)"

    if [ "x${HAS_ALIAS}" == "x0" ]; then
        echo "if [ -f ~/.bash_aliases ]; then" >> ${HOME}/.bashrc
        echo "  . ~/.bash_aliases" >> ${HOME}/.bashrc
        echo "fi" >> ${HOME}/.bashrc
    fi

    . ${ALIAS}
fi

# done
_success "done."
