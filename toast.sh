#!/bin/bash

# OS 관련 설정
OS_NAME="$(uname | awk '{print tolower($0)}')"
OS_DARWIN=false
OS_LINUX=false

case ${OS_NAME} in
darwin*) OS_DARWIN=true ;;
linux*) OS_LINUX=true ;;
esac

# 크로스 플랫폼 명령어 래퍼 함수들
_sed() {
  if [ "${OS_DARWIN}" == "true" ]; then
    sed -i "" "$@"
  else
    sed -i "$@"
  fi
}

_grep() {
  if [ "${OS_DARWIN}" == "true" ]; then
    grep -E "$@"
  else
    grep -P "$@"
  fi
}

_xargs() {
  if [ "${OS_DARWIN}" == "true" ]; then
    xargs "$@"
  else
    xargs -r "$@"
  fi
}

_readlink() {
  if [ "${OS_DARWIN}" == "true" ]; then
    greadlink -f "$@"
  else
    readlink -f "$@"
  fi
}

TOAST_VERSION=${TOAST_VERSION:-$(cat VERSION 2>/dev/null || echo "v0.0.0")}

CMD=$1
PARAM1=$2
PARAM2=$3
PARAM3=$4
PARAM4=$5
PARAMS=$*

CONFIG_DIR="${HOME}/.toast"

CONFIG="${CONFIG_DIR}/$(basename $0)"

ENV_DIR=
PEM_DIR=
ROLE_DIR=
SRC_DIR=

HEIGHT=15

# 임시 파일들을 위한 유니크한 이름 생성
LIST=$(mktemp /tmp/toast-XXXXXX-list)
TEMP=$(mktemp /tmp/toast-XXXXXX-result)

