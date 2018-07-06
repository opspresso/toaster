#!/bin/bash

VERSION=$(curl -sL toast.sh/toaster.txt)

#figlet bastion
echo "================================================================================"
echo "  _               _   _              "
echo " | |__   __ _ ___| |_(_) ___  _ __   "
echo " | '_ \ / _' / __| __| |/ _ \| '_ \  "
echo " | |_) | (_| \__ \ |_| | (_) | | | | "
echo " |_.__/ \__,_|___/\__|_|\___/|_| |_|  by nalbam (${VERSION}) "
echo "================================================================================"

# curl -sL toast.sh/helper/bastion.sh | bash

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
    elif [ $(echo "${OS_FULL}" | grep -c "ubuntu") -gt 0 ]; then
        OS_TYPE="apt"
    elif [ $(echo "${OS_FULL}" | grep -c "coreos") -gt 0 ]; then
        OS_TYPE="apt"
    fi
elif [ "${OS_NAME}" == "darwin" ]; then
    OS_TYPE="brew"
fi

if [ "${OS_TYPE}" == "" ]; then
    error "Not supported OS. [${OS_FULL}]"
fi

# version
DATE=
KUBECTL=
KOPS=
HELM=
DRAFT=
JENKINS_X=
TERRAFORM=
NODE=
JAVA=
MAVEN=
HEPTIO=

config=~/.bastion
if [ -f ${config} ]; then
  . ${config}
fi

# brew for mac
if [ "${OS_TYPE}" == "brew" ]; then
    command -v brew > /dev/null || ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# update
echo "================================================================================"
echo "# update... "

VERSION=$(date '+%Y-%m-%d %H')

if [ "${DATE}" != "${VERSION}" ]; then
    if [ "${OS_TYPE}" == "apt" ]; then
        sudo apt update
    elif [ "${OS_TYPE}" == "yum" ]; then
        sudo yum update -y
    elif [ "${OS_TYPE}" == "brew" ]; then
        brew update && brew upgrade
    fi

    if [ "${OS_TYPE}" == "apt" ]; then
        sudo apt install -y git vim telnet jq make wget docker httpd python-pip
    elif [ "${OS_TYPE}" == "yum" ]; then
        sudo yum install -y git vim telnet jq make wget docker httpd python-pip
    elif [ "${OS_TYPE}" == "brew" ]; then
        command -v jq > /dev/null || brew install jq
        command -v git > /dev/null || brew install git
        command -v vim > /dev/null || brew install vim
        command -v make > /dev/null || brew install make
        command -v wget > /dev/null || brew install wget
        command -v docker > /dev/null || brew install docker
        command -v telnet > /dev/null || brew install telnet
    fi

    DATE="${VERSION}"
fi

# aws-cli
echo "================================================================================"
echo "# install aws-cli... "

if [ "${OS_TYPE}" == "brew" ]; then
    command -v aws > /dev/null || brew install awscli
else
    pip install --upgrade --user awscli
fi

aws --version

if [ ! -f ~/.aws/credentials ]; then
    # aws region
    aws configure set default.region ap-northeast-2

    # aws credentials
    echo "[default]" > ~/.aws/credentials
    echo "aws_access_key_id=" >> ~/.aws/credentials
    echo "aws_secret_access_key=" >> ~/.aws/credentials
fi

# kubectl
echo "================================================================================"
echo "# install kubectl... "

if [ "${OS_TYPE}" == "brew" ]; then
    command -v kubectl > /dev/null || brew install kubernetes-cli
else
    VERSION=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)

    if [ "${KUBECTL}" != "${VERSION}" ]; then
        wget https://storage.googleapis.com/kubernetes-release/release/${VERSION}/bin/${OS_NAME}/amd64/kubectl
        chmod +x kubectl && sudo mv kubectl /usr/local/bin/kubectl

        KUBECTL="${VERSION}"
    fi
fi

kubectl version --client --short

# kops
echo "================================================================================"
echo "# install kops... "

if [ "${OS_TYPE}" == "brew" ]; then
    command -v kops > /dev/null || brew install kops
else
    VERSION=$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | jq --raw-output '.tag_name')

    if [ "${KOPS}" != "${VERSION}" ]; then
        wget https://github.com/kubernetes/kops/releases/download/${VERSION}/kops-${OS_NAME}-amd64
        chmod +x kops-${OS_NAME}-amd64 && sudo mv kops-${OS_NAME}-amd64 /usr/local/bin/kops

        KOPS="${VERSION}"
    fi
fi

kops version

# helm
echo "================================================================================"
echo "# install helm... "

if [ "${OS_TYPE}" == "brew" ]; then
    command -v helm > /dev/null || brew install kubernetes-helm
