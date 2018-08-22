#!/bin/bash

# curl -sL toast.sh/install | bash

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

################################################################################

VERSION=$(curl -s https://api.github.com/repos/nalbam/toaster/releases/latest | grep tag_name | cut -d'"' -f4)

_result "toaster version: ${VERSION}"

DIST=/tmp/toaster
rm -rf ${DIST}

# download
curl -sL -o ${DIST} https://github.com/nalbam/toaster/releases/download/${VERSION}/toaster
chmod +x ${DIST}
sudo mv ${DIST} /usr/local/bin/toaster

# done
_success "done."
