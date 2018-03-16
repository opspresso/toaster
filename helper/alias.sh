#!/bin/bash

alias e="~/toaster/helper/env.sh"
alias n="~/toaster/helper/nsh.sh"
alias s="~/toaster/helper/ssh.sh"

alias t="~/toaster/toast.sh"
alias ta="t auto"
alias tu="t update"
alias td="t deploy"

alias tf="terraform"
alias tfp="tf plan -var-file=sample.tfvars"
alias tfa="tf plan -out=terraform.tfplan && tf apply -input=false terraform.tfplan"
alias tfg="tf graph"
alias tfd="tf destroy -force"
alias tfc="rm -rf .terraform && tf init"

alias vg="vagrant"
alias vgu="vg up"
alias vgh="vg halt"
alias vgd="vg destroy"
