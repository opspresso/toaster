#!/bin/bash

# curl -sL toast.sh/draft | bash

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

_replace() {
    REPLACE_FILE=$1
    REPLACE_KEY=$2
    DEFAULT_VAL=$3
    REPLACE_TYPE=$4

    if [ "${DEFAULT_VAL}" == "" ]; then
        _read "${REPLACE_KEY} : "
    else
        _read "${REPLACE_KEY} [${DEFAULT_VAL}] : "
    fi

    if [ -z ${ANSWER} ]; then
        REPLACE_VAL=${DEFAULT_VAL}
    else
        REPLACE_VAL=${ANSWER}
    fi

    if [ "${REPLACE_TYPE}" == "yaml" ]; then
        _command "sed -i -e s|${REPLACE_KEY}: .*|${REPLACE_KEY}: ${REPLACE_VAL}| ${REPLACE_FILE}"
        sed -i -e "s|${REPLACE_KEY}: .*|${REPLACE_KEY}: ${REPLACE_VAL}|" ${REPLACE_FILE}
    else
        _command "sed -i -e s|${REPLACE_KEY} = .*|${REPLACE_KEY} = ${REPLACE_VAL}| ${REPLACE_FILE}"
        sed -i -e "s|${REPLACE_KEY} = .*|${REPLACE_KEY} = \"${REPLACE_VAL}\"|" ${REPLACE_FILE}
    fi
}

################################################################################

if [ ! -f Dockerfile ]; then
    _error "File not found. [Dockerfile]"
fi

VERSION=$(curl -s https://api.github.com/repos/nalbam/toaster/releases/latest | grep tag_name | cut -d'"' -f4)

_result "draft package version: ${VERSION}"

if [ -f draft.toml ]; then
    _read "Do you really want to apply? (YES/[no]) : "

    if [ "${ANSWER}" != "YES" ]; then
        exit 0
    fi
fi

mkdir -p charts/acme/templates

DIST=/tmp/draft.tar.gz

_result "draft package downloaded."

# download
curl -sL -o ${DIST} https://github.com/nalbam/toaster/releases/download/${VERSION}/draft.tar.gz

if [ ! -f ${DIST} ]; then
    _error "Can not download. [${REPO}]"
fi

# untar here
tar -zxf ${DIST}

mv -f dockerignore .dockerignore
mv -f draftignore .draftignore

# Jenkinsfile IMAGE_NAME
DEFAULT=$(basename "$PWD")
_replace "Jenkinsfile" "IMAGE_NAME" "${DEFAULT}"

if [ -d .git ]; then
    # Jenkinsfile REPOSITORY_URL
    DEFAULT=$(git remote -v | head -1 | awk '{print $2}')
    _replace "Jenkinsfile" "REPOSITORY_URL" "${DEFAULT}"

    # Jenkinsfile REPOSITORY_SECRET
    DEFAULT=
    _replace "Jenkinsfile" "REPOSITORY_SECRET" "${DEFAULT}"
fi

# values.yaml internalPort
DEFAULT=8080
_replace "charts/acme/values.yaml" "internalPort" "${DEFAULT}" "yaml"

# done
_success "done."
