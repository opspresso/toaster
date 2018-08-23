#!/bin/bash

SHELL_DIR=${HOME}/helper

APP=$(echo "$1" | sed -e "s/\///g")
CMD="$2"
MSG="$3"
TAG="$4"
ALL="$*"

PROJECT=""
BRANCH=""

NOW_DIR=$(pwd)

PROVIDER=""
MY_ID=""

GIT_URL=""
GIT_PWD=""

################################################################################

command -v tput > /dev/null || TPUT=false

_echo() {
    if [ -z ${TPUT} ] && [ ! -z $2 ]; then
        echo -e "$(tput setaf $2)$1$(tput sgr0)"
    else
        echo -e "$1"
    fi
}

_read() {
    if [ -z ${TPUT} ]; then
        read -p "$(tput setaf 6)$1$(tput sgr0)" ANSWER
    else
        read -p "$1" ANSWER
    fi
}

_result() {
    _echo "# $@" 4
}

_command() {
    _echo "$ $@" 3
}

_success() {
    _echo "+ $@" 2
    exit 0
}

_error() {
    _echo "- $@" 1
    exit 1
}

usage() {
    #figlet nsh
    echo "================================================================================"
    echo "            _ "
    echo "  _ __  ___| |__ "
    echo " | '_ \/ __| '_ \ "
    echo " | | | \__ \ | | | "
    echo " |_| |_|___/_| |_| "
    echo "================================================================================"
    echo " Usage: nsh.sh {name} {clone|remove|branch|tag|diff|commit|pull|push|pp}"
    echo " [${NOW_DIR}]"
    echo " [${PROVIDER}][${GIT_URL}][${MY_ID}][${APP}]"
    echo "================================================================================"

    exit 1
}

################################################################################

nsh() {
    case ${CMD} in
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
            git_commit ${ALL}
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
    LIST=$(echo ${NOW_DIR} | tr "/" " ")
    DETECT=false

    for V in ${LIST}; do
        if [ "${PROVIDER}" == "" ]; then
            GIT_PWD="${GIT_PWD}/${V}"
        fi
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

    # git@github.com:
    # ssh://git@8.8.8.8:443/
    if [ "${PROVIDER}" != "" ]; then
        if [ "${PROVIDER}" == "github.com" ]; then
            GIT_URL="git@${PROVIDER}:"
        elif [ "${PROVIDER}" == "gitlab.com" ]; then
            GIT_URL="git@${PROVIDER}:"
        else
            if [ -f ${GIT_PWD}/.git_url ]; then
                GIT_URL=$(cat ${GIT_PWD}/.git_url)
            else
                _read "Please input git url. (ex: ssh://git@8.8.8.8:443/): "

                GIT_URL=${ANSWER}

                if [ ! -z ${GIT_URL} ]; then
                    echo "${GIT_URL}" > ${GIT_PWD}/.git_url
                fi
            fi
        fi
    fi
}

get_cmd() {
    if [ -z ${CMD} ]; then
        usage
    fi

    case ${CMD} in
        cl|clone)
            if [ -z ${MSG} ]; then
                PROJECT=${APP}
            else
                PROJECT=${MSG}
            fi
            ;;
        *)
            PROJECT=${APP}
            ;;
    esac

    case ${CMD} in
        cl|clone)
            if [ -d ${NOW_DIR}/${PROJECT} ]; then
                _error "Source directory already exists."
            fi
            ch_now_dir
            rm_app_dir
            ;;
        *)
            if [ ! -d ${NOW_DIR}/${PROJECT} ]; then
                _error "Source directory doesn't exists."
            fi
            ch_app_dir
        ;;
    esac
}

ch_now_dir() {
    cd ${NOW_DIR}
}

ch_app_dir() {
    if [ ! -d "${NOW_DIR}/${PROJECT}" ]; then
        _error "Not set project."
    fi

    cd ${NOW_DIR}/${PROJECT}

    # selected branch
    BRANCH=$(git branch | grep \* | cut -d' ' -f2)

    if [ "${BRANCH}" == "" ]; then
        BRANCH="master"
    fi

    _result "${BRANCH}"
}

rm_app_dir() {
    rm -rf ${NOW_DIR}/${PROJECT}
}

git_clone() {
    git clone "${GIT_URL}${MY_ID}/${APP}.git" "${PROJECT}"

    if [ ! -d "${NOW_DIR}/${PROJECT}" ]; then
        _error "Not set project."
    fi

    ch_app_dir

    # https://github.com/awslabs/git-secrets
    git secrets --install
    git secrets --register-aws

    git branch -v
}

git_remote() {
    git remote

    if [ "${MSG}" == "" ]; then
        return
    fi

    REMOTES="/tmp/${APP}-remote"
    git remote > ${REMOTES}

    while read VAR; do
        if [ "${VAR}" == "${MSG}" ]; then
            _error "Remote '${MSG}' already exists."
        fi
    done < ${REMOTES}

    git remote add --track master ${MSG} "${GIT_URL}${MSG}/${APP}.git"
    git remote
}

git_branch() {
    git branch -a

    if [ "${MSG}" == "" ]; then
        return
    fi
    if [ "${MSG}" == "${BRANCH}" ]; then
        _error "Already on '${BRANCH}'."
    fi

    HAS="false"
    BRANCHES="/tmp/${APP}-branch"
    git branch -a > ${BRANCHES}

    while read VAR; do
        ARR=(${VAR})
        if [ "${ARR[1]}" == "" ]; then
            if [ "${ARR[0]}" == "${MSG}" ]; then
                HAS="true"
            fi
        else
            if [ "${ARR[1]}" == "${MSG}" ]; then
                HAS="true"
            fi
        fi
    done < ${BRANCHES}

    if [ "${HAS}" != "true" ]; then
        git branch ${MSG} ${TAG}
    fi

    git checkout ${MSG}
    git branch -v
}

git_diff() {
    git branch -v
    git diff
}

git_commit() {
    shift && shift
    MSG=$*

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

################################################################################

prepare

get_cmd

nsh
