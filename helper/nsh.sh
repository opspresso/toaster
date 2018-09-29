#!/bin/bash

APP=$(echo "$1" | sed -e "s/\///g")
CMD=$2
MSG=$3
TAG=$4
ALL=$*

PROJECT=
BRANCH=

NOW_DIR=$(pwd)

PROVIDER=
MY_ID=

GIT_URL=
GIT_PWD=

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
        if [ -z ${PROVIDER} ]; then
            GIT_PWD="${GIT_PWD}/${V}"
        fi
        if [ "${DETECT}" == "true" ]; then
            if [ -z ${PROVIDER} ]; then
                PROVIDER="${V}"
            elif [ -z ${MY_ID} ]; then
                MY_ID="${V}"
            fi
        elif [ "${V}" == "src" ]; then
            DETECT=true
        fi
    done

    # git@github.com:
    # ssh://git@8.8.8.8:443/
    if [ ! -z ${PROVIDER} ]; then
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

cmd() {
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
    if [ ! -d ${NOW_DIR}/${PROJECT} ]; then
        _error "Not set project."
    fi

    cd ${NOW_DIR}/${PROJECT}

    # selected branch
    BRANCH=$(git branch | grep \* | cut -d' ' -f2)

    if [ -z ${BRANCH} ]; then
        BRANCH="master"
    fi

    _result "${BRANCH}"
}

rm_app_dir() {
    rm -rf ${NOW_DIR}/${PROJECT}
}

git_clone() {
    _command "git clone ${GIT_URL}${MY_ID}/${APP}.git ${PROJECT}"
    git clone ${GIT_URL}${MY_ID}/${APP}.git ${PROJECT}

    if [ ! -d ${NOW_DIR}/${PROJECT} ]; then
        _error "Not set project."
    fi

    ch_app_dir

    # https://github.com/awslabs/git-secrets

    _command "git secrets --install"
    git secrets --install

    _command "git secrets --register-aws"
    git secrets --register-aws

    _command "git branch -v"
    git branch -v
}

git_remote() {
    _command "git remote"
    git remote

    if [ -z ${MSG} ]; then
        _error
    fi

    REMOTES="/tmp/${APP}-remote"
    git remote > ${REMOTES}

    while read VAR; do
        if [ "${VAR}" == "${MSG}" ]; then
            _error "Remote '${MSG}' already exists."
        fi
    done < ${REMOTES}

    _command "git remote add --track master ${MSG} ${GIT_URL}${MSG}/${APP}.git"
    git remote add --track master ${MSG} ${GIT_URL}${MSG}/${APP}.git

    _command "git remote"
    git remote
}

git_branch() {
    _command "git branch -a"
    git branch -a

    if [ -z ${MSG} ]; then
        _error
    fi
    if [ "${MSG}" == "${BRANCH}" ]; then
        _error "Already on '${BRANCH}'."
    fi

    HAS="false"
    BRANCHES="/tmp/${APP}-branch"
    git branch -a > ${BRANCHES}

    while read VAR; do
        ARR=(${VAR})
        if [ -z ${ARR[1]} ]; then
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
        _command "git branch ${MSG} ${TAG}"
        git branch ${MSG} ${TAG}
    fi

    _command "git checkout ${MSG}"
    git checkout ${MSG}

    _command "git branch -v"
    git branch -v
}

git_diff() {
    _command "git branch -v"
    git branch -v

    _command "git diff"
    git diff
}

git_commit() {
    shift 2
    MSG=$*

    if [ -z ${MSG} ]; then
        _error
    fi

    _command "git add --all"
    git add --all

    _command "git commit -m ${MSG}"
    git commit -m ${MSG}
}

git_pull() {
    _command "git branch -v"
    git branch -v

    REMOTES="/tmp/${APP}-remote"
    git remote > ${REMOTES}

    _command "git pull origin ${BRANCH}"
    git pull --no-edit origin ${BRANCH}

    while read REMOTE; do
        if [ "${REMOTE}" != "origin" ]; then
            _command "git pull ${REMOTE} ${BRANCH}"
            git pull --no-edit ${REMOTE} ${BRANCH}
        fi
    done < ${REMOTES}
}

git_push() {
    _command "git branch -v"
    git branch -v

    _command "git push origin ${BRANCH}"
    git push --no-edit origin ${BRANCH}
}

git_tag() {
    _command "git branch -v"
    git branch -v

    _command "git pull"
    git pull --no-edit

    _command "git tag"
    git tag
}

################################################################################

prepare

cmd

nsh
