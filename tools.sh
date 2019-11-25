#!/bin/bash

# curl -sL toast.sh/tools | bash

REPO="toast.sh/pkgs"

# update
curl -sL ${REPO}/base | bash
# [ $? == 1 ] && exit 1

# awscli
curl -sL ${REPO}/awscli | bash

# terraform
curl -sL ${REPO}/terraform | bash

# kubectl
curl -sL ${REPO}/kubectl | bash

# helm
curl -sL ${REPO}/helm | bash

# nodejs
curl -sL ${REPO}/nodejs | bash

# # java
# curl -sL ${REPO}/java | bash -s "1.8.0"

# # maven
# curl -sL ${REPO}/maven | bash -s "3.5.4"

# aws-iam-authenticator
curl -sL ${REPO}/aws-iam-authenticator | bash -s "v0.3.0"

# clean
curl -sL ${REPO}/clean | bash
