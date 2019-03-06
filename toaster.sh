#!/bin/bash

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

_echo() {
    if [ "${TPUT}" != "" ] && [ "$2" != "" ]; then
        echo -e "$(tput setaf $2)$1$(tput sgr0)"
    else
        echo -e "$1"
    fi
}

_read() {
    echo
    if [ "${2}" == "" ]; then
        if [ "${TPUT}" != "" ]; then
            read -p "$(tput setaf 6)$1$(tput sgr0)" ANSWER
        else
            read -p "$1" ANSWER
        fi
    else
        if [ "${TPUT}" != "" ]; then
            read -s -p "$(tput setaf 6)$1$(tput sgr0)" ANSWER
        else
            read -s -p "$1" ANSWER
        fi
        echo
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
    exit 0
}

_error() {
    echo
    _echo "- $@" 1
    exit 1
}

_replace() {
    if [ "${OS_NAME}" == "darwin" ]; then
        sed -i "" -e "$1" $2
    else
        sed -i -e "$1" $2
    fi
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

_usage() {
    #figlet toaster
cat <<EOF
================================================================================
  _                  _
 | |_ ___   __ _ ___| |_ ___ _ __
 | __/ _ \ / _' / __| __/ _ \ '__|
 | || (_) | (_| \__ \ ||  __/ |
  \__\___/ \__,_|___/\__\___|_|    ${THIS_VERSION}
================================================================================
 Usage: `basename $0` {update|helper|tools|version}
================================================================================
EOF
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

_save() {
    echo "# toaster" > ${CONFIG}
    echo "SRC_DIR=${SRC_DIR}" >> ${CONFIG}
    echo "ENV_DIR=${ENV_DIR}" >> ${CONFIG}
    echo "PEM_DIR=${PEM_DIR}" >> ${CONFIG}
}

_reset() {
    SRC_DIR=
    ENV_DIR=
    PEM_DIR=
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
    touch ${HISTORY}

    # history
    if [ -z ${_USER} ]; then
        if [ -f ${HISTORY} ]; then
            _result "${HISTORY}"

            cat ${HISTORY} | sort > ${LIST}

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
        aws ec2 describe-instances --query "Reservations[*].Instances[*].PublicIpAddress" --output=text > ${LIST}

        _select_one

        _HOST="${SELECTED}"

        if [ -z ${_HOST} ]; then
            _read "Please input ssh host. []: "

            _HOST="${ANSWER}"
        fi
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
    curl -sL toast.sh/install | bash -s ${PARAM1}
    exit 0
}

_tools() {
    curl -sL toast.sh/tools | bash
    exit 0
}

_git() {
    CMD=$PARAM1
    MSG=$PARAM2
    TAG=$PARAM3
    ALL=$*

    _git_prepare

    case ${CMD} in
        cl|clone)
            git_clone
            ;;
        r|remote)
            git_remote
            ;;
        b|branch)
            git_branch
            ;;
        t|tag)
            git_tag
            ;;
        d|diff)
            git_diff
            ;;
        c|commit)
            git_pull
            git_commit ${ALL}
            git_push
            ;;
        p|pp)
            git_pull
            git_push
            ;;
        pl|pull)
            git_pull
            ;;
        ph|push)
            git_push
            ;;
        rm|remove)
            git_rm
            ;;
        *)
            git_usage
            ;;
    esac
}

_git_prepare() {
    LIST=$(echo ${NOW_DIR} | tr "/" " ")
    DETECT=false

    for V in ${LIST}; do
        if [ -z ${PROVIDER} ]; then
            GIT_PWD="${GIT_PWD}/${V}"
        fi
        if [ "${DETECT}" == "true" ]; then
            if [ -z ${PROVIDER} ]; then
                PROVIDER="${V}"
            elif [ -z ${MY_ID} ]; then
                MY_ID="${V}"
            fi
        elif [ "${V}" == "src" ]; then
            DETECT=true
        fi
    done

    # git@github.com:
    # ssh://git@8.8.8.8:443/
    if [ ! -z ${PROVIDER} ]; then
        if [ "${PROVIDER}" == "github.com" ]; then
            GIT_URL="git@${PROVIDER}:"
        elif [ "${PROVIDER}" == "gitlab.com" ]; then
            GIT_URL="git@${PROVIDER}:"
        else
            if [ -f ${GIT_PWD}/.git_url ]; then
                GIT_URL=$(cat ${GIT_PWD}/.git_url)
            else
                _read "Please input git url. (ex: ssh://git@8.8.8.8:443/): "

                GIT_URL=${ANSWER}

                if [ ! -z ${GIT_URL} ]; then
                    echo "${GIT_URL}" > ${GIT_PWD}/.git_url
                fi
            fi
        fi
    fi
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
        r|reset)
            _reset
            ;;
        u|update)
            _update
            ;;
        t|tools)
            _tools
            ;;
        *)
            _usage
    esac

    _save
}

_toast

_success "done."
