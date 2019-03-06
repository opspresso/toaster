#!/bin/bash

# curl -sL toast.sh/install | bash

OS_NAME="$(uname | awk '{print tolower($0)}')"

THIS_VERSION=v0.0.0

CMD=$1
PARAM1=$2
PARAM2=$3
PARAM3=$4

CONFIG_DIR="${HOME}/.toaster"

CONFIG="${CONFIG_DIR}/$(basename $0)"

SRC_DIR=
ENV_DIR=
PEM_DIR=

LIST=/tmp/toaster-temp-list
TEMP=/tmp/toaster-temp-result

################################################################################

command -v fzf > /dev/null && FZF=true
command -v tput > /dev/null && TPUT=true

_bar() {
    _echo "================================================================================"
}

_echo() {
    if [ "${TPUT}" != "" ] && [ "$2" != "" ]; then
        echo -e "$(tput setaf $2)$1$(tput sgr0)"
    else
        echo -e "$1"
    fi
}

_read() {
    echo
    if [ "${TPUT}" != "" ]; then
        read -p "$(tput setaf 6)$1$(tput sgr0)" ANSWER
    else
        read -p "$1" ANSWER
    fi
}

_result() {
    echo
    _echo "# $@" 4
}

_command() {
    echo
    _echo "$ $@" 3
}

_success() {
    echo
    _echo "+ $@" 2
    echo
    exit 0
}

_error() {
    echo
    _echo "- $@" 1
    echo
    exit 1
}

_select_one() {
    OPT=$1

    SELECTED=

    CNT=$(cat ${LIST} | wc -l | xargs)
    if [ "x${CNT}" == "x0" ]; then
        return
    fi

    if [ "${OPT}" != "" ] && [ "x${CNT}" == "x1" ]; then
        SELECTED="$(cat ${LIST} | xargs)"
    else
        if [ "${FZF}" != "" ]; then
            SELECTED=$(cat ${LIST} | fzf --reverse --no-mouse --height=10 --bind=left:page-up,right:page-down)
        else
            echo

            IDX=0
            while read VAL; do
                IDX=$(( ${IDX} + 1 ))
                printf "%3s. %s\n" "${IDX}" "${VAL}"
            done < ${LIST}

            if [ "${CNT}" != "1" ]; then
                CNT="1-${CNT}"
            fi

            _read "Please select one. (${CNT}) : "

            if [ -z ${ANSWER} ]; then
                return
            fi
            TEST='^[0-9]+$'
            if ! [[ ${ANSWER} =~ ${TEST} ]]; then
                return
            fi
            SELECTED=$(sed -n ${ANSWER}p ${LIST})
        fi
    fi
}

################################################################################

_logo() {
    #figlet toaster
    _bar
    _echo "  _                  _             "
    _echo " | |_ ___   __ _ ___| |_ ___ _ __  "
    _echo " | __/ _ \ / _' / __| __/ _ \ '__| "
    _echo " | || (_) | (_| \__ \ ||  __/ |    "
    _echo "  \__\___/ \__,_|___/\__\___|_|    ${THIS_VERSION} "
    _bar
}

_usage() {
    _logo
    _echo " Usage: `basename $0` {update|helper|tools|version} "
    _bar
    _error
}

_prepare() {
    mkdir -p ${CONFIG_DIR}

    touch ${CONFIG} && . ${CONFIG}

    rm -rf ${LIST} ${TEMP}
}

_src_dir() {
    _prepare

    if [ -z ${SRC_DIR} ] || [ ! -d ${SRC_DIR} ]; then
        DEFAULT="${HOME}/work/src"

        _read "Please input source directory. [${DEFAULT}]: "
        SRC_DIR=${ANSWER:-${DEFAULT}}
    fi

    mkdir -p ${SRC_DIR}/github.com

    if [ ! -d ${SRC_DIR} ]; then
        _error "[${SRC_DIR}] is not directory."
    fi
}

_env_dir() {
    _src_dir

    if [ -z ${ENV_DIR} ] || [ ! -d ${ENV_DIR} ]; then
        DEFAULT="${SRC_DIR}/github.com/${USER}/keys/env"

        _read "Please input env directory. [${DEFAULT}]: "
        ENV_DIR=${ANSWER:-${DEFAULT}}
    fi

    if [ ! -d ${ENV_DIR} ]; then
        _error "[${ENV_DIR}] is not directory."
    fi
}

_pem_dir() {
    _src_dir

    if [ -z ${PEM_DIR} ] || [ ! -d ${PEM_DIR} ]; then
        DEFAULT="${SRC_DIR}/github.com/${USER}/keys/pem"

        _read "Please input pem directory. [${DEFAULT}]: "
        PEM_DIR=${ANSWER:-${DEFAULT}}
    fi

    if [ ! -d ${PEM_DIR} ]; then
        _error "[${PEM_DIR}] is not directory."
    fi
}

_save_conf() {
    echo "# toaster conf" > ${CONFIG}
    echo "SRC_DIR=${SRC_DIR}" >> ${CONFIG}
    echo "ENV_DIR=${ENV_DIR}" >> ${CONFIG}
    echo "PEM_DIR=${PEM_DIR}" >> ${CONFIG}
}

_cdw() {
    _src_dir

    find ${SRC_DIR} -maxdepth 2 -type d -exec ls -d "{}" \; > ${LIST}

    _select_one

    if [ -z ${SELECTED} ] || [ ! -d ${SELECTED} ]; then
        _error
    fi

    printf "${SELECTED}" > ${TEMP}

    _command "cd ${SELECTED}"
}

