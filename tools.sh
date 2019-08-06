#!/bin/bash

# curl -sL toast.sh/tools | bash

REPO="opspresso.com/tools"

# update
curl -sL ${REPO}/base | bash
[ $? == 1 ] && exit 1

# awscli
curl -sL ${REPO}/awscli | bash

# kubectl
curl -sL ${REPO}/kubectl | bash

# helm
curl -sL ${REPO}/helm | bash

# # kops
# curl -sL ${REPO}/kops | bash

# # draft
# curl -sL ${REPO}/draft | bash

# terraform
curl -sL ${REPO}/terraform | bash

# nodejs
curl -sL ${REPO}/nodejs | bash -s "10"

# # java
# curl -sL ${REPO}/java | bash -s "1.8.0"

# # maven
# curl -sL ${REPO}/maven | bash -s "3.5.4"

# aws-iam-authenticator
curl -sL ${REPO}/aws-iam-authenticator | bash -s "0.3.0"

# clean
curl -sL ${REPO}/clean | bash
