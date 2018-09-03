#!/bin/bash

# curl -sL toast.sh/install | bash

OS_NAME="$(uname | awk '{print tolower($0)}')"

THIS_VERSION=v0.0.0

CMD=$1
SUB=$2

NAME=
BRANCH=master
VERSION=0.0.0
NAMESPACE=
CLUSTER=

BASE_DOMAIN=
JENKINS=
REGISTRY=
CHARTMUSEUM=
SONARQUBE=
NEXUS=

CONFIG=${HOME}/.toaster

touch ${CONFIG} && . ${CONFIG}

for v in "$@"; do
    case ${v} in
    --name=*)
        NAME="${v#*=}"
        shift
        ;;
    --branch=*)
        BRANCH="${v#*=}"
        shift
        ;;
    --version=*)
        VERSION="${v#*=}"
        shift
        ;;
    --namespace=*)
        NAMESPACE="${v#*=}"
        shift
        ;;
    --cluster=*)
        CLUSTER="${v#*=}"
        shift
        ;;
    *)
        shift
        ;;
    esac
done

################################################################################

command -v tput > /dev/null || TPUT=false

_bar() {
    _echo "================================================================================"
}

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

_logo() {
    #figlet toaster
    _bar
    _echo " | |_ ___   __ _ ___| |_ ___ _ __  "
    _echo " | __/ _ \ / _' / __| __/ _ \ '__| "
    _echo " | || (_) | (_| \__ \ ||  __/ | "
    _echo "  \__\___/ \__,_|___/\__\___|_|  ${THIS_VERSION}"
    _bar
}

_usage() {
    _logo
    _echo " Usage: $0 {update|bastion|scan|build|helm|draft} "
    _bar
    _error
}

_replace() {
    if [ "${OS_NAME}" == "darwin" ]; then
        sed -i "" -e "$1" $2
    else
        sed -i -e "$1" $2
    fi
}

################################################################################

_toast() {
    case ${CMD} in
        u|update)
            _update
            ;;
        t|bastion)
            _bastion
            ;;
        h|helper)
            _helper
            ;;
        d|draft)
            _draft
            ;;
        *)
            _usage
    esac
}

