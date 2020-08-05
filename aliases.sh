#!/bin/bash

alias t='toaster'
alias tu='t update'
alias tt='t tools'

c() {
    toaster cdw ${1}
    if [ -f /tmp/toaster-temp-result ]; then
        cd $(cat /tmp/toaster-temp-result)
    fi
}

alias e='toaster env'
alias n='toaster git'
alias s='toaster ssh'
alias x='toaster ctx'
alias v='toaster vsc'

alias a='aws'
alias k='kubectl'
alias h='helm'

alias av='aws-vault'

alias tf='terraform'
alias tfp='tf init && tf plan'
alias tfa='tf init && tf apply'
alias tfd='tf init && tf destroy'
alias tff='tf fmt'
alias tfg='tf graph'
alias tfo='tf output'
alias tfc='rm -rf .terraform && tf init'

alias py='python'
alias py3='python3'

# alias p='reveal-md -w --port 8888 --theme https://raw.githubusercontent.com/nalbam/docs/master/.theme/black.css'
alias p='reveal-md -w --port 8888 --theme night'

alias chrome="/Applications/Google\\ \\Chrome.app/Contents/MacOS/Google\\ \\Chrome"

# export GOPATH=$HOME/work
# export PATH=$PATH:$GOPATH/bin
