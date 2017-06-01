#!/bin/bash

function usage() {
    echo "Usage: $0 {name} {clone|remove|branch|tag|diff|commit|pull|push|pp}"
}

function yell() {
    case "${CMD}" in
        cl|clone)
            git_clone
            ;;
        rm|remove)
            rm_app_dir
            ;;
        b|branch)
            git_branch
            ;;
        t|tag)
            git_tag
            ;;
        d|diff)
            git_diff
            ;;
        c|commit)
            git_pull
            git_commit
            git_push
            ;;
        pl|pull)
            git_pull
            ;;
        ph|push)
            git_push
            ;;
        p|pp)
            git_pull
            git_push
            ;;
        *)
            usage
            ;;
    esac
}

function prepare() {
    if [ ! -d "${YEL_DIR}" ]; then
        mkdir "${YEL_DIR}"
    fi

    if [ -f "${CONFIG}" ]; then
        . "${CONFIG}"
    fi

    if [ "${APP}" == "" ]; then
        usage
        exit 1
    fi
    if [ "${CMD}" == "" ]; then
        usage
        exit 1
    fi
}

function get_cmd() {
    case "${CMD}" in
        cl|clone)
            if [ "${MSG}" == "" ]; then
                PROJECT="${APP}"
            else
                PROJECT="${MSG}"
            fi
            ;;
        *)
            PROJECT="${APP}"
            ;;
    esac

    BCH="${YEL_DIR}/${PROJECT}.bch"

    case "${CMD}" in
        cl|clone)
            if [ -d "${NOW_DIR}/${PROJECT}" ]; then
                echo "Source directory already exists."
                exit 1
            fi
            ch_now_dir
            rm_app_dir
            ;;
        *)
            if [ ! -d "${NOW_DIR}/${PROJECT}" ]; then
                echo "Source directory doesn't exists."
                exit 1
            fi
            ch_app_dir
        ;;
    esac
}

function get_provider() {
    if [ "${PROVIDER}" == "" ]; then
        echo "Please enter provider no."
        echo " 1. github.com"
        echo " 2. bitbucket.org"
        read PROVIDER

        if [ "${PROVIDER}" == "1" ]; then
            PROVIDER="github.com"
        elif [ "${PROVIDER}" == "2" ]; then
            PROVIDER="bitbucket.org"
        else
            echo "provider is empty."
            exit 1
        fi

        echo "PROVIDER=${PROVIDER}" >> "${CONFIG}"
    fi
}

function get_my_id() {
    if [ "${MY_ID}" == "" ]; then
        echo "Please enter your ${PROVIDER} account. [example:nalbam]"
        read MY_ID

        if [ "${MY_ID}" == "" ]; then
            echo "${PROVIDER} account is empty."
            exit 1
        fi

        echo "MY_ID=${MY_ID}" >> "${CONFIG}"
    fi
}

function get_up_id() {
    if [ "${UP_ID}" == "" ]; then
        echo "Please enter ${PROVIDER} upstream account. [default:${MY_ID}]"
        read UP_ID

        if [ "${UP_ID}" == "" ]; then
            UP_ID="${MY_ID}"
        fi

        echo "UP_ID=${UP_ID}" >> "${CONFIG}"
    fi
}

function ch_now_dir() {
    cd "${NOW_DIR}"
}

function ch_app_dir() {
    if [ ! -d "${NOW_DIR}/${PROJECT}" ]; then
        exit 1
    fi

    cd "${NOW_DIR}/${PROJECT}"

    if [ -f "${BCH}" ]; then
        read BRANCH < "${BCH}"
    fi

    if [ "${BRANCH}" == "" ]; then
        BRANCH="master"
    fi
}

function rm_app_dir() {
    rm -rf "${NOW_DIR}/${PROJECT}"
    rm -rf "${YEL_DIR}/${PROJECT}".*
}

function git_clone() {
    git clone "git@${PROVIDER}:${MY_ID}/${APP}.git" "${PROJECT}"

    if [ ! -d "${NOW_DIR}/${PROJECT}" ]; then
        exit 1
    fi

    ch_app_dir

    if [ "${MY_ID}" != "${UP_ID}" ]; then
        git remote add --track master upstream "git@${PROVIDER}:${UP_ID}/${APP}.git"
    fi

    git branch -v
}

function git_diff() {
    git branch -v
    git diff
}

function git_commit() {
    git branch -v
    git add --all
    git commit -m "${MSG}"
}

function git_pull() {
    git branch -v
    git pull origin "${BRANCH}"

    if [ "${MY_ID}" != "${UP_ID}" ]; then
        git pull upstream "${BRANCH}"
    fi
}

function git_push() {
    git branch -v
    git push origin "${BRANCH}"
}

function git_tag() {
    git pull
    git tag
}

function git_branch() {
    git branch -v

    if [ "${MSG}" == "" ]; then
        exit 1
    fi
    if [ "${MSG}" == "${BRANCH}" ]; then
        exit 1
    fi

    BRANCH="${MSG}"

    if [ "${TAG}" != "" ]; then
        if [ "${BRANCH}" != "${TAG}" ]; then
            git branch "${BRANCH}" "${TAG}"
        fi
    fi

    git checkout "${BRANCH}"
    echo "${BRANCH}" > "${BCH}"

    git branch -v
}

############################################################

APP=$(echo "$1" | sed -e "s/\///g")
CMD="$2"
MSG="$3"
TAG="$4"

PROJECT=""
BRANCH=""
BCH=""

NOW_DIR=$(pwd)
YEL_DIR="${NOW_DIR}/.yell"

CONFIG="${YEL_DIR}/config.sh"

PROVIDER=""
MY_ID=""
UP_ID=""

prepare

get_provider
get_my_id
get_up_id

get_cmd

yell

exit $?
