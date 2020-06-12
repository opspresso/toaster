#!/bin/bash

OS_NAME="$(uname | awk '{print tolower($0)}')"

THIS_VERSION=v0.0.0

CMD=$1
PARAM1=$2
PARAM2=$3
PARAM3=$4
PARAM4=$5
PARAMS=$*

CONFIG_DIR="${HOME}/.toaster"

CONFIG="${CONFIG_DIR}/$(basename $0)"

SRC_DIR=
ENV_DIR=
PEM_DIR=

HEIGHT=15

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
            SELECTED=$(cat ${LIST} | fzf --reverse --no-mouse --height=${HEIGHT} --bind=left:page-up,right:page-down)
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

            _read "Please select one (${CNT}): "

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
 Usage: `basename $0` {cdw|env|ctx|ssh|update|tools}
================================================================================
EOF
}

_prepare() {
    mkdir -p ~/.aws
    mkdir -p ~/.ssh
    mkdir -p ${CONFIG_DIR}

    touch ${CONFIG} && . ${CONFIG}

    rm -rf ${LIST} ${TEMP}
}

_src_dir() {
    _prepare

    if [ -z ${SRC_DIR} ] || [ ! -d ${SRC_DIR} ]; then
        DEFAULT="${HOME}/work/src"

        _read "Please input source directory [${DEFAULT}]: "
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

        _read "Please input env directory [${DEFAULT}]: "
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

        _read "Please input pem directory [${DEFAULT}]: "
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

    _DIR=${PARAM1}

    if [ -z ${_DIR} ]; then
        find ${SRC_DIR} -maxdepth 2 -type d -exec ls -d "{}" \; | sort > ${LIST}

        _select_one

        _DIR=${SELECTED}
    fi

    if [ -z ${_DIR} ] || [ ! -d ${_DIR} ]; then
        _error
    fi

    printf "${_DIR}" > ${TEMP}

    _command "cd ${_DIR}"
}

_code() {
    _src_dir

    _DIR=${PARAM1}

    if [ -z ${_DIR} ]; then
        find ${SRC_DIR} -maxdepth 2 -type d -exec ls -d "{}" \; | sort > ${LIST}

        _select_one

        _DIR=${SELECTED}
    fi

    if [ -z ${_DIR} ] || [ ! -d ${_DIR} ]; then
        _error
    fi

    printf "${_DIR}" > ${TEMP}

    _result "${_DIR}"

    if [ "${OS_NAME}" == "linux" ]; then
        /usr/bin/code ${_DIR}
    elif [ "${OS_NAME}" == "darwin" ]; then
        /Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin/code ${_DIR}
    elif [ "${OS_NAME}" == "mingw64_nt-10.0" ]; then
        /c/Users/${USER:-$(whoami)}/AppData/Local/Programs/Microsoft\ VS\ Code/Code.exe ${_DIR}
    else
        _error
    fi
}

_env() {
    _env_dir

    command -v aws > /dev/null || AWSCLI=false

    if [ ! -z ${AWSCLI} ]; then
        _error "Please install awscli."
    fi

    _NAME=${PARAM1}

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

    mkdir -p ~/.aws

    LC=$(cat ${ENV_DIR}/${_NAME} | wc -l | xargs)

    # cp -f ${ENV_DIR}/${_NAME} ~/.aws/credentials

    ACCESS_KEY="$(sed -n 1p ${ENV_DIR}/${_NAME})"
    SECRET_KEY="$(sed -n 2p ${ENV_DIR}/${_NAME})"

    if [ ${LC} -gt 2 ]; then
        _REGION="$(sed -n 3p ${ENV_DIR}/${_NAME})"
    fi
    if [ ${LC} -gt 3 ]; then
        _OUTPUT="$(sed -n 4p ${ENV_DIR}/${_NAME})"
    fi

    _REGION=${PARAM2:-$_REGION}
    _OUTPUT=${PARAM3:-$_OUTPUT}

    aws configure set default.region ${_REGION}
    aws configure set default.output ${_OUTPUT}

    echo "[default]" > ~/.aws/credentials
    echo "aws_access_key_id=${ACCESS_KEY}" >> ~/.aws/credentials
    echo "aws_secret_access_key=${SECRET_KEY}" >> ~/.aws/credentials

    _result "${_NAME}"
    _result "${ACCESS_KEY}"
    _result "**********${SECRET_KEY:30}"
    _result "${_REGION}"

    # all profile
    ls ${ENV_DIR} > ${LIST}

    while read VAL; do
        ACCESS_KEY="$(sed -n 1p ${ENV_DIR}/${VAL})"
        SECRET_KEY="$(sed -n 2p ${ENV_DIR}/${VAL})"

        echo "" >> ~/.aws/credentials
        echo "[${VAL}]" >> ~/.aws/credentials
        echo "aws_access_key_id=${ACCESS_KEY}" >> ~/.aws/credentials
        echo "aws_secret_access_key=${SECRET_KEY}" >> ~/.aws/credentials
    done < ${LIST}

    chmod 600 ~/.aws/credentials
}

