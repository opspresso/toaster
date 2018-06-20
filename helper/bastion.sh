#!/bin/bash

echo "================================================================================"
echo "                  _          _               _   _              "
echo "  _ __ ___   __ _| | _____  | |__   __ _ ___| |_(_) ___  _ __   "
echo " | '_ ' _ \ / _' | |/ / _ \ | '_ \ / _' / __| __| |/ _ \| '_ \  "
echo " | | | | | | (_| |   <  __/ | |_) | (_| \__ \ |_| | (_) | | | | "
echo " |_| |_| |_|\__,_|_|\_\___| |_.__/ \__,_|___/\__|_|\___/|_| |_|  by nalbam "
echo "================================================================================"

# curl -sL toast.sh/helper/bastion.sh | bash

# update
echo "================================================================================"
echo "# update "
sudo yum update -y

# git, jq
echo "================================================================================"
echo "# install git vim jq "
sudo yum install -y git vim jq

# aws-cli
echo "================================================================================"
echo "# install awscli "
pip install --upgrade --user awscli
aws --version

# kubectl
echo "================================================================================"
echo "# install kubectl "
cat <<EOF > kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
sudo cp -rf kubernetes.repo /etc/yum.repos.d/kubernetes.repo
sudo yum install -y kubectl
kubectl version --client --short

# kops
echo "================================================================================"
echo "# install kops "
export VERSION=$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | jq --raw-output '.tag_name')
curl -sLO https://github.com/kubernetes/kops/releases/download/${VERSION}/kops-linux-amd64
chmod +x kops-linux-amd64 && sudo mv kops-linux-amd64 /usr/local/bin/kops
kops version

# helm
echo "================================================================================"
echo "# install helm "
export VERSION=$(curl -s https://api.github.com/repos/kubernetes/helm/releases/latest | jq --raw-output '.tag_name')
curl -sL https://storage.googleapis.com/kubernetes-helm/helm-${VERSION}-linux-amd64.tar.gz | tar xzv
sudo mv linux-amd64/helm /usr/local/bin/helm
helm version --client --short

# jenkins-x
echo "================================================================================"
echo "# install jenkins-x "
export VERSION=$(curl -s https://api.github.com/repos/jenkins-x/jx/releases/latest | jq --raw-output '.tag_name')
curl -sL https://github.com/jenkins-x/jx/releases/download/${VERSION}/jx-linux-amd64.tar.gz | tar xzv
sudo mv jx /usr/local/bin/jx
jx --version

# terraform
echo "================================================================================"
echo "# install terraform "
export VERSION=$(curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | jq --raw-output '.tag_name' | cut -c 2-)
curl -sLO https://releases.hashicorp.com/terraform/${VERSION}/terraform_${VERSION}_linux_amd64.zip
unzip terraform_${VERSION}_linux_amd64.zip
sudo mv terraform /usr/local/bin/terraform
terraform version
