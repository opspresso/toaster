#!/bin/bash

# curl -sL toast.sh/draft | bash

ANSWER=

################################################################################

_print() {
    TPUT=
    command -v tput > /dev/null || TPUT=true
    if [ -z ${TPUT} ]; then
        echo -e "$(tput setaf $2)$1$(tput sgr0)"
    else
        echo -e "$1"
    fi
}

_success() {
    _print "+ $@" 2
    exit 0
}

_error() {
    _print "- $@" 1
    exit 1
}

_question() {
    read -p "$(tput setaf 6)$@$(tput sgr0)" ANSWER
}

################################################################################

if [ ! -f Dockerfile ]; then
    _error "File not found. [Dockerfile]"
fi

if [ -f draft.toml ]; then
    _question "Are you sure? (YES/[no]) : "

    if [ "${ANSWER}" != "YES" ]; then
        exit 0
    fi
fi

mkdir -p charts/acme/templates

DIST=/tmp/draft.tar.gz

VERSION=$(curl -s https://api.github.com/repos/nalbam/toaster/releases/latest | grep tag_name | cut -d'"' -f4)

# download
curl -sL -o ${DIST} https://github.com/nalbam/toaster/releases/download/${VERSION}/draft.tar.gz

if [ ! -f ${DIST} ]; then
    error "Can not download. [${REPO}]"
fi

# untar
tar -zxf ${DIST}

mv -f dockerignore .dockerignore
mv -f draftignore .draftignore

_success "done."