# 스크립트 종료 시 임시 파일 정리
cleanup() {
  rm -f ${LIST} ${TEMP} /tmp/sts-result /tmp/*-remote /tmp/*-branch
}
trap cleanup EXIT

################################################################################

command -v fzf >/dev/null && FZF=true
command -v tput >/dev/null && TPUT=true

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
  exit 0
}

_error() {
  echo
  _echo "- $@" 1
  exit 1
}

_replace() {
  _sed -e "$1" "$2"
}

_find_replace() {
  if [ "${OS_DARWIN}" == "true" ]; then
    find . -name "$2" -exec sed -i "" -e "$1" {} \;
  else
    find . -name "$2" -exec sed -i -e "$1" {} \;
  fi
}

# 크로스 플랫폼 명령어 체크
_check_commands() {
  if [ "${OS_DARWIN}" == "true" ]; then
    command -v greadlink >/dev/null || brew install coreutils
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
        IDX=$((${IDX} + 1))
        printf "%3s. %s\n" "${IDX}" "${VAL}"
      done <${LIST}

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
  #figlet toast.sh
  cat <<EOF
================================================================================
 _                  _         _
| |_ ___   __ _ ___| |_   ___| |__
| __/ _ \ / _' / __| __| / __| '_ \\
| || (_) | (_| \__ \ |_ _\__ \ | | |
 \__\___/ \__,_|___/\__(_)___/_| |_|   ${TOAST_VERSION}
================================================================================
  Usage: $(basename $0) {cdw|am|env|git|ssh|region|ssh|ctx|ns|update}

  alias t='toast'

  c() {
    local dir="$(toast cdw $@)"
    if [ -n "$dir" ]; then
      echo "$dir"
      cd "$dir"
    fi
  }

  alias m='toast am'
  alias e='toast env'
  alias n='toast git'
  alias s='toast ssh'
  alias r='toast region'
  alias x='toast ctx'
  alias z='toast ns'
================================================================================
EOF
}

_prepare() {
  _check_commands

  mkdir -p ~/.aws
  mkdir -p ~/.ssh
  mkdir -p ${CONFIG_DIR}

  touch ${CONFIG} && . ${CONFIG}

  rm -rf ${LIST} ${TEMP}
}

_src_dir() {
  _prepare

  if [ -z ${SRC_DIR} ] || [ ! -d ${SRC_DIR} ]; then
    DEFAULT="${HOME}/workspace"

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

_role_dir() {
  _src_dir

  if [ -z ${ROLE_DIR} ] || [ ! -d ${ROLE_DIR} ]; then
    DEFAULT="${SRC_DIR}/github.com/${USER}/keys/role"

    _read "Please input role directory [${DEFAULT}]: "
    ROLE_DIR=${ANSWER:-${DEFAULT}}
  fi

  if [ ! -d ${ROLE_DIR} ]; then
    _error "[${ROLE_DIR}] is not directory."
  fi
}

_save() {
  echo "# toast" >${CONFIG}
  echo "ENV_DIR=${ENV_DIR}" >>${CONFIG}
  echo "PEM_DIR=${PEM_DIR}" >>${CONFIG}
  echo "ROLE_DIR=${ROLE_DIR}" >>${CONFIG}
  echo "SRC_DIR=${SRC_DIR}" >>${CONFIG}
}

_reset() {
  SRC_DIR=
  ENV_DIR=
  PEM_DIR=
}

_am() {
  _command "aws sts get-caller-identity"
  aws sts get-caller-identity | jq .
}

_av() {
  if [ ! -f ~/.aws/config ]; then
    _error "~/.aws/config not found."
  fi

  _VAL=${PARAM1}

  if [ -z ${_VAL} ]; then
    cat ~/.aws/config | sed -n 's/\[profile \(.*\)\]/\1/p' >${LIST}

    _select_one

    _VAL=${SELECTED}
  fi

  if [ -z ${_VAL} ]; then
    echo ""
    exit 1
  fi

  # export AWS_VAULT= && aws-vault exec ${_VAL} --

  echo "${_VAL}"
  exit 0
}

_cdw() {
  _src_dir

  _DIR=${PARAM1}

  if [ -z ${_DIR} ]; then
    find ${SRC_DIR} -maxdepth 2 -type d -exec ls -d "{}" \; | sort >${LIST}

    _select_one

    _DIR=${SELECTED}
  fi

  if [ -z ${_DIR} ] || [ ! -d ${_DIR} ]; then
    echo ""
    exit 1
  fi

  echo "${_DIR}"
  exit 0
}

_env() {
  _env_dir

  command -v aws >/dev/null || AWSCLI=false

  if [ ! -z ${AWSCLI} ]; then
    _error "Please install awscli."
  fi

  _NAME=${PARAM1}

  if [ -z ${_NAME} ]; then
    ls ${ENV_DIR} >${LIST}

    _select_one

    _NAME="${SELECTED}"
  fi

  if [ -z ${_NAME} ]; then
    _error
  fi
  if [ ! -f "${ENV_DIR}/${_NAME}" ]; then
    _error
  fi

  _result "${_NAME}"

  # LC=$(cat ${ENV_DIR}/${_NAME} | wc -l | xargs)

  ACCESS_KEY="$(sed -n 1p ${ENV_DIR}/${_NAME})"
  SECRET_KEY="$(sed -n 2p ${ENV_DIR}/${_NAME})"
  _REGION="$(sed -n 3p ${ENV_DIR}/${_NAME})"
  _OUTPUT="$(sed -n 4p ${ENV_DIR}/${_NAME})"
  _MFA="$(sed -n 5p ${ENV_DIR}/${_NAME})"

  ARR=(${_REGION})

  if [ ! -z ${ARR[1]} ]; then
    LIST=/tmp/regions && rm -rf ${LIST}

    for V in ${ARR[@]}; do
      echo ${V} >>${LIST}
    done

    _select_one

    _REGION="${SELECTED}"
  fi

  _REGION=${_REGION:-ap-northeast-2}
  _OUTPUT=${_OUTPUT:-json}

  aws configure set default.region ${_REGION}
  aws configure set default.output ${_OUTPUT}

  _command "export AWS_REGION=${_REGION}"
  export AWS_REGION=${_REGION}

  echo "[default]" >~/.aws/credentials
  echo "aws_access_key_id=${ACCESS_KEY}" >>~/.aws/credentials
  echo "aws_secret_access_key=${SECRET_KEY}" >>~/.aws/credentials

  chmod 600 ~/.aws/credentials

  rm -rf ~/.aws/credentials.backup

  ACCOUNT_ID=$(aws sts get-caller-identity | grep "Account" | cut -d'"' -f4)
  _result "${ACCOUNT_ID}"

  USERNAME=$(aws sts get-caller-identity | grep "Arn" | cut -d'"' -f4 | cut -d'/' -f2)
  _result "user/${USERNAME}"

  if [ "${ACCOUNT_ID}" == "" ] || [ "${USERNAME}" == "" ]; then
    _error
  fi

  _command "export AWS_ACCOUNT_ID=${ACCOUNT_ID}"
  export AWS_ACCOUNT_ID=${ACCOUNT_ID}

  if [ "${_MFA}" == "mfa" ]; then
    _mfa
  fi

  # _result "${ACCESS_KEY}"
  # _result "**********${SECRET_KEY:30}"
  # _result "${_REGION}"

  _am
}

_mfa() {
  _read "TOKEN_CODE : "
  TOKEN_CODE=${ANSWER}

  TMP=$(mktemp /tmp/sts-XXXXXX-result)

  if [ "${TOKEN_CODE}" == "" ]; then
    aws sts get-session-token >${TMP}
  else
    aws sts get-session-token \
      --serial-number arn:aws:iam::${ACCOUNT_ID}:mfa/${USERNAME} \
      --token-code ${TOKEN_CODE} >${TMP}
  fi

  ACCESS_KEY=$(cat ${TMP} | grep AccessKeyId | cut -d'"' -f4)
  SECRET_KEY=$(cat ${TMP} | grep SecretAccessKey | cut -d'"' -f4)

  if [ "${ACCESS_KEY}" == "" ] || [ "${SECRET_KEY}" == "" ]; then
    _error "Cannot call GetSessionToken."
  fi

  SESSION_TOKEN=$(cat ${TMP} | grep SessionToken | cut -d'"' -f4)

  echo "[default]" >~/.aws/credentials
  echo "aws_access_key_id=${ACCESS_KEY}" >>~/.aws/credentials
  echo "aws_secret_access_key=${SECRET_KEY}" >>~/.aws/credentials

  if [ "${SESSION_TOKEN}" != "" ]; then
    echo "aws_session_token=${SESSION_TOKEN}" >>~/.aws/credentials
  fi

  chmod 600 ~/.aws/credentials

  # _am
}

_assume() {
  _role_dir

  _NAME=${PARAM1}
  _ROLE=${PARAM2}

  # role
  if [ -z ${_NAME} ]; then
    ls ${ROLE_DIR} >${LIST}

    if [ -f ~/.aws/credentials.backup ]; then
      echo "[Restore...]" >>${LIST}
    fi

    _select_one

    if [ -z ${SELECTED} ]; then
      _error
    fi

    _NAME="${SELECTED}"
  fi
  if [ -z ${_NAME} ]; then
    _error
  fi

  if [ "${_NAME}" == "[Restore...]" ]; then
    mv ~/.aws/credentials.backup ~/.aws/credentials

    _am

    _success
  fi

  if [ ! -f "${ROLE_DIR}/${_NAME}" ]; then
    _error
  fi

  if [ -z ${_ROLE} ]; then
    _ROLE="$(sed -n 1p ${ROLE_DIR}/${_NAME})"
  fi
  if [ -z ${_ROLE} ]; then
    _error
  fi

  TMP=/tmp/sts-result

  aws sts assume-role \
    --role-arn ${_ROLE} \
    --role-session-name ${_NAME} >${TMP}

  ACCESS_KEY=$(cat ${TMP} | grep AccessKeyId | cut -d'"' -f4)
  SECRET_KEY=$(cat ${TMP} | grep SecretAccessKey | cut -d'"' -f4)

  if [ "${ACCESS_KEY}" == "" ] || [ "${SECRET_KEY}" == "" ]; then
    _error "Cannot call GetSessionToken."
  fi

  SESSION_TOKEN=$(cat ${TMP} | grep SessionToken | cut -d'"' -f4)

  if [ -f ~/.aws/credentials ]; then
    cp ~/.aws/credentials ~/.aws/credentials.backup
    chmod 600 ~/.aws/credentials.backup
  fi

  echo "[default]" >~/.aws/credentials
  echo "aws_access_key_id=${ACCESS_KEY}" >>~/.aws/credentials
  echo "aws_secret_access_key=${SECRET_KEY}" >>~/.aws/credentials

  if [ "${SESSION_TOKEN}" != "" ]; then
    echo "aws_session_token=${SESSION_TOKEN}" >>~/.aws/credentials
  fi

  chmod 600 ~/.aws/credentials

  # echo "export AWS_ACCESS_KEY_ID=${ACCESS_KEY}"
  # echo "export AWS_SECRET_ACCESS_KEY=${SECRET_KEY}"
  # echo "export AWS_SESSION_TOKEN=${SESSION_TOKEN}"

  # export AWS_ACCESS_KEY_ID=${ACCESS_KEY}
  # export AWS_SECRET_ACCESS_KEY=${SECRET_KEY}
  # export AWS_SESSION_TOKEN=${SESSION_TOKEN}

  _am
}

_region() {
  command -v aws >/dev/null || AWSCLI=false

  if [ ! -z ${AWSCLI} ]; then
    _error "Please install awscli."
  fi

  _REGION=${PARAM1}

  if [ -z "${_REGION}" ]; then
    _result "$(aws configure get default.region)"

    aws ec2 describe-regions --output text | cut -f4 | sort >${LIST}

    _select_one

    _REGION="${SELECTED}"
  fi

  if [ -z "${_REGION}" ]; then
    _error "Region not found."
  fi

  _set_region ${_REGION}
}

_set_region() {
  _REGION=$1

  _command "export AWS_REGION=${_REGION}"
  export AWS_REGION=${_REGION}

  _command "export AWS_DEFAULT_REGION=${_REGION}"
  export AWS_DEFAULT_REGION=${_REGION}

  _command "aws configure set default.region ${_REGION}"
  aws configure set default.region ${_REGION}
}

_ctx() {
  _NAME=${PARAM1}

  CONTEXT="$(kubectl config view -o json | jq '.contexts' -r)"

  if [ -z "${_NAME}" ]; then
    if [ "${CONTEXT}" == "null" ]; then
      rm -rf ${LIST} && touch ${LIST}
    else
      # kubectl config view -o json | jq '.contexts[].name' -r | sort > ${LIST}
      kubectl config view -o json | jq '.contexts[].context.cluster' -r | tr '/' ':' | cut -d':' -f4 -f7 | sort >${LIST}
    fi

    echo "[New...]" >>${LIST}
    echo "[Del...]" >>${LIST}

    _select_one

    # _NAME="${SELECTED}"

    if [[ ${SELECTED} == *":"* ]]; then
      _REGION="$(echo ${SELECTED} | cut -d':' -f1)"
      _NAME="$(echo ${SELECTED} | cut -d':' -f2)"

      _set_region ${_REGION}
    else
      _NAME="${SELECTED}"
    fi
  fi

  if [ -z "${_NAME}" ]; then
    _error
  fi

  if [ "${_NAME}" == "[New...]" ]; then
    aws eks list-clusters | jq '.clusters[]' -r | sort >${LIST}

    _select_one

    _NAME="${SELECTED}"

    if [ -z "${_NAME}" ]; then
      _error
    fi

    _command "aws eks update-kubeconfig --name ${_NAME} --alias ${_NAME}"
    aws eks update-kubeconfig --name ${_NAME} --alias ${_NAME}

    chmod 600 ~/.kube/config

    return
  fi

  if [ "${_NAME}" == "[Del...]" ]; then
    if [ "${CONTEXT}" == "null" ]; then
      rm -rf ${LIST} && touch ${LIST}
    else
      kubectl config view -o json | jq '.contexts[].name' -r | sort >${LIST}
    fi

    echo "[All...]" >>${LIST}

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

    # chmod 600 ~/.kube/config

    return
  fi

  printf "${_NAME}" >${TEMP}

  _command "kubectl config use-context ${_NAME}"
  kubectl config use-context ${_NAME}

  chmod 600 ~/.kube/config
}

_ns() {
  _NAME=${PARAM1}

  if [ -z "${_NAME}" ]; then
    kubectl get ns | grep Active | cut -d' ' -f1 >${LIST}

    _select_one

    _NAME="${SELECTED}"
  fi

  if [ -z "${_NAME}" ]; then
    _error
  fi

  printf "${_NAME}" >${TEMP}

  _command "kubectl config set-context --current --namespace=${_NAME}"
  kubectl config set-context --current --namespace=${_NAME}
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
    cat <<EOF >~/.ssh/config
Host *
  StrictHostKeyChecking accept-new
EOF
  fi
  chmod 600 ~/.ssh/config

  # history
  if [ -z ${_USER} ]; then
    if [ -f ${HISTORY} ]; then
      _result "${HISTORY}"

      cat ${HISTORY} | sort >${LIST}

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
    ls ${PEM_DIR} | grep '.pem' >${LIST}

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
      --output=text >${LIST}

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
      echo "${_PEMS} ${_HOST} ${_USER}" >>${HISTORY}
    fi
  fi

  chmod 600 ${PEM_DIR}/${_PEMS}

  rm -rf ~/.ssh/known_hosts && touch ~/.ssh/known_hosts

  _command "ssh -i ${PEM_DIR}/${_PEMS} ${_USER}@${_HOST}"
  ssh -i ${PEM_DIR}/${_PEMS} ${_USER}@${_HOST}
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

      cat ${HISTORY} | sort >${LIST}

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
      echo "${_REQ} ${_CON} ${_URL}" >>${HISTORY}
    fi
  fi

  _command "ab -n ${_REQ} -c ${_CON} ${_URL}"
  ab -n ${_REQ} -c ${_CON} ${_URL}
}

_version() {
  _echo "# version: ${TOAST_VERSION}" 3
  exit 0
}

_update() {
  # _echo "# version: ${THIS_VERSION}" 3
  curl -fsSL toast.sh/install | bash -s ${PARAM1}
  exit 0
}

_tools() {
  /bin/bash -c "$(curl -fsSL nalbam.github.io/dotfiles/run.sh)"
  exit 0
}

_git() {
  git_prepare

  case ${CMD} in
  cl | clone)
    git_clone
    ;;
  rm | remove)
    git_rm
    ;;
  r | remote)
    git_remote
    ;;
  b | branch)
    git_branch
    ;;
  t | tag)
    git_tag
    ;;
  d | diff)
    git_diff
    ;;
  c | commit)
    git_pull
    git_commit ${PARAMS}
    git_push
    ;;
  p | pp)
    git_pull
    git_push
    ;;
  pl | pull)
    git_pull
    ;;
  ph | push)
    git_push
    ;;
    # *)
    #   git_usage
    #   ;;
  esac
}

# Git 관련 함수들을 더 작고 명확한 단위로 분리

git_parse_params() {
  local app=$1
  local cmd=$2
  local msg=$3
  local tag=$4

  APP=$(echo "$app" | sed -e "s/\///g")
  CMD=$cmd
  MSG=$msg
  TAG=$tag

  if [ -z "${CMD}" ]; then
    if [ "${APP}" == "config" ]; then
      git_config
    fi
    _error
  fi
}

git_get_provider() {
  local now_dir=$1
  local list=$(echo ${now_dir} | tr "/" " ")
  local detect=false
  local git_pwd=""
  local provider=""
  local username=""

  for V in ${list}; do
    if [ -z ${provider} ]; then
      git_pwd="${git_pwd}/${V}"
    fi
    if [ "${detect}" == "true" ]; then
      if [ -z ${provider} ]; then
        provider="${V}"
      elif [ -z ${username} ]; then
        username="${V}"
      fi
    elif [ "${V}" == "workspace" ]; then
      detect=true
    fi
  done

  GIT_PWD=${git_pwd}
  PROVIDER=${provider}
  USERNAME=${username}
}

git_get_url() {
  local provider=$1
  local git_pwd=$2

  if [ ! -z ${provider} ]; then
    if [ "${provider}" == "github.com" ]; then
      GIT_URL="git@${provider}:"
    elif [ "${provider}" == "gitlab.com" ]; then
      GIT_URL="git@${provider}:"
    elif [ "${provider}" == "keybase" ]; then
      GIT_URL="${provider}://"
    else
      if [ -f ${git_pwd}/.git_url ]; then
        GIT_URL=$(cat ${git_pwd}/.git_url)
      else
        _read "Please input git url (ex: ssh://git@8.8.8.8:88/): "
        GIT_URL=${ANSWER}
        if [ ! -z ${GIT_URL} ]; then
          echo "${GIT_URL}" >${git_pwd}/.git_url
        fi
      fi
    fi
  fi
}

git_check_project() {
  local cmd=$1
  local app=$2
  local msg=$3
  local now_dir=$4

  case ${cmd} in
  cl | clone)
    if [ -z ${msg} ]; then
      PROJECT=${app}
    else
      PROJECT=${msg}
    fi
    if [ -d ${now_dir}/${PROJECT} ]; then
      _error "Source directory already exists. [${now_dir}/${PROJECT}]"
    fi
    ;;
  *)
    PROJECT=${app}
    if [ ! -d ${now_dir}/${PROJECT} ]; then
      _error "Source directory doesn't exists. [${now_dir}/${PROJECT}]"
    fi
    ;;
  esac
}

git_prepare() {
  NOW_DIR=$(pwd)

  git_parse_params "$PARAM1" "$PARAM2" "$PARAM3" "$PARAM4"
  git_get_provider "${NOW_DIR}"
  git_get_url "${PROVIDER}" "${GIT_PWD}"
  git_check_project "${CMD}" "${APP}" "${MSG}" "${NOW_DIR}"

  case ${CMD} in
  cl | clone | rm | remove) ;;
  *)
    git_dir
    ;;
  esac
}

git_config() {
  COUNT=$(git config --list | wc -l | xargs)

  git config --global core.autocrlf input
  git config --global core.precomposeunicode true
  git config --global core.quotepath false
  git config --global pager.branch false
  git config --global pager.config false
  git config --global pager.tag false
  git config --global pull.ff only

  USERNAME=$(git config user.name)
  DEFAULT=${USERNAME:-"nalbam"}
  _read "Please input git user name [${DEFAULT}]: "
  USERNAME="${ANSWER:-${DEFAULT}}"

  git config --global user.name "${USERNAME}"

  USEREMAIL=$(git config user.email)
  DEFAULT=${USEREMAIL:-"me@nalbam.com"}
  _read "Please input git user email [${DEFAULT}]: "
  USEREMAIL="${ANSWER:-${DEFAULT}}"

  git config --global user.email "${USEREMAIL}"

  _command "git config --list"
  git config --list

  _success
}

git_dir() {
  cd ${NOW_DIR}/${PROJECT}

  # selected branch
  BRANCH=$(git branch | grep \* | xargs | cut -d' ' -f2)

  if [ -z ${BRANCH} ]; then
    BRANCH="main"
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

  # # https://github.com/awslabs/git-secrets

  # _command "git secrets --install"
  # git secrets --install

  # _command "git secrets --register-aws"
  # git secrets --register-aws

  _command "git branch -v"
  git branch -v
}

git_rm() {
  rm -rf ${NOW_DIR}/${PROJECT}
}

git_default() {
  DEFAULT=$(git branch -a | grep 'HEAD' | xargs | cut -d' ' -f3 | cut -d'/' -f2)

  if [ -z ${DEFAULT} ]; then
    DEFAULT="main"
  fi
}

git_remote() {
  _command "git remote -v"
  git remote -v

  if [ -z ${MSG} ]; then
    _error
  fi

  REMOTES=$(mktemp /tmp/${APP}-XXXXXX-remote)
  git remote >${REMOTES}

  while read VAR; do
    if [ "${VAR}" == "${MSG}" ]; then
      _error "Remote '${MSG}' already exists."
    fi
  done <${REMOTES}

  git_default

  _command "git remote add --track ${DEFAULT} ${MSG} ${GIT_URL}${MSG}/${APP}.git"
  git remote add --track ${DEFAULT} ${MSG} ${GIT_URL}${MSG}/${APP}.git

  _command "git remote -v"
  git remote -v
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
  BRANCHES=$(mktemp /tmp/${APP}-XXXXXX-branch)
  git branch -a >${BRANCHES}

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
  done <${BRANCHES}

  if [ "${HAS}" != "true" ]; then
    _command "git branch ${MSG} ${TAG}"
    git branch ${MSG} ${TAG}
  fi

  # _command "git checkout ${MSG}"
  # git checkout ${MSG}

  _command "git switch ${MSG}"
  git switch ${MSG}

  _command "git restore"
  git restore

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
  git remote >${REMOTES}

  _command "git pull origin ${BRANCH}"
  git pull origin ${BRANCH}

  while read REMOTE; do
    if [ "${REMOTE}" != "origin" ]; then
      _command "git pull ${REMOTE} ${BRANCH}"
      git pull ${REMOTE} ${BRANCH}
    fi
  done <${REMOTES}
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
  a | am)
    _am # iam
    ;;
  l | av)
    _av # aws-vault
    ;;
  c | cdw)
    _cdw # cd workspace
    ;;
  e | env)
    _env # aws profile
    ;;
  q | assume)
    _assume # aws assume role
    ;;
  r | region)
    _region # aws region
    ;;
  x | ctx)
    _ctx # kubectl context
    ;;
  z | ns)
    _ns # kubectl namespace
    ;;
  g | git)
    _git # git
    ;;
  s | ssh)
    _ssh # ssh
    ;;
  m | mtu)
    _mtu # mtu
    ;;
  b | stress)
    _stress # stress test
    ;;
  u | update)
    _update # toast update
    ;;
  t | tools)
    _tools # toast tools
    ;;
  v | version)
    _version # toast version
    ;;
  # r|reset)
  #   _reset
  #   ;;
  *)
    _usage
    ;;
  esac

  _save
}

_toast

_success
