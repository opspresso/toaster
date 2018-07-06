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

OS_NAME="$(uname)"
OS_FULL="$(uname -a)"

if [ "${OS_NAME}" == "Linux" ]; then
    if [ $(echo "${OS_FULL}" | grep -c "amzn1") -gt 0 ]; then
        OS_TYPE="amzn"
    elif [ $(echo "${OS_FULL}" | grep -c "amzn2") -gt 0 ]; then
        OS_TYPE="amzn"
    elif [ $(echo "${OS_FULL}" | grep -c "el6") -gt 0 ]; then
        OS_TYPE="el6"
    elif [ $(echo "${OS_FULL}" | grep -c "el7") -gt 0 ]; then
        OS_TYPE="el7"
    elif [ $(echo "${OS_FULL}" | grep -c "Ubuntu") -gt 0 ]; then
        OS_TYPE="Ubuntu"
    elif [ $(echo "${OS_FULL}" | grep -c "coreos") -gt 0 ]; then
        OS_TYPE="coreos"
    fi
fi

if [ "${OS_TYPE}" == "" ]; then
    error "Not supported OS. [${OS_FULL}]"
fi

# localtime
sudo ln -sf "/usr/share/zoneinfo/Asia/Seoul" "/etc/localtime"
date

# version
DATE=
KUBECTL=
KOPS=
HELM=
DRAFT=
EKSCTL=
JX=
TF=
NODE=
JAVA=
MAVEN=
HEPTIO=

config=~/.bastion
if [ -f ${config} ]; then
  . ${config}
fi

# update
echo "================================================================================"
echo "# update... "

VERSION=$(date '+%Y-%m-%d %H')

if [ "${DATE}" != "${VERSION}" ]; then
    if [ "${OS_TYPE}" == "Ubuntu" ] || [ "${OS_TYPE}" == "coreos" ]; then
        sudo apt-get update
    elif [ "${OS_TYPE}" == "amzn" ] || [ "${OS_TYPE}" == "el6" ] || [ "${OS_TYPE}" == "el7" ]; then
        sudo yum update -y
    fi

    if [ "${OS_TYPE}" == "Ubuntu" ] || [ "${OS_TYPE}" == "coreos" ]; then
        sudo apt-get install -y git vim telnet jq make wget docker httpd python-pip
    elif [ "${OS_TYPE}" == "amzn" ] || [ "${OS_TYPE}" == "el6" ] || [ "${OS_TYPE}" == "el7" ]; then
        sudo yum install -y git vim telnet jq make wget docker httpd python-pip
    fi

    DATE=$(date '+%Y-%m-%d %H')
fi

# aws-cli
echo "================================================================================"
echo "# install aws-cli... "

pip install --upgrade --user awscli

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

VERSION=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)

if [ "${KUBECTL}" != "${VERSION}" ]; then
    wget https://storage.googleapis.com/kubernetes-release/release/${VERSION}/bin/linux/amd64/kubectl
    chmod +x kubectl && sudo mv kubectl /usr/local/bin/kubectl

    KUBECTL="${VERSION}"
fi

kubectl version --client --short

# kops
echo "================================================================================"
echo "# install kops... "

VERSION=$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | jq --raw-output '.tag_name')

if [ "${KOPS}" != "${VERSION}" ]; then
    wget https://github.com/kubernetes/kops/releases/download/${VERSION}/kops-linux-amd64
    chmod +x kops-linux-amd64 && sudo mv kops-linux-amd64 /usr/local/bin/kops

    KOPS="${VERSION}"
fi

kops version

# helm
echo "================================================================================"
echo "# install helm... "

