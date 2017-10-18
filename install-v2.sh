#!/bin/bash

success() {
    echo -e "$(tput setaf 2)$1$(tput sgr0)"
}

warning() {
    echo -e "$(tput setaf 1)$1$(tput sgr0)"
}

################################################################################

REPO="http://toast.sh"

################################################################################

if [ ! -d ~/toaster ]; then
    mkdir ~/toaster
fi

# version
curl -s -o /tmp/toaster.new ${REPO}/toaster.txt

if [ ! -f /tmp/toaster.new ]; then
    warning "Can not download. [version]"
    exit 1
fi

if [ -f /tmp/toaster.old ]; then
    NEW="$(cat /tmp/toaster.new)"
    OLD="$(cat /tmp/toaster.old)"

    if [ "${NEW}" == "${OLD}" ]; then
        success "Already have latest version. [${OLD}]"
        exit 0
    fi

    MSG="Latest version updated. [${OLD} -> ${NEW}]"
else
    MSG="Toast.sh installed."
fi

# download
curl -s -o /tmp/toaster.tar.gz ${REPO}/toaster-v2.tar.gz

if [ ! -f /tmp/toaster.tar.gz ]; then
    warning "Can not download. [toast.sh]"
    exit 1
fi

# install
tar -zxf /tmp/toaster.tar.gz -C ~/toaster

# cp version
cp -rf /tmp/toaster.new /tmp/toaster.old

# done
success "${MSG}"