_update() {
    VERSION=$(curl -s https://api.github.com/repos/nalbam/toaster/releases/latest | grep tag_name | cut -d'"' -f4)

    if [ "${VERSION}" == "${THIS_VERSION}" ]; then
        _success "Latest version already installed. [${THIS_VERSION}]"
    fi

    curl -sL toast.sh/install | bash
    exit 0
}

_bastion() {
    curl -sL toast.sh/helper/bastion.sh | bash
    exit 0
}

_version() {
    _echo ${THIS_VERSION} 2
    exit 0
}

_helper() {
    _result "helper package version: ${THIS_VERSION}"

    DIST=/tmp/helper.tar.gz
    rm -rf ${DIST}

    # download
    curl -sL -o ${DIST} https://github.com/nalbam/toaster/releases/download/${THIS_VERSION}/helper.tar.gz

    if [ ! -f ${DIST} ]; then
        _error "Can not download."
    fi

    _result "helper package downloaded."

    HELPER_DIR="${HOME}/helper"
    mkdir -p ${HELPER_DIR}

    BASH_ALIAS="${HOME}/.bash_aliases"

    # install
    tar -zxf ${DIST} -C ${HELPER_DIR}

    # alias
    if [ -f ${HELPER_DIR}/alias.sh ]; then
        cp -rf ${HELPER_DIR}/alias.sh ${BASH_ALIAS}
        chmod 644 ${BASH_ALIAS}
    fi

    if [ -f ${BASH_ALIAS} ]; then
        touch ~/.bashrc
        HAS_ALIAS="$(cat ${HOME}/.bashrc | grep bash_aliases | wc -l | xargs)"

        if [ "x${HAS_ALIAS}" == "x0" ]; then
            echo "if [ -f ~/.bash_aliases ]; then" >> ${HOME}/.bashrc
            echo "  . ~/.bash_aliases" >> ${HOME}/.bashrc
            echo "fi" >> ${HOME}/.bashrc
        fi

        . ${BASH_ALIAS}
    fi

    # chmod 755
    find ${HELPER_DIR}/** | grep [.]sh | xargs chmod 755
}

_draft() {
    case ${SUB} in
        init)
            _draft_init
            ;;
        pack)
            _draft_pack
            ;;
        up)
            _draft_up
            ;;
        *)
            _draft_init
    esac
}

_draft_init() {
    _command "draft version"
    draft version

    _command "draft init"
    draft init

    if [ ! -z ${REGISTRY} ]; then
        _command "draft config set registry ${REGISTRY}"
        draft config set registry ${REGISTRY}
    fi
}

_draft_pack() {
    if [ ! -f Dockerfile ]; then
        _error "File not found. [Dockerfile]"
    fi

    if [ -f draft.toml ]; then
        _read "Do you really want to apply? (YES/[no]) : "

        if [ "${ANSWER}" != "YES" ]; then
            exit 0
        fi
    fi

    _result "draft package version: ${THIS_VERSION}"

    mkdir -p charts/acme/templates

    DIST=/tmp/draft.tar.gz
    rm -rf ${DIST}

    # download
    curl -sL -o ${DIST} https://github.com/nalbam/toaster/releases/download/${THIS_VERSION}/draft.tar.gz

    if [ ! -f ${DIST} ]; then
        _error "Can not download."
    fi

    _result "draft package downloaded."

    # untar here
    tar -zxf ${DIST}

    mv -f dockerignore .dockerignore
    mv -f draftignore .draftignore

    # Jenkinsfile IMAGE_NAME
    DEFAULT=$(basename "$PWD")
    _chart_replace "Jenkinsfile" "IMAGE_NAME" "${DEFAULT}"

    if [ -d .git ]; then
        # Jenkinsfile REPOSITORY_URL
        DEFAULT=$(git remote -v | head -1 | awk '{print $2}')
        _chart_replace "Jenkinsfile" "REPOSITORY_URL" "${DEFAULT}"

        # Jenkinsfile REPOSITORY_SECRET
        DEFAULT=
        _chart_replace "Jenkinsfile" "REPOSITORY_SECRET" "${DEFAULT}"
    fi

    # values.yaml internalPort
    DEFAULT=8080
    _chart_replace "charts/acme/values.yaml" "internalPort" "${DEFAULT}" "yaml"
}

_draft_up() {
    _draft_init

    if [ ! -f draft.toml ]; then
        _error "Not found draft.toml"
    fi

    if [ -z ${NAME} ]; then
        _error "NAME is empty."
    fi
    if [ -z ${NAMESPACE} ]; then
        _error "NAMESPACE is empty."
    fi

    _command "sed -i -e s/NAMESPACE/${NAMESPACE}/g draft.toml"
    _replace "s/NAMESPACE/${NAMESPACE}/g" draft.toml

    _command "sed -i -e s/NAME/${NAME}-${NAMESPACE}/g draft.toml"
    _replace "s/NAME/${NAME}-${NAMESPACE}/g" draft.toml

    _command "draft up -e ${NAMESPACE}"
	draft up -e ${NAMESPACE}
}

_chart_replace() {
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
        _replace "s|${REPLACE_KEY}: .*|${REPLACE_KEY}: ${REPLACE_VAL}|" ${REPLACE_FILE}
    else
        _command "sed -i -e s|${REPLACE_KEY} = .*|${REPLACE_KEY} = ${REPLACE_VAL}| ${REPLACE_FILE}"
        _replace "s|${REPLACE_KEY} = .*|${REPLACE_KEY} = \"${REPLACE_VAL}\"|" ${REPLACE_FILE}
    fi
}

_toast

_success "done."