_ctx() {
    _NAME=${PARAM1}

    CONTEXT="$(kubectl config view -o json | jq '.contexts' -r)"

    if [ -z "${_NAME}" ]; then
        if [ "${CONTEXT}" == "null" ]; then
            rm -rf ${LIST} && touch ${LIST}
        else
            kubectl config view -o json | jq '.contexts[].name' -r | sort > ${LIST}
        fi

        echo "[New...]" >> ${LIST}
        echo "[Del...]" >> ${LIST}

        _select_one

        _NAME="${SELECTED}"
    fi

    if [ -z "${_NAME}" ]; then
        _error
    fi

    if [ "${_NAME}" == "[New...]" ]; then
        aws eks list-clusters | jq '.clusters[]' -r | sort > ${LIST}

        _select_one

        _NAME="${SELECTED}"

        if [ -z "${_NAME}" ]; then
            _error
        fi

        _command "aws eks update-kubeconfig --name ${_NAME} --alias ${_NAME}"
        aws eks update-kubeconfig --name ${_NAME} --alias ${_NAME}

        return
    fi

    if [ "${_NAME}" == "[Del...]" ]; then
        if [ "${CONTEXT}" == "null" ]; then
            rm -rf ${LIST} && touch ${LIST}
        else
            kubectl config view -o json | jq '.contexts[].name' -r | sort > ${LIST}
        fi

        echo "[All...]" >> ${LIST}

        _select_one

        _NAME="${SELECTED}"

        if [ -z "${_NAME}" ]; then
            _error
        fi

        if [ "${_NAME}" == "[All...]" ]; then
            _command "rm -rf ~/.kube"
            rm -rf ~/.kube
        else
            _command "kubectl config delete-context ${_NAME}"
            kubectl config delete-context ${_NAME}
        fi

        return
    fi

    _command "kubectl config use-context ${_NAME}"
    kubectl config use-context ${_NAME}
}

_ssh() {
    _pem_dir

    _PEMS=${PARAM1}
    _HOST=${PARAM2}
    _USER=${PARAM3}

    HISTORY="${CONFIG_DIR}/ssh-history"
    touch ${HISTORY}

    # config
    if [ ! -f ~/.ssh/config ]; then
cat <<EOF > ~/.ssh/config
Host *
    StrictHostKeyChecking no
EOF
    fi
    chmod 400 ~/.ssh/config

    # history
    if [ -z ${_USER} ]; then
        if [ -f ${HISTORY} ]; then
            _result "${HISTORY}"

            cat ${HISTORY} | sort > ${LIST}

            _select_one

            if [ "${SELECTED}" != "" ]; then
                ARR=(${SELECTED})

                _PEMS=${ARR[0]}
                _HOST=${ARR[1]}
                _USER=${ARR[2]}

                FROM_HISTORY=true
            fi
        fi
    fi

    # pem
    if [ -z ${_PEMS} ]; then
        ls ${PEM_DIR} > ${LIST}

        _select_one

        if [ -z ${SELECTED} ] || [ ! -f ${PEM_DIR}/${SELECTED} ]; then
            _error
        fi

        _PEMS="${SELECTED}"
    fi
    if [ -z ${_PEMS} ]; then
        _error
    fi

    # host
    if [ -z ${_HOST} ]; then
        aws ec2 describe-instances \
            --filters "Name=tag:Type,Values=bastion" \
            --query "Reservations[].Instances[].{Name:Tags[?Key=='Name'] | [0].Value, Ip:PublicIpAddress}" \
            --output=text > ${LIST}

        _select_one

        _HOST="$(echo ${SELECTED} | awk '{print $1}')"

        if [ -z ${_HOST} ]; then
            _read "Please input ssh host []: "

            _HOST="${ANSWER}"
        fi
    fi
    if [ -z ${_HOST} ]; then
        _error
    fi

    # user
    if [ -z ${_USER} ]; then
        DEFAULT="ec2-user"
        _read "Please input ssh user [${DEFAULT}]: "
        _USER="${ANSWER:-${DEFAULT}}"
    fi
    if [ -z ${_USER} ]; then
        _error
    fi

    if [ ! -f ${PEM_DIR}/${_PEMS} ]; then
        if [ -f ${PEM_DIR}/${_PEMS}.pem ]; then
            _PEMS="${_PEMS}.pem"
        else
            _error
        fi
    fi

    if [ -z ${FROM_HISTORY} ]; then
        COUNT=$(cat ${HISTORY} | grep "${_PEMS} ${_HOST} ${_USER}" | wc -l | xargs)

        if [ "x${COUNT}" == "x0" ]; then
            echo "${_PEMS} ${_HOST} ${_USER}" >> ${HISTORY}
        fi
    fi

    chmod 600 ${PEM_DIR}/${_PEMS}

    grep -v "${_HOST}" ~/.ssh/known_hosts > /tmp/known_hosts
    cp /tmp/known_hosts ~/.ssh/known_hosts

    _command "ssh -i ${PEM_DIR}/${_PEMS} ${_USER}@${_HOST}"
    ssh -i ${PEM_DIR}/${_PEMS} ${_USER}@${_HOST}
}