VERSION=$(curl -s https://api.github.com/repos/kubernetes/helm/releases/latest | jq --raw-output '.tag_name')

if [ "${HELM}" != "${VERSION}" ]; then
    curl -L https://storage.googleapis.com/kubernetes-helm/helm-${VERSION}-linux-amd64.tar.gz | tar xz
    sudo mv linux-amd64/helm /usr/local/bin/helm && rm -rf linux-amd64

    HELM="${VERSION}"
fi

helm version --client --short

# draft
echo "================================================================================"
echo "# install draft... "

VERSION=$(curl -s https://api.github.com/repos/Azure/draft/releases/latest | jq --raw-output '.tag_name')

if [ "${DRAFT}" != "${VERSION}" ]; then
    curl -L https://azuredraft.blob.core.windows.net/draft/draft-${VERSION}-linux-amd64.tar.gz | tar xz
    sudo mv linux-amd64/draft /usr/local/bin/draft && rm -rf linux-amd64

    DRAFT="${VERSION}"
fi

draft version --short

# eksctl
#echo "================================================================================"
#echo "# install eksctl... "
#
#VERSION=$(curl -s https://api.github.com/repos/weaveworks/eksctl/releases/latest | jq --raw-output '.tag_name')
#
#if [ "${EKSCTL}" != "${VERSION}" ]; then
#    curl -L https://github.com/weaveworks/eksctl/releases/download/${VERSION}/eksctl_Linux_amd64.tar.gz | tar xz
#    chmod +x eksctl && sudo mv eksctl /usr/local/bin/eksctl
#
#    EKSCTL="${VERSION}"
#fi
#
#eksctl version

# jenkins-x
echo "================================================================================"
echo "# install jenkins-x... "

VERSION=$(curl -s https://api.github.com/repos/jenkins-x/jx/releases/latest | jq --raw-output '.tag_name')

if [ "${JX}" != "${VERSION}" ]; then
    curl -L https://github.com/jenkins-x/jx/releases/download/${VERSION}/jx-linux-amd64.tar.gz | tar xz
    sudo mv jx /usr/local/bin/jx

    JX="${VERSION}"
fi

jx --version

# terraform
echo "================================================================================"
echo "# install terraform... "

VERSION=$(curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | jq --raw-output '.tag_name' | cut -c 2-)

if [ "${TF}" != "${VERSION}" ]; then
    wget https://releases.hashicorp.com/terraform/${VERSION}/terraform_${VERSION}_linux_amd64.zip
    unzip terraform_${VERSION}_linux_amd64.zip && rm -rf terraform_${VERSION}_linux_amd64.zip
    sudo mv terraform /usr/local/bin/terraform

    TF="${VERSION}"
fi

terraform version

# nodejs
echo "================================================================================"
echo "# install nodejs... "

VERSION=10

if [ "${NODE}" != "${VERSION}" ]; then
    if [ "${OS_TYPE}" == "Ubuntu" ] || [ "${OS_TYPE}" == "coreos" ]; then
        curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -
        sudo apt-get install -y nodejs
    elif [ "${OS_TYPE}" == "amzn" ] || [ "${OS_TYPE}" == "el6" ] || [ "${OS_TYPE}" == "el7" ]; then
        curl -sL https://rpm.nodesource.com/setup_10.x | sudo bash -
        sudo yum install -y nodejs
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
    if [ "${OS_TYPE}" == "Ubuntu" ] || [ "${OS_TYPE}" == "coreos" ]; then
        sudo apt-get install -y openjdk-8-jdk
    elif [ "${OS_TYPE}" == "amzn" ] || [ "${OS_TYPE}" == "el6" ] || [ "${OS_TYPE}" == "el7" ]; then
        sudo yum remove -y java-1.7.0-openjdk
        sudo yum install -y java-1.8.0-openjdk java-1.8.0-openjdk-devel
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
    wget https://amazon-eks.s3-us-west-2.amazonaws.com/${VERSION}/2018-06-05/bin/linux/amd64/heptio-authenticator-aws
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
#echo "EKSCTL=\"${EKSCTL}\"" >> ${config}
echo "JX=\"${JX}\"" >> ${config}
echo "TF=\"${TF}\"" >> ${config}
echo "NODE=\"${NODE}\"" >> ${config}
echo "JAVA=\"${JAVA}\"" >> ${config}
echo "MAVEN=\"${MAVEN}\"" >> ${config}
echo "HEPTIO=\"${HEPTIO}\"" >> ${config}

cat ${config}

echo "# Done."