else
    VERSION=$(curl -s https://api.github.com/repos/kubernetes/helm/releases/latest | jq --raw-output '.tag_name')

    if [ "${HELM}" != "${VERSION}" ]; then
        curl -L https://storage.googleapis.com/kubernetes-helm/helm-${VERSION}-${OS_NAME}-amd64.tar.gz | tar xz
        sudo mv ${OS_NAME}-amd64/helm /usr/local/bin/helm && rm -rf ${OS_NAME}-amd64

        HELM="${VERSION}"
    fi
fi

helm version --client --short

# draft
echo "================================================================================"
echo "# install draft... "

#if [ "${OS_TYPE}" == "brew" ]; then
#    command -v draft > /dev/null || brew install draft
#else
    VERSION=$(curl -s https://api.github.com/repos/Azure/draft/releases/latest | jq --raw-output '.tag_name')

    if [ "${DRAFT}" != "${VERSION}" ]; then
        curl -L https://azuredraft.blob.core.windows.net/draft/draft-${VERSION}-${OS_NAME}-amd64.tar.gz | tar xz
        sudo mv ${OS_NAME}-amd64/draft /usr/local/bin/draft && rm -rf ${OS_NAME}-amd64

        DRAFT="${VERSION}"
    fi
#fi

draft version --short

# jenkins-x
echo "================================================================================"
echo "# install jenkins-x... "

if [ "${OS_TYPE}" == "brew" ]; then
    command -v jx > /dev/null || brew install jx
else
    VERSION=$(curl -s https://api.github.com/repos/jenkins-x/jx/releases/latest | jq --raw-output '.tag_name')

    if [ "${JENKINS_X}" != "${VERSION}" ]; then
        curl -L https://github.com/jenkins-x/jx/releases/download/${VERSION}/jx-${OS_NAME}-amd64.tar.gz | tar xz
        sudo mv jx /usr/local/bin/jx

        JENKINS_X="${VERSION}"
    fi
fi

jx --version

# terraform
echo "================================================================================"
echo "# install terraform... "

if [ "${OS_TYPE}" == "brew" ]; then
    command -v terraform > /dev/null || brew install terraform
else
    VERSION=$(curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | jq --raw-output '.tag_name' | cut -c 2-)

    if [ "${TERRAFORM}" != "${VERSION}" ]; then
        wget https://releases.hashicorp.com/terraform/${VERSION}/terraform_${VERSION}_${OS_NAME}_amd64.zip
        unzip terraform_${VERSION}_${OS_NAME}_amd64.zip && rm -rf terraform_${VERSION}_${OS_NAME}_amd64.zip
        sudo mv terraform /usr/local/bin/terraform

        TERRAFORM="${VERSION}"
    fi
fi

terraform version

# nodejs
echo "================================================================================"
echo "# install nodejs... "

VERSION=10

if [ "${NODE}" != "${VERSION}" ]; then
    if [ "${OS_TYPE}" == "apt" ]; then
        curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -
        sudo apt-get install -y nodejs
    elif [ "${OS_TYPE}" == "yum" ]; then
        curl -sL https://rpm.nodesource.com/setup_10.x | sudo bash -
        sudo yum install -y nodejs
    elif [ "${OS_TYPE}" == "brew" ]; then
        command -v node > /dev/null || brew install node
    fi

    NODE="${VERSION}"
fi

echo "node $(node -v)"
echo "npm $(npm -v)"

# java
echo "================================================================================"
echo "# install java... "

VERSION=1.8.0

if [ "${JAVA}" != "${VERSION}" ]; then
    if [ "${OS_TYPE}" == "apt" ]; then
        sudo apt-get install -y openjdk-8-jdk
    elif [ "${OS_TYPE}" == "yum" ]; then
        sudo yum remove -y java-1.7.0-openjdk
        sudo yum install -y java-1.8.0-openjdk java-1.8.0-openjdk-devel
    elif [ "${OS_TYPE}" == "brew" ]; then
        command -v java > /dev/null || brew cask install java
    fi

    JAVA="${VERSION}"
fi

java -version

# maven
echo "================================================================================"
echo "# install maven... "

VERSION=3.5.3

if [ "${MAVEN}" != "${VERSION}" ]; then
    if [ ! -d /usr/local/apache-maven-${VERSION} ]; then
      curl -L https://www.apache.org/dist/maven/maven-3/${VERSION}/binaries/apache-maven-${VERSION}-bin.tar.gz | tar xz
      sudo mv -f apache-maven-${VERSION} /usr/local/
      sudo ln -sf /usr/local/apache-maven-${VERSION}/bin/mvn /usr/local/bin/mvn
    fi

    MAVEN="${VERSION}"
fi

mvn -version

# heptio
echo "================================================================================"
echo "# install heptio... "

VERSION=1.10.3

if [ "${HEPTIO}" != "${VERSION}" ]; then
    wget https://amazon-eks.s3-us-west-2.amazonaws.com/${VERSION}/2018-06-05/bin/${OS_NAME}/amd64/heptio-authenticator-aws
    chmod +x heptio-authenticator-aws && sudo mv heptio-authenticator-aws /usr/local/bin/heptio-authenticator-aws

    HEPTIO="${VERSION}"
fi

echo "${VERSION}"

echo "================================================================================"

echo "# bastion" > ${config}
echo "DATE=\"${DATE}\"" >> ${config}
echo "KUBECTL=\"${KUBECTL}\"" >> ${config}
echo "KOPS=\"${KOPS}\"" >> ${config}
echo "HELM=\"${HELM}\"" >> ${config}
echo "DRAFT=\"${DRAFT}\"" >> ${config}
echo "JENKINS_X=\"${JENKINS_X}\"" >> ${config}
echo "TERRAFORM=\"${TERRAFORM}\"" >> ${config}
echo "NODE=\"${NODE}\"" >> ${config}
echo "JAVA=\"${JAVA}\"" >> ${config}
echo "MAVEN=\"${MAVEN}\"" >> ${config}
echo "HEPTIO=\"${HEPTIO}\"" >> ${config}

echo "# Done."
