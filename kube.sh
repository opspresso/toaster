#!/bin/bash

# version
DATE=
KUBECTL=

CONFIG=~/.tools
touch ${CONFIG} && . ${CONFIG}

################################################################################

command -v tput > /dev/null || TPUT=false

_echo() {
    if [ -z ${TPUT} ] && [ ! -z $2 ]; then
        echo -e "$(tput setaf $2)$1$(tput sgr0)"
    else
        echo -e "$1"
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

DATE=$(date '+%Y-%m-%d %H:%M:%S')

OS_NAME="$(uname | awk '{print tolower($0)}')"
OS_FULL="$(uname -a)"
OS_TYPE=

if [ "${OS_NAME}" == "linux" ]; then
    if [ $(echo "${OS_FULL}" | grep -c "amzn1") -gt 0 ]; then
        OS_TYPE="yum"
    elif [ $(echo "${OS_FULL}" | grep -c "amzn2") -gt 0 ]; then
        OS_TYPE="yum"
    elif [ $(echo "${OS_FULL}" | grep -c "el6") -gt 0 ]; then
        OS_TYPE="yum"
    elif [ $(echo "${OS_FULL}" | grep -c "el7") -gt 0 ]; then
        OS_TYPE="yum"
    elif [ $(echo "${OS_FULL}" | grep -c "Ubuntu") -gt 0 ]; then
        OS_TYPE="apt"
    elif [ $(echo "${OS_FULL}" | grep -c "coreos") -gt 0 ]; then
        OS_TYPE="apt"
    fi
elif [ "${OS_NAME}" == "darwin" ]; then
    OS_TYPE="brew"
fi

_result "${OS_FULL}"
_result "${DATE}"

if [ "${OS_TYPE}" == "" ]; then
    _error "Not supported OS. [${OS_NAME}]"
fi

# brew for mac
if [ "${OS_TYPE}" == "brew" ]; then
    command -v brew > /dev/null || ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# for ubuntu
if [ "${OS_TYPE}" == "apt" ]; then
    export LC_ALL=C
fi

# update
echo "================================================================================"
_result "update..."

if [ "${OS_TYPE}" == "apt" ]; then
    sudo apt update && sudo apt upgrade -y
    command -v jq > /dev/null || sudo apt install -y jq
    command -v git > /dev/null || sudo apt install -y git
    command -v docker > /dev/null || sudo apt install -y docker
    command -v pip > /dev/null || sudo apt install -y python-pip
elif [ "${OS_TYPE}" == "yum" ]; then
    sudo yum update -y
    command -v jq > /dev/null || sudo yum install -y jq
    command -v git > /dev/null || sudo yum install -y git
    command -v docker > /dev/null || sudo yum install -y docker
    command -v pip > /dev/null || sudo yum install -y python-pip
elif [ "${OS_TYPE}" == "brew" ]; then
    brew update && brew upgrade
    command -v jq > /dev/null || brew install jq
    command -v git > /dev/null || brew install git
fi

# kubectl
echo "================================================================================"
_result "install kubectl, kubeadm, kubelet..."

if [ "${OS_TYPE}" == "brew" ]; then
    command -v kubectl > /dev/null || brew install kubernetes-cli
else
    VERSION=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)

    if [ "${KUBECTL}" != "${VERSION}" ] || [ "$(command -v kubectl)" == "" ]; then
        _result " ${KUBECTL} >> ${VERSION}"

        curl -LO https://storage.googleapis.com/kubernetes-release/release/${VERSION}/bin/${OS_NAME}/amd64/kubectl
        chmod +x kubectl && sudo mv kubectl /usr/local/bin/kubectl

        curl -LO https://storage.googleapis.com/kubernetes-release/release/${VERSION}/bin/${OS_NAME}/amd64/kubeadm
        chmod +x kubeadm && sudo mv kubeadm /usr/local/bin/kubeadm

        curl -LO https://storage.googleapis.com/kubernetes-release/release/${VERSION}/bin/${OS_NAME}/amd64/kubelet
        chmod +x kubelet && sudo mv kubelet /usr/local/bin/kubelet

        KUBECTL="${VERSION}"
    fi
fi

kubectl version --client --short | xargs | awk '{print $3}'

# clean
echo "================================================================================"
_result "clean all..."

if [ "${OS_TYPE}" == "apt" ]; then
    sudo apt clean all
    sudo apt autoremove -y
elif [ "${OS_TYPE}" == "yum" ]; then
    sudo yum clean all
elif [ "${OS_TYPE}" == "brew" ]; then
    brew cleanup
fi

echo "================================================================================"

_success "done."
