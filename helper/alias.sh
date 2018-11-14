#!/bin/bash

alias e="~/.helper/env.sh"
alias n="~/.helper/nsh.sh"
alias s="~/.helper/ssh.sh"

alias v="~/.helper/code.sh"
alias v.="v ."

alias t="toaster"
alias tu="t update"
alias th="t helper"
alias tt="t tools"

alias vc="valve"

alias tm="tmux"
alias tmb='tmux new-session -d && tmux split-window -h && tmux split-window -v && tmux select-pane -L && tmux split-window -v && tmux select-pane -U && tmux attach-session -d'
alias tms='tmux new-session -d && tmux split-window -v && tmux split-window -v && tmux select-pane -U && tmux select-pane -U && tmux split-window -v && tmux select-pane -U && tmux attach-session -d'

alias tf="terraform"
alias tfp="tf init && tf plan"
alias tfa="tf init && tf apply -auto-approve"
alias tfd="tf init && tf destroy -auto-approve"
alias tff="tf fmt"
alias tfg="tf graph"
alias tfo="tf output"
alias tfc="rm -rf .terraform && tf init"

# alias p="reveal-md -w --port 8888 --theme https://raw.githubusercontent.com/nalbam/docs/master/.theme/black.css"

export GOPATH=$HOME/work
export PATH=$PATH:$GOPATH/bin

c() {
    ~/.helper/cdw.sh ${1}
    if [ -f /tmp/toaster-helper-cdw-result ]; then
        cd $(cat /tmp/toaster-helper-cdw-result)
    fi
}