_git() {
    _src_dir

}

_code() {
    _src_dir

    find ${SRC_DIR} -maxdepth 2 -type d -exec ls -d "{}" \; > ${LIST}

    _select_one

    if [ -z ${SELECTED} ] || [ ! -d ${SELECTED} ]; then
        _error
    fi

    printf "${SELECTED}" > ${TEMP}

    _result "${SELECTED}"

    if [ "${OS_NAME}" == "linux" ]; then
        /usr/bin/code ${SELECTED}
    elif [ "${OS_NAME}" == "darwin" ]; then
        /Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin/code ${SELECTED}
    elif [ "${OS_NAME}" == "mingw64_nt-10.0" ]; then
        /c/Users/${USER:-$(whoami)}/AppData/Local/Programs/Microsoft\ VS\ Code/Code.exe ${SELECTED}
    else
        _error
    fi
}

_env() {
    _env_dir

    _NAME=${PARAM1}
    _REGION=${PARAM2:-ap-northeast-2}
    _OUTPUT=${PARAM3:-json}

    if [ -z ${_NAME} ]; then
        ls ${ENV_DIR} > ${LIST}

        _select_one

        _NAME="${SELECTED}"
    fi

    if [ -z ${_NAME} ]; then
        _error
    fi
    if [ ! -f "${ENV_DIR}/${_NAME}" ]; then
        _error
    fi

    command -v aws > /dev/null || AWSCLI=false

    if [ ! -z ${AWSCLI} ]; then
        _error "Please install awscli."
    fi

    mkdir -p ~/.aws

    aws configure set default.region ${_REGION}
    aws configure set default.output ${_OUTPUT}

    cp -f ${ENV_DIR}/${_NAME} ~/.aws/credentials

    _result "${_NAME}  ${_REGION}  ${_OUTPUT}"
}

_ssh() {
    _pem_dir

    _PEM=${PARAM1}
    _HOST=${PARAM2}
    _USER=${PARAM3}

    HISTORY="${CONFIG_DIR}/ssh-history"

    # history
    if [ -z ${_USER} ]; then
        if [ -f ${HISTORY} ]; then
            _result "${HISTORY}"

            cat ${HISTORY} > ${LIST}

            _select_one

            if [ "${SELECTED}" != "" ]; then
                ARR=(${SELECTED})

                _PEM=${ARR[0]}
                _HOST=${ARR[1]}
                _USER=${ARR[2]}

                FROM_HISTORY=true
            fi
        fi
    fi

    # pem
    if [ -z ${_PEM} ]; then
        ls ${PEM_DIR} > ${LIST}

        _select_one

        if [ -z ${SELECTED} ] || [ ! -f ${PEM_DIR}/${SELECTED} ]; then
            _error
        fi

        _PEM="${SELECTED}"
    fi
    if [ -z ${_PEM} ]; then
        _error
    fi

    # host
    if [ -z ${_HOST} ]; then
        _read "Please input ssh host. []: "

        _HOST="${ANSWER}"
    fi
    if [ -z ${_HOST} ]; then
        _error
    fi

    # user
    if [ -z ${_USER} ]; then
        _read "Please input ssh user. [ec2-user]: "

        _USER="${ANSWER:-ec2-user}"
    fi
    if [ -z ${_USER} ]; then
        _error
    fi

    if [ ! -f ${PEM_DIR}/${_PEM} ]; then
        if [ -f ${PEM_DIR}/${_PEM}.pem ]; then
            _PEM="${_PEM}.pem"
        else
            _error
        fi
    fi

    if [ -z ${FROM_HISTORY} ]; then
        COUNT=$(cat ${HISTORY} | grep "${_PEM} ${_HOST} ${_USER}" | wc -l | xargs)

        if [ "x${COUNT}" == "x0" ]; then
            echo "${_PEM} ${_HOST} ${_USER}" >> ${HISTORY}
        fi
    fi

    _command "ssh -i ${PEM_DIR}/${_PEM} ${_USER}@${_HOST}"
    ssh -i ${PEM_DIR}/${_PEM} ${_USER}@${_HOST}
}

_ctx() {
    _NAME=${PARAM1}

    if [ -z ${_NAME} ]; then
        echo "$(kubectl config view -o json | jq '.contexts[].name' -r)" > ${LIST}

        _select_one

        _NAME="${SELECTED}"
    fi

    if [ -z ${_NAME} ]; then
        _error
    fi

    kubectl config use-context ${_NAME}
}

_update() {
    _echo "# version: ${THIS_VERSION}" 3
    curl -sL toast.sh/install | bash -s ${SUB}
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

    HELPER_DIR="${HOME}/.helper"
    mkdir -p ${HELPER_DIR}

    if [ -d ${HOME}/helper ]; then
        mv ${HOME}/helper ${HELPER_DIR}
    fi

    # install
    tar -zxf ${DIST} -C ${HELPER_DIR}

    BASH_ALIAS="${HOME}/.bash_aliases"

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

_tools() {
    curl -sL toast.sh/tools | bash
    exit 0
}

_toast() {
    _prepare

    case ${CMD} in
        c|cdw)
            _cdw
            ;;
        e|env)
            _env
            ;;
        g|git)
            _git
            ;;
        s|ssh)
            _ssh
            ;;
        x|ctx)
            _ctx
            ;;
        v|code)
            _code
            ;;
        u|update)
            _update
            ;;
        h|helper)
            _helper
            ;;
        t|tools)
            _tools
            ;;
        *)
            _usage
    esac

    _save_conf
}

_toast

_success "done."