_mfa() {
    ACCOUNT_ID=$(aws sts get-caller-identity | grep "Account" | cut -d'"' -f4)

    _result "${ACCOUNT_ID}"

    USERNAME=$(aws sts get-caller-identity | grep "Arn" | cut -d'"' -f 4 | cut -d'/' -f2)

    _result "${USERNAME}"

    if [ "${ACCOUNT_ID}" == "" ] || [ "${USERNAME}" == "" ]; then
        _error
    fi

    _read "TOKEN_CODE : "
    TOKEN_CODE=${ANSWER}

    _aws_sts_token "${ACCOUNT_ID}" "${USERNAME}" "${TOKEN_CODE}"
}

_aws_sts_token() {
    ACCOUNT_ID=${1}
    USERNAME=${2}
    TOKEN_CODE=${3}

    TMP=/tmp/sts-result

    if [ "${TOKEN_CODE}" == "" ]; then
        aws sts get-session-token > ${TMP}
    else
        aws sts get-session-token \
            --serial-number arn:aws:iam::${ACCOUNT_ID}:mfa/${USERNAME} \
            --token-code ${TOKEN_CODE} > ${TMP}
    fi

    ACCESS_KEY=$(cat ${TMP} | grep AccessKeyId | cut -d'"' -f4)
    SECRET_KEY=$(cat ${TMP} | grep SecretAccessKey | cut -d'"' -f4)

    if [ "${ACCESS_KEY}" == "" ] || [ "${SECRET_KEY}" == "" ]; then
        _error "Cannot call GetSessionToken."
    fi

    SESSION_TOKEN=$(cat ${TMP} | grep SessionToken | cut -d'"' -f4)

    echo "[default]" > ~/.aws/credentials
    echo "aws_access_key_id=${ACCESS_KEY}" >> ~/.aws/credentials
    echo "aws_secret_access_key=${SECRET_KEY}" >> ~/.aws/credentials

    if [ "${SESSION_TOKEN}" != "" ]; then
        echo "aws_session_token=${SESSION_TOKEN}" >> ~/.aws/credentials
    fi

    chmod 600 ~/.aws/credentials

    _result "${USERNAME}"
    _result "${ACCESS_KEY}"
    _result "**********${SECRET_KEY:30}"
}

_mtu() {
    _MTU=${PARAM1}
    _VAL=${PARAM2}

    _command "ifconfig | grep mtu"
    ifconfig | grep mtu

    # mtu name
    if [ -z ${_MTU} ]; then
        DEFAULT="en0"
        _read "Please input mtu [${DEFAULT}]: "
        _MTU="${ANSWER:-${DEFAULT}}"
    fi
    if [ -z ${_MTU} ]; then
        _error
    fi

    # mtu value
    if [ -z ${_VAL} ]; then
        DEFAULT="1500"
        _read "Please input mtu [${DEFAULT}]: "
        _VAL="${ANSWER:-${DEFAULT}}"
    fi
    if [ -z ${_VAL} ]; then
        _error
    fi

    _command "sudo ifconfig ${_MTU} mtu ${_VAL}"
    sudo ifconfig ${_MTU} mtu ${_VAL}

    _command "ifconfig | grep mtu | grep ${_MTU}"
    ifconfig | grep mtu | grep ${_MTU}
}

