#!/bin/bash

function usage() {
  echo "Usage: $0 {name} {clone|remove|branch|diff|commit|pull|push|pp}"
}

function get_my_id() {
  if [ "${MY_ID}" == "" ]; then
    echo "Please enter your github account. [example:nalbam]"
    read MY_ID

    if [ "${MY_ID}" == "" ]; then
      echo "github account is null."
      exit 1
    fi

    echo "MY_ID=${MY_ID}" >> "${CONFIG}"
  fi
}

function get_up_id() {
  if [ "${UP_ID}" == "" ]; then
    echo "Please enter github upstream account. [default:${MY_ID}]"
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
  if [ ! -d "${NOW_DIR}/${PRJ}" ]; then
    exit 1
  fi

  cd "${NOW_DIR}/${PRJ}"

  if [ -f "${BCH}" ]; then
    read BRANCH < "${BCH}"
  fi

  if [ "${BRANCH}" == "" ]; then
    BRANCH="master"
  fi
}

function rm_app_dir() {
  rm -rf "${NOW_DIR}/${PRJ}"
  rm -rf "${YEL_DIR}/${PRJ}".*
}

function git_clone() {
  git clone "git@github.com:${MY_ID}/${APP}.git" "${PRJ}"

  if [ ! -d "${NOW_DIR}/${PRJ}" ]; then
    exit 1
  fi

  ch_app_dir

  if [ "${MY_ID}" != "${UP_ID}" ]; then
    git remote add --track master upstream "git@github.com:${UP_ID}/${APP}.git"
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

  git checkout "${BRANCH}"
  echo "${BRANCH}" > "${BCH}"

  git branch -v
}

############################################################

APP=$(echo "$1" | sed -e "s/\///g")
CMD="$2"
MSG="$3"
PRJ=""

NOW_DIR=$(pwd)
YEL_DIR="${NOW_DIR}/.yell"

CONFIG="${YEL_DIR}/config.sh"

MY_ID=""
UP_ID=""

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

get_my_id
get_up_id

BRANCH=""

case "${CMD}" in
  cl|clone)
    if [ "${MSG}" == "" ]; then
      PRJ="${APP}"
    else
      PRJ="${MSG}"
    fi
    ;;
  *)
    PRJ="${APP}"
    ;;
esac

BCH="${YEL_DIR}/${PRJ}.bch"

case "${CMD}" in
  cl|clone)
    if [ -d "${NOW_DIR}/${PRJ}" ]; then
      echo "Source directory already exists."
      exit 1
    fi
    ch_now_dir
    rm_app_dir
    ;;
  *)
    if [ ! -d "${NOW_DIR}/${PRJ}" ]; then
      echo "Source directory doesn't exists."
      exit 1
    fi
    ch_app_dir
    ;;
esac

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

exit $?
