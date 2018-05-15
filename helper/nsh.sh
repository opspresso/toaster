#!/bin/bash

success() {
    echo -e "$(tput setaf 2)$1$(tput sgr0)"
    exit 0
}

error() {
    echo -e "$(tput setaf 1)$1$(tput sgr0)"
    exit 1
}

usage() {
    if [ -r /tmp/toaster.old ]; then
        VER="$(cat /tmp/toaster.old)"
    else
        VER="v3"
    fi

    #figlet nsh
    echo "================================================================================"
    echo "            _ "
    echo "  _ __  ___| |__ "
    echo " | '_ \/ __| '_ \ "
    echo " | | | \__ \ | | | "
    echo " |_| |_|___/_| |_|  by nalbam (${VER}) "
    echo "================================================================================"
    echo " Usage: nsh.sh {name} {clone|remove|branch|tag|diff|commit|pull|push|pp}"
    echo "================================================================================"

    exit 1
}

################################################################################

APP=$(echo "$1" | sed -e "s/\///g")
CMD="$2"
MSG="$3"
TAG="$4"

PROJECT=""
BRANCH=""

NOW_DIR=$(pwd)

PROVIDER=""
MY_ID=""

################################################################################

nsh() {
    case "${CMD}" in
        cl|clone)
            git_clone
            ;;
        r|remote)
            git_remote
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
        p|pp)
            git_pull
            git_push
            ;;
        pl|pull)
            git_pull
            ;;
        ph|push)
            git_push
            ;;
        rm|remove)
            rm_app_dir
            ;;
        *)
            usage
            ;;
    esac
}

################################################################################

prepare() {
    if [ "${APP}" == "" ]; then
        usage
    fi
    if [ "${CMD}" == "" ]; then
        usage
    fi

    LIST=$(echo ${NOW_DIR} | tr "/" " ")
    DETECT=false

    for V in ${LIST}; do
        if [ "${DETECT}" == "true" ]; then
            if [ "${PROVIDER}" == "" ]; then
                PROVIDER="${V}"
            elif [ "${MY_ID}" == "" ]; then
                MY_ID="${V}"
            fi
        elif [ "${V}" == "src" ]; then
            DETECT=true
        fi
    done
}

get_cmd() {
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

    case "${CMD}" in
        cl|clone)
            if [ -d "${NOW_DIR}/${PROJECT}" ]; then
                error "Source directory already exists."
            fi
            ch_now_dir
            rm_app_dir
            ;;
        *)
            if [ ! -d "${NOW_DIR}/${PROJECT}" ]; then
                error "Source directory doesn't exists."
            fi
            ch_app_dir
        ;;
    esac
}

ch_now_dir() {
    cd "${NOW_DIR}"
}

ch_app_dir() {
    if [ ! -d "${NOW_DIR}/${PROJECT}" ]; then
        error "Not set project."
    fi

    cd "${NOW_DIR}/${PROJECT}"

    BRANCH=$(git branch | grep \* | cut -d' ' -f2)

    if [ "${BRANCH}" == "" ]; then
        BRANCH="master"
    fi

    echo "# ${BRANCH}"
}

rm_app_dir() {
    rm -rf "${NOW_DIR}/${PROJECT}"
}

git_clone() {
    git clone "git@${PROVIDER}:${MY_ID}/${APP}.git" "${PROJECT}"

    if [ ! -d "${NOW_DIR}/${PROJECT}" ]; then
        error "Not set project."
    fi

    ch_app_dir

    # https://github.com/awslabs/git-secrets
    git secrets --install
    git secrets --register-aws

    git branch -v
}

git_remote() {
    git branch -v

    REMOTES="/tmp/${APP}-remote"
    git remote > ${REMOTES}

    while read REMOTE; do
        if [ "${REMOTE}" == "${MSG}" ]; then
            error "Remote ${MSG} already exists."
        fi
    done < ${REMOTES}

    git remote add --track master ${MSG} "git@${PROVIDER}:${MSG}/${APP}.git"
    git remote
}

git_diff() {
    git branch -v
    git diff
}

git_commit() {
    git branch -v
    git add --all
    git commit -m "${MSG}"
}

git_pull() {
    git branch -v

    REMOTES="/tmp/${APP}-remote"
    git remote > ${REMOTES}

    git pull origin ${BRANCH}

    while read REMOTE; do
        if [ "${REMOTE}" != "origin" ]; then
            git pull ${REMOTE} ${BRANCH}
        fi
    done < ${REMOTES}
}

git_push() {
    git branch -v
    git push origin ${BRANCH}
}

git_tag() {
    git branch -v
    git pull
    git tag
}

git_branch() {
    git branch -v

    if [ "${MSG}" != "" ]; then
        return
    fi
    if [ "${MSG}" == "${BRANCH}" ]; then
        error "Already on '${BRANCH}'."
    fi

    if [ "${MSG}" != "${TAG}" ]; then
        git branch "${MSG}" "${TAG}"
    fi

    git checkout "${MSG}"

    git branch -v
}

################################################################################

prepare

get_cmd

nsh
