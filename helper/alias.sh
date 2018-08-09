#!/bin/bash

#alias c="~/toaster/helper/cdw.sh"
alias e="~/toaster/helper/env.sh"
alias n="~/toaster/helper/nsh.sh"
alias s="~/toaster/helper/ssh.sh"

alias v="~/toaster/helper/vscode.sh"
alias v.="~/toaster/helper/vscode.sh ."

alias t="~/toaster/toast.sh"
alias tu="t update"
alias tb="t bastion"

alias st="/Applications/Sublime\ Text.app/Contents/SharedSupport/bin/subl"
alias vs="/Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin/code"

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
    ~/toaster/helper/cdw.sh
    DIR=$(cat /tmp/cdw.result)
    if [ ! -z ${DIR} ]; then
        cd ${DIR}
    fi
}
