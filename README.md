# toast.sh

[![build](https://img.shields.io/github/actions/workflow/status/opspresso/toast.sh/push.yml?branch=main&style=for-the-badge&logo=github)](https://github.com/opspresso/toast.sh/actions/workflows/push.yml)
[![release](https://img.shields.io/github/v/release/opspresso/toast.sh?style=for-the-badge&logo=github)](https://github.com/opspresso/toast.sh/releases)

## install

```bash
bash -c "$(curl -fsSL toast.sh/install)"
```

## usage

<!-- usage start -->

```
================================================================================
 _                  _         _
| |_ ___   __ _ ___| |_   ___| |__
| __/ _ \ / _' / __| __| / __| '_ \\
| || (_) | (_| \__ \ |_ _\__ \ | | |
 \__\___/ \__,_|___/\__(-)___/_| |_|
================================================================================
Usage: $(basename $0) {am|cdw|env|git|ssh|region|ssh|ctx|ns|update}
================================================================================
```

<!-- usage end -->

## aliases

```bash
alias t='toast'
alias tu='bash -c "$(curl -fsSL toast.sh/install)"'
alias tt='bash -c "$(curl -fsSL nalbam.github.io/dotfiles/run.sh)"'

c() {
  local dir="$(toast cdw $@)"
  if [ -n "$dir" ]; then
    echo "$dir"
    cd "$dir"
  fi
}

v() {
  local profile="$(toast av $@)"
  if [ -n "$profile" ]; then
    export AWS_VAULT= && aws-vault exec $profile --
  fi
}

alias m='toast am'
alias e='toast env'
alias n='toast git'
alias s='toast ssh'
alias r='toast region'
alias x='toast ctx'
alias z='toast ns'
```