_stress() {
    _REQ=${PARAM1}
    _CON=${PARAM2}
    _URL=${PARAM3}

    HISTORY="${CONFIG_DIR}/stress-history"
    touch ${HISTORY}

    # history
    if [ -z ${_URL} ]; then
        if [ -f ${HISTORY} ]; then
            _result "${HISTORY}"

            cat ${HISTORY} | sort > ${LIST}

            _select_one

            if [ "${SELECTED}" != "" ]; then
                ARR=(${SELECTED})

                _REQ=${ARR[0]}
                _CON=${ARR[1]}
                _URL=${ARR[2]}

                FROM_HISTORY=true
            fi
        fi
    fi

    # requests
    if [ -z ${_REQ} ]; then
        DEFAULT="1000000"
        _read "Please input requests [${DEFAULT}]: "
        _REQ="${ANSWER:-${DEFAULT}}"
    fi
    if [ -z ${_REQ} ]; then
        _error
    fi

    # concurrency
    if [ -z ${_CON} ]; then
        DEFAULT="10"
        _read "Please input concurrency [${DEFAULT}]: "
        _CON="${ANSWER:-${DEFAULT}}"
    fi
    if [ -z ${_CON} ]; then
        _error
    fi

    # url
    if [ -z ${_URL} ]; then
        _read "Please input url : "
        _URL="${ANSWER}"
    fi
    if [ -z ${_URL} ]; then
        _error
    fi

    if [ -z ${FROM_HISTORY} ]; then
        COUNT=$(cat ${HISTORY} | grep "${_REQ} ${_CON} ${_URL}" | wc -l | xargs)

        if [ "x${COUNT}" == "x0" ]; then
            echo "${_REQ} ${_CON} ${_URL}" >> ${HISTORY}
        fi
    fi

    _command "ab -n ${_REQ} -c ${_CON} ${_URL}"
    ab -n ${_REQ} -c ${_CON} ${_URL}
}

_update() {
    _echo "# version: ${THIS_VERSION}" 3
    curl -sL toast.sh/install | bash -s ${PARAM1}
    exit 0
}

_tools() {
    # curl -sL opspresso.com/install | bash
    curl -sL opspresso.github.io/tools/install.sh | bash
    exit 0
}

_docker() {
    CMD=${PARAM1}

    case ${CMD} in
        c|clean)
            docker_clean
            ;;
    esac
}

docker_clean() {
    echo
    echo "$ docker ps -a -f status=exited -f status=dead"

    LIST="$(docker ps -a -q -f status=exited -f status=dead | xargs)"
    if [ "${LIST}" != "" ]; then
        docker rm ${LIST}
    fi

    echo
    echo "$ docker images -f dangling=true"

    LIST="$(docker images -q -f dangling=true | xargs)"
    if [ "${LIST}" != "" ]; then
        docker rmi ${LIST}
    fi

    echo
    echo "$ docker volume ls -f dangling=true"

    LIST="$(docker volume ls -q -f dangling=true | xargs)"
    if [ "${LIST}" != "" ]; then
        docker volume rm ${LIST}
    fi
}

_git() {
    _git_prepare

    case ${CMD} in
        cl|clone)
            git_clone
            ;;
        rm|remove)
            git_rm
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
            git_commit ${PARAMS}
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
        # *)
        #     git_usage
        #     ;;
    esac
}

_git_prepare() {
    APP=$(echo "$PARAM1" | sed -e "s/\///g")
    CMD=$PARAM2
    MSG=$PARAM3
    TAG=$PARAM4

    if [ -z ${CMD} ]; then
        _error
    fi

    NOW_DIR=$(pwd)

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
                USERNAME="${V}"
            fi
        elif [ "${V}" == "src" ]; then
            DETECT=true
        fi
    done

    # git@github.com:
    # ssh://git@8.8.8.8:88/
    if [ ! -z ${PROVIDER} ]; then
        if [ "${PROVIDER}" == "github.com" ]; then
            GIT_URL="git@${PROVIDER}:"
        elif [ "${PROVIDER}" == "gitlab.com" ]; then
            GIT_URL="git@${PROVIDER}:"
        elif [ "${PROVIDER}" == "keybase" ]; then
            GIT_URL="${PROVIDER}://"
        else
            if [ -f ${GIT_PWD}/.git_url ]; then
                GIT_URL=$(cat ${GIT_PWD}/.git_url)
            else
                _read "Please input git url (ex: ssh://git@8.8.8.8:88/): "

                GIT_URL=${ANSWER}

                if [ ! -z ${GIT_URL} ]; then
                    echo "${GIT_URL}" > ${GIT_PWD}/.git_url
                fi
            fi
        fi
    fi

    case ${CMD} in
        cl|clone)
            if [ -z ${MSG} ]; then
                PROJECT=${APP}
            else
                PROJECT=${MSG}
            fi
            if [ -d ${NOW_DIR}/${PROJECT} ]; then
                _error "Source directory already exists. [${NOW_DIR}/${PROJECT}]"
            fi
            ;;
        *)
            PROJECT=${APP}
            if [ ! -d ${NOW_DIR}/${PROJECT} ]; then
                _error "Source directory doesn't exists. [${NOW_DIR}/${PROJECT}]"
            fi
            ;;
    esac

    case ${CMD} in
        cl|clone|rm|remove)
            ;;
        *)
            git_dir
            ;;
    esac
}

