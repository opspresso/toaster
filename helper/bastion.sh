#!/bin/bash

VERSION=$(curl -sL toast.sh/toaster.txt)

echo "================================================================================"
echo "  _               _   _              "
echo " | |__   __ _ ___| |_(_) ___  _ __   "
echo " | '_ \ / _' / __| __| |/ _ \| '_ \  "
echo " | |_) | (_| \__ \ |_| | (_) | | | | "
echo " |_.__/ \__,_|___/\__|_|\___/|_| |_|  by nalbam (${VERSION}) "
echo "================================================================================"

# curl -sL toast.sh/helper/bastion.sh | bash

# Date
sudo rm -rf "/etc/localtime"
sudo ln -sf "/usr/share/zoneinfo/Asia/Seoul" "/etc/localtime"
date

# update
echo "================================================================================"
echo "# update... "
sudo yum update -y

# tools
echo "================================================================================"
echo "# install tools... "
sudo yum install -y git vim telnet jq gcc-c++ make

# aws-cli
echo "================================================================================"
echo "# install awscli... "
pip install --upgrade --user awscli
aws --version

# aws region
aws configure set default.region ap-northeast-2

# aws credentials
cat <<EOF > ~/.aws/credentials
[default]
aws_access_key_id=
aws_secret_access_key=
EOF

# kubectl
echo "================================================================================"
echo "# install kubectl... "
cat <<EOF > kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
sudo mv kubernetes.repo /etc/yum.repos.d/kubernetes.repo
sudo yum install -y kubectl
kubectl version --client --short

# kops
echo "================================================================================"
echo "# install kops... "
export VERSION=$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | jq --raw-output '.tag_name')
curl -sLO https://github.com/kubernetes/kops/releases/download/${VERSION}/kops-linux-amd64
chmod +x kops-linux-amd64 && sudo mv kops-linux-amd64 /usr/local/bin/kops
kops version

# helm
echo "================================================================================"
echo "# install helm... "
export VERSION=$(curl -s https://api.github.com/repos/kubernetes/helm/releases/latest | jq --raw-output '.tag_name')
curl -sL https://storage.googleapis.com/kubernetes-helm/helm-${VERSION}-linux-amd64.tar.gz | tar xz
sudo mv linux-amd64/helm /usr/local/bin/helm
helm version --client --short

# jenkins-x
echo "================================================================================"
echo "# install jenkins-x... "
export VERSION=$(curl -s https://api.github.com/repos/jenkins-x/jx/releases/latest | jq --raw-output '.tag_name')
curl -sL https://github.com/jenkins-x/jx/releases/download/${VERSION}/jx-linux-amd64.tar.gz | tar xz
sudo mv jx /usr/local/bin/jx
jx --version

# terraform
echo "================================================================================"
echo "# install terraform... "
export VERSION=$(curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | jq --raw-output '.tag_name' | cut -c 2-)
curl -sLO https://releases.hashicorp.com/terraform/${VERSION}/terraform_${VERSION}_linux_amd64.zip
unzip terraform_${VERSION}_linux_amd64.zip && rm -rf terraform_${VERSION}_linux_amd64.zip
sudo mv terraform /usr/local/bin/terraform
terraform version

# java
echo "================================================================================"
echo "# install java... "
sudo yum remove -y java-1.7.0-openjdk java-1.7.0-openjdk-devel
sudo yum install -y java-1.8.0-openjdk java-1.8.0-openjdk-devel
java -version

# maven
echo "================================================================================"
echo "# install maven... "
export VERSION=3.5.3
curl -sL https://www.apache.org/dist/maven/maven-3/${VERSION}/binaries/apache-maven-${VERSION}-bin.tar.gz | tar xz
sudo mv apache-maven-${VERSION} /usr/local/
sudo ln -sf /usr/local/apache-maven-${VERSION}/bin/mvn /usr/local/bin/mvn
mvn -version

# nodejs
echo "================================================================================"
echo "# install nodejs... "
curl --silent --location https://rpm.nodesource.com/setup_10.x | sudo bash -
sudo yum install -y nodejs
echo "node $(node -v)"
echo "npm $(npm -v)"

echo "================================================================================"
echo "# Done. "
