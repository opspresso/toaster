#!/bin/bash

USERNAME="opspresso"
REPONAME="toaster"

VERSION=${1}

################################################################################

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

_prepare() {
    mkdir -p ~/.aws
    mkdir -p ~/.ssh

    # config
    if [ ! -f ~/.ssh/config ]; then
cat <<EOF > ~/.ssh/config
Host *
    StrictHostKeyChecking no
EOF
    fi
    chmod 400 ~/.ssh/config
}

_version() {
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
}

_download() {
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
}

_alias() {
    TARGET=${HOME}/${1}

    ALIAS="${HOME}/.toast_aliases"

    curl -sL -o ${ALIAS} https://github.com/${USERNAME}/${REPONAME}/releases/download/${VERSION}/alias

    if [ -f ${ALIAS} ]; then
        touch ${TARGET}
        HAS_ALIAS="$(cat ${TARGET} | grep toast_aliases | wc -l | xargs)"

        if [ "x${HAS_ALIAS}" == "x0" ]; then
            echo "if [ -f ~/.toast_aliases ]; then" >> ${TARGET}
            echo "  source ~/.toast_aliases" >> ${TARGET}
            echo "fi" >> ${TARGET}
        fi

        source ${ALIAS}
    fi
}

################################################################################

_prepare

_version

_download

_alias ".bashrc"
_alias ".zshrc"
