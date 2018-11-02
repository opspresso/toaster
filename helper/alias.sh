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

alias tm="tmux"

alias vc="valve"

alias tf="terraform"
alias tfp="tf init && tf plan"
alias tfa="tf init && tf apply -auto-approve"
alias tfd="tf init && tf destroy -auto-approve"
alias tfg="tf graph"
alias tfo="tf output"
alias tfc="rm -rf .terraform && tf init"

alias vg="vagrant"
alias vgu="vg up"
alias vgh="vg halt"
alias vgd="vg destroy"

alias p="reveal-md -w --port 8888 --theme https://raw.githubusercontent.com/nalbam/docs/master/.theme/black.css"

c() {
    ~/.helper/cdw.sh ${1}
    if [ -f /tmp/toaster-helper-cdw-result ]; then
        cd $(cat /tmp/toaster-helper-cdw-result)
    fi
}
