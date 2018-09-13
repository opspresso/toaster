#!/bin/bash

# curl -sL toast.sh/install | bash

OS_NAME="$(uname | awk '{print tolower($0)}')"

THIS_VERSION=v0.0.0

CMD=$1
SUB=$2

NAME=
VERSION=0.0.0
SECRET=

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
    --this=*)
        THIS_VERSION="${v#*=}"
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
    _echo "  _                  _             "
    _echo " | |_ ___   __ _ ___| |_ ___ _ __  "
    _echo " | __/ _ \ / _' / __| __/ _ \ '__| "
    _echo " | || (_) | (_| \__ \ ||  __/ |    "
    _echo "  \__\___/ \__,_|___/\__\___|_|    ${THIS_VERSION}"
    _bar
}

_usage() {
    _logo
    _echo " Usage: $0 {update|bastion|helper|draft|version} "
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
        b|bastion)
            _bastion
            ;;
        h|helper)
            _helper
            ;;
        d|draft)
            _draft
            ;;
        v|version)
            _version
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

_config_save() {
    echo "# toaster config" > ${CONFIG}
    echo "SECRET=${SECRET}" >> ${CONFIG}
    echo "NAMESPACE=${NAMESPACE}" >> ${CONFIG}
    echo "CLUSTER=${CLUSTER}" >> ${CONFIG}
    echo "BASE_DOMAIN=${BASE_DOMAIN}" >> ${CONFIG}
    echo "JENKINS=${JENKINS}" >> ${CONFIG}
    echo "REGISTRY=${REGISTRY}" >> ${CONFIG}
    echo "CHARTMUSEUM=${CHARTMUSEUM}" >> ${CONFIG}
    echo "SONARQUBE=${SONARQUBE}" >> ${CONFIG}
    echo "NEXUS=${NEXUS}" >> ${CONFIG}
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
    _result "draft package version: ${THIS_VERSION}"

    echo
    _read "Do you really want to apply? (YES/[no]) : "
    echo

    if [ "${ANSWER}" != "YES" ]; then
        exit 0
    fi

    DIST=/tmp/toaster-draft-${THIS_VERSION}
    LIST=/tmp/toaster-draft-ls

    if [ ! -d ${DIST} ]; then
        mkdir -p ${DIST}

        # download
        pushd ${DIST}
        curl -sL https://github.com/nalbam/toaster/releases/download/${THIS_VERSION}/draft.tar.gz | tar xz
        popd

        echo
        _result "draft package downloaded."
        echo
    fi

    # find all
    ls ${DIST} > ${LIST}

    IDX=0
    while read VAL; do
        IDX=$(( ${IDX} + 1 ))
        printf "%3s %s\n" "$IDX" "$VAL";
    done < ${LIST}

    echo
    _read "Please select a project type. (1-5) : "
    echo

    SELECTED=
    if [ -z ${ANSWER} ]; then
        _error
    fi
    TEST='^[0-9]+$'
    if ! [[ ${ANSWER} =~ ${TEST} ]]; then
        _error
    fi
    SELECTED=$(sed -n ${ANSWER}p ${LIST})

    _result "${SELECTED}"

    mkdir -p charts/acme/templates

    # copy
    cp -rf ${DIST}/${SELECTED}/charts/* charts/
    cp -rf ${DIST}/${SELECTED}/dockerignore .dockerignore
    cp -rf ${DIST}/${SELECTED}/draftignore .draftignore
    cp -rf ${DIST}/${SELECTED}/Dockerfile Dockerfile
    cp -rf ${DIST}/${SELECTED}/Jenkinsfile Jenkinsfile
    cp -rf ${DIST}/${SELECTED}/draft.toml draft.toml

    # Jenkinsfile IMAGE_NAME
    DEFAULT=$(basename $(pwd))
    _chart_replace "Jenkinsfile" "def IMAGE_NAME" "${DEFAULT}"

    # Jenkinsfile REPOSITORY_URL
    DEFAULT=
    if [ -d .git ]; then
        DEFAULT=$(git remote -v | head -1 | awk '{print $2}')
    fi
    _chart_replace "Jenkinsfile" "def REPOSITORY_URL" "${DEFAULT}"

    # Jenkinsfile REPOSITORY_SECRET
    _chart_replace "Jenkinsfile" "def REPOSITORY_SECRET" "${SECRET}"
    SECRET="${REPLACE_VAL}"

    # Jenkinsfile CLUSTER
    _chart_replace "Jenkinsfile" "def CLUSTER" "${CLUSTER}"
    CLUSTER="${REPLACE_VAL}"

    # Jenkinsfile BASE_DOMAIN
    _chart_replace "Jenkinsfile" "def BASE_DOMAIN" "${BASE_DOMAIN}"
    BASE_DOMAIN="${REPLACE_VAL}"

    _config_save
    echo
}

_draft_up() {
    _draft_init

    if [ ! -f draft.toml ]; then
        _error "Not found draft.toml"
    fi

    # draft.toml NAMESPACE
    DEFAULT="local"
    _draft_replace "draft.toml" "NAMESPACE" "${DEFAULT}"
    NAMESPACE="${REPLACE_VAL}"

    # draft.toml NAME
    DEFAULT="$(basename $(pwd))-${NAMESPACE}"
    _draft_replace "draft.toml" "NAME" "${DEFAULT}"

    _command "draft up -e ${NAMESPACE}"
	draft up -e ${NAMESPACE}
}

_draft_replace() {
    REPLACE_FILE=$1
    REPLACE_KEY=$2
    DEFAULT_VAL=$3

    echo

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

    _command "sed -i -e s|${REPLACE_KEY}|${REPLACE_VAL}| ${REPLACE_FILE}"
    _replace "s|${REPLACE_KEY}|${REPLACE_VAL}|" ${REPLACE_FILE}
}

_chart_replace() {
    REPLACE_FILE=$1
    REPLACE_KEY=$2
    DEFAULT_VAL=$3
    REPLACE_TYPE=$4

    echo

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
