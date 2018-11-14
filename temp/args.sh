#!/bin/bash

NAME=
VERSION=
NEMESPACE=

CHARTMUSEUM=

FORCE=
DELETE=
REMOTE=
VERVOSE=

# $@ is all command line parameters passed to the script.
# -o is for short options like -v
# -l is for long options with double dash like --version
# the comma separates different long options
# -a is for long options with single dash like -version
options=$(getopt -l "version:,namespace:,chartmuseum:,force,delete,remote,verbose" -o "v:n:c:fdrV" -a -- "$@")

# set --:
# If no arguments follow this option, then the positional parameters are unset. Otherwise, the positional parameters
# are set to the arguments, even if some of them begin with a ‘-’.
eval set -- "$options"

while true; do
    case $1 in
    -v|--version)
        shift
        export VERSION=$1
        ;;
    -n|--namespace)
        shift
        export NEMESPACE=$1
        ;;
    -c|--chartmuseum)
        shift
        export CHARTMUSEUM=$1
        ;;
    -f|--force)
        export FORCE=1
        ;;
    -d|--delete)
        export DELETE=1
        ;;
    -r|--remote)
        export REMOTE=1
        ;;
    -V|--verbose)
        export VERVOSE=1
        set -xv  # Set xtrace and verbose mode.
        ;;
    --)
        shift
        break
        ;;
    esac
    shift
done

echo "NAME=${1}"
echo "VERSION=${VERSION}"
echo "NEMESPACE=${NEMESPACE}"
echo "CHARTMUSEUM=${CHARTMUSEUM}"
echo "FORCE=${FORCE}"
echo "DELETE=${DELETE}"
echo "REMOTE=${REMOTE}"
echo "VERVOSE=${VERVOSE}"

echo "0=${0}"
echo "1=${1}"
echo "2=${2}"
echo "3=${3}"
echo "4=${4}"
