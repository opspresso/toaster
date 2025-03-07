# toast.sh

[![build](https://img.shields.io/github/actions/workflow/status/opspresso/toast.sh/push.yml?branch=main&style=for-the-badge&logo=github)](https://github.com/opspresso/toast.sh/actions/workflows/push.yml)
[![release](https://img.shields.io/github/v/release/opspresso/toast.sh?style=for-the-badge&logo=github)](https://github.com/opspresso/toast.sh/releases)

toast.sh is a shell script utility that simplifies the use of CLI tools for AWS, Kubernetes, Git, and more.

## Key Features

* AWS Features
  - AWS Profile Management (`toast env`)
  - AWS Region Management (`toast region`)
  - IAM Role Switching (`toast assume`)
  - AWS Vault Support (`toast av`)

* Kubernetes Features
  - Context Switching (`toast ctx`)
  - Namespace Switching (`toast ns`)

* Git Features
  - Repository Cloning (`toast git clone`)
  - Branch Management (`toast git branch`)
  - Tag Management (`toast git tag`)
  - Remote Repository Management (`toast git remote`)

* Other Utilities
  - SSH Connection Management (`toast ssh`)
  - MTU Configuration (`toast mtu`)
  - Stress Testing (`toast stress`)

## Installation

```bash
bash -c "$(curl -fsSL toast.sh/install)"
```

## Usage

```
================================================================================
 _                  _         _
| |_ ___   __ _ ___| |_   ___| |__
| __/ _ \ / _' / __| __| / __| '_ \\
| || (_) | (_| \__ \ |_ _\__ \ | | |
 \__\___/ \__,_|___/\__(-)___/_| |_|
================================================================================
Usage: toast {am|cdw|env|git|ssh|region|ssh|ctx|ns|update}
================================================================================
```

## Aliases

```bash
alias t='toast'
alias tu='bash -c "$(curl -fsSL toast.sh/install)"'
alias tt='bash -c "$(curl -fsSL nalbam.github.io/dotfiles/run.sh)"'

# Directory Navigation
c() {
  local dir="$(toast cdw $@)"
  if [ -n "$dir" ]; then
    echo "$dir"
    cd "$dir"
  fi
}

# AWS Vault Execution
v() {
  local profile="$(toast av $@)"
  if [ -n "$profile" ]; then
    export AWS_VAULT= && aws-vault exec $profile --
  fi
}

# Common Command Aliases
alias m='toast am'      # Check AWS IAM info
alias e='toast env'     # Set AWS profile
alias n='toast git'     # Git commands
alias s='toast ssh'     # SSH connection
alias r='toast region'  # Change AWS region
alias x='toast ctx'     # Switch Kubernetes context
alias z='toast ns'      # Switch Kubernetes namespace
```

## License

This project is licensed under the [GNU General Public License v3.0](LICENSE).

## Contributing

Bug reports, feature requests, and pull requests are welcome through the GitHub repository.