git_dir() {
    cd ${NOW_DIR}/${PROJECT}

    # selected branch
    BRANCH=$(git branch | grep \* | cut -d' ' -f2)

    if [ -z ${BRANCH} ]; then
        BRANCH="master"
    fi

    _result "${BRANCH}"
}

git_clone() {
    _command "git clone ${GIT_URL}${USERNAME}/${APP}.git ${PROJECT}"
    git clone ${GIT_URL}${USERNAME}/${APP}.git ${PROJECT}

    if [ ! -d ${NOW_DIR}/${PROJECT} ]; then
        _error "Source directory doesn't exists. [${NOW_DIR}/${PROJECT}]"
    fi

    git_dir

    # https://github.com/awslabs/git-secrets

    _command "git secrets --install"
    git secrets --install

    _command "git secrets --register-aws"
    git secrets --register-aws

    _command "git branch -v"
    git branch -v
}

git_rm() {
    rm -rf ${NOW_DIR}/${PROJECT}
}

git_remote() {
    _command "git remote"
    git remote

    if [ -z ${MSG} ]; then
        _error
    fi

    REMOTES="/tmp/${APP}-remote"
    git remote > ${REMOTES}

    while read VAR; do
        if [ "${VAR}" == "${MSG}" ]; then
            _error "Remote '${MSG}' already exists."
        fi
    done < ${REMOTES}

    _command "git remote add --track master ${MSG} ${GIT_URL}${MSG}/${APP}.git"
    git remote add --track master ${MSG} ${GIT_URL}${MSG}/${APP}.git

    _command "git remote"
    git remote
}

git_branch() {
    _command "git branch -a"
    git branch -a

    if [ -z ${MSG} ]; then
        _error
    fi
    if [ "${MSG}" == "${BRANCH}" ]; then
        _error "Already on '${BRANCH}'."
    fi

    HAS="false"
    BRANCHES="/tmp/${APP}-branch"
    git branch -a > ${BRANCHES}

    while read VAR; do
        ARR=(${VAR})
        if [ -z ${ARR[1]} ]; then
            if [ "${ARR[0]}" == "${MSG}" ]; then
                HAS="true"
            fi
        else
            if [ "${ARR[1]}" == "${MSG}" ]; then
                HAS="true"
            fi
        fi
    done < ${BRANCHES}

    if [ "${HAS}" != "true" ]; then
        _command "git branch ${MSG} ${TAG}"
        git branch ${MSG} ${TAG}
    fi

    _command "git checkout ${MSG}"
    git checkout ${MSG}

    if [ "${HAS}" == "true" ]; then
        _command "git pull origin ${MSG}"
        git pull origin ${MSG}
    fi

    _command "git branch -v"
    git branch -v
}

git_diff() {
    _command "git branch -v"
    git branch -v

    _command "git diff"
    git diff
}

git_commit() {
    shift 3
    MSG=$*

    if [ "${MSG}" == "" ]; then
        _error
    fi

    _command "git add --all"
    git add --all

    _command "git commit -m ${MSG}"
    git commit -a --allow-empty-message -m "${MSG}"
}

git_pull() {
    _command "git branch -v"
    git branch -v

    REMOTES="/tmp/${APP}-remote"
    git remote > ${REMOTES}

    _command "git pull origin ${BRANCH}"
    git pull origin ${BRANCH}

    while read REMOTE; do
        if [ "${REMOTE}" != "origin" ]; then
            _command "git pull ${REMOTE} ${BRANCH}"
            git pull ${REMOTE} ${BRANCH}
        fi
    done < ${REMOTES}
}

git_push() {
    _command "git branch -v"
    git branch -v

    _command "git push origin ${BRANCH}"
    git push origin ${BRANCH}
}

git_tag() {
    _command "git branch -v"
    git branch -v

    _command "git pull"
    git pull

    _command "git tag"
    git tag
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
        d|docker)
            _docker
            ;;
        s|ssh)
            _ssh
            ;;
        a|mfa)
            _mfa
            ;;
        x|ctx)
            _ctx
            ;;
        v|code)
            _code
            ;;
        m|mtu)
            _mtu
            ;;
        b|stress)
            _stress
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

_success
