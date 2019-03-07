#!/bin/bash

alias t="toaster"
alias tu="t update"
alias th="t helper"
alias tt="t tools"

c() {
    toaster cdw ${1}
    if [ -f /tmp/toaster-temp-result ]; then
        cd $(cat /tmp/toaster-temp-result)
    fi
}

alias e="toaster env"
alias n="toaster git"
alias s="toaster ssh"
alias x="toaster ctx"

alias v="toaster code"
alias v.="v ."

alias ku="kubectl"
alias he="helm"

alias va="valve"

alias tm="tmux"
alias tmb='tmux new-session -d && tmux split-window -h && tmux split-window -v && tmux select-pane -L && tmux split-window -v && tmux select-pane -U && tmux attach-session -d'
alias tms='tmux new-session -d && tmux split-window -v && tmux split-window -v && tmux select-pane -U && tmux select-pane -U && tmux split-window -v && tmux select-pane -U && tmux attach-session -d'

alias tf="terraform"
alias tfp="tf init && tf plan"
alias tfa="tf init && tf apply"
alias tfd="tf init && tf destroy"
alias tff="tf fmt"
alias tfg="tf graph"
alias tfo="tf output"
alias tfc="rm -rf .terraform && tf init"

# alias p="reveal-md -w --port 8888 --theme https://raw.githubusercontent.com/nalbam/docs/master/.theme/black.css"

export GOPATH=$HOME/work
export PATH=$PATH:$GOPATH/bin
