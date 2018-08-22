#!/bin/bash

# curl -sL toast.sh/install | bash

VERSION=$(curl -s https://api.github.com/repos/nalbam/toaster/releases/latest | grep tag_name | cut -d'"' -f4)

curl -sLO https://github.com/nalbam/toaster/releases/download/${VERSION}/toaster

chmod +x toaster

mv toaster /usr/local/bin/toaster
