#!/bin/bash

USERNAME="opspresso"
REPONAME="toast.sh"

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

_install() {
  command -v toast > /dev/null && TOAST=true
  if [ "${TOAST}" != "" ]; then
    toast version
  fi

  if [ -z ${VERSION} ]; then
    VERSION=$(curl -s https://api.github.com/repos/$USERNAME/$REPONAME/releases/latest | grep tag_name | cut -d'"' -f4)

    if [ -z ${VERSION} ]; then
      VERSION=$(curl -fsSL toast.sh/VERSION | xargs)
    fi
  fi

  # _result "version: ${VERSION}"

  if [ -z ${VERSION} ]; then
    _error "Version not Found."
  fi

  # toast
  DIST=/tmp/toast-${VERSION}
  rm -rf ${DIST}

  # download
  curl -fsSL -o ${DIST} https://github.com/$USERNAME/$REPONAME/releases/download/$VERSION/toast
  chmod +x ${DIST}

  # copy path
  COPY_PATH=/usr/local/bin
  if [ ! -z "$HOME" ]; then
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

  if [ "${COPY_PATH}" == "/usr/local/bin" ]; then
    sudo mv -f ${DIST} ${COPY_PATH}/toast
    sudo chmod +x ${COPY_PATH}/toast
  else
    mkdir -p ${COPY_PATH}
    mv -f ${DIST} ${COPY_PATH}/toast
    chmod +x ${COPY_PATH}/toast
  fi

  toast version
}

################################################################################

_install
