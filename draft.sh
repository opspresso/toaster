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

_result() {
    _print "# $@" 4
}

_command() {
    _print "$ $@" 3
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

_command "download ${VERSION}"

# download
curl -sL -o ${DIST} https://github.com/nalbam/toaster/releases/download/${VERSION}/draft.tar.gz

if [ ! -f ${DIST} ]; then
    _error "Can not download. [${REPO}]"
fi

# untar
tar -zxf ${DIST}

mv -f dockerignore .dockerignore
mv -f draftignore .draftignore

# IMAGE_NAME
DEFAULT=$(basename "$PWD")
_question "IMAGE_NAME [${DEFAULT}] : "

if [ -z ${ANSWER} ]; then
    IMAGE_NAME=${DEFAULT}
else
    IMAGE_NAME=${ANSWER}
fi

_command "sed -i -e s|IMAGE_NAME = .*|IMAGE_NAME = ${IMAGE_NAME}| Jenkinsfile"
sed -i -e "s|IMAGE_NAME = .*|IMAGE_NAME = \"${IMAGE_NAME}\"|" Jenkinsfile

# REPOSITORY_URL
if [ -d .git ]; then
    DEFAULT=$(git remote -v | head -1 | awk '{print $2}')
    _question "REPOSITORY_URL [${DEFAULT}] : "

    if [ -z ${ANSWER} ]; then
        REPOSITORY_URL=${DEFAULT}
    else
        REPOSITORY_URL=${ANSWER}
    fi

    _command "sed -i -e s|REPOSITORY_URL = .*|REPOSITORY_URL = ${REPOSITORY_URL}| Jenkinsfile"
    sed -i -e "s|REPOSITORY_URL = .*|REPOSITORY_URL = \"${REPOSITORY_URL}\"|" Jenkinsfile
fi

# internalPort
DEFAULT=80
_question "internalPort [${DEFAULT}] : "

if [ -z ${ANSWER} ]; then
    internalPort=${DEFAULT}
else
    internalPort=${ANSWER}
fi

_command "sed -i -e s|internalPort: .*|internalPort: $internalPort| charts/acme/values.yaml"
sed -i -e "s|internalPort: .*|internalPort: $internalPort|" charts/acme/values.yaml

# done
_success "done."
