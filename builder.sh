#!/bin/bash

OS_NAME="$(uname | awk '{print tolower($0)}')"

SHELL_DIR=$(dirname $0)

RUN_PATH="."

CMD=${1:-$CIRCLE_JOB}

PARAM=${2}

USERNAME=${CIRCLE_PROJECT_USERNAME}
REPONAME=${CIRCLE_PROJECT_REPONAME}

BRANCH=${CIRCLE_BRANCH:-master}

DOCKER_USER=${DOCKER_USER:-$USERNAME}
DOCKER_PASS=${DOCKER_PASS}

CIRCLE_BUILDER=${CIRCLE_BUILDER}

GITHUB_TOKEN=${GITHUB_TOKEN}

PUBLISH_PATH=${PUBLISH_PATH}

SLACK_TOKEN=${SLACK_TOKEN}

################################################################################

# command -v tput > /dev/null && TPUT=true
TPUT=

_echo() {
  if [ "${TPUT}" != "" ] && [ "$2" != "" ]; then
    echo -e "$(tput setaf $2)$1$(tput sgr0)"
  else
    echo -e "$1"
  fi
}

_result() {
  echo
  _echo "# $@" 4
}

_command() {
  echo
  _echo "$ $@" 3
}

_success() {
  echo
  _echo "+ $@" 2
  exit 0
}

_error() {
  echo
  _echo "- $@" 1
  exit 1
}

_replace() {
  if [ "${OS_NAME}" == "darwin" ]; then
    sed -i "" -e "$1" $2
  else
    sed -i -e "$1" $2
  fi
}

_prepare() {
  # target
  mkdir -p ${RUN_PATH}/target/publish
  mkdir -p ${RUN_PATH}/target/release

  if [ -f ${RUN_PATH}/target/circleci-stop ]; then
    _success "circleci-stop"
  fi
}

_build() {
  if [ ! -f ${RUN_PATH}/VERSION ]; then
    _error "not found VERSION"
  fi

  _result "BRANCH=${BRANCH}"
  _result "PR_URL=${CIRCLE_PULL_REQUEST}"

  # release version
  MAJOR=$(cat ${RUN_PATH}/VERSION | xargs | cut -d'.' -f1)
  MINOR=$(cat ${RUN_PATH}/VERSION | xargs | cut -d'.' -f2)
  PATCH=$(cat ${RUN_PATH}/VERSION | xargs | cut -d'.' -f3)

  if [ "${PATCH}" != "x" ]; then
    VERSION="${MAJOR}.${MINOR}.${PATCH}"
    printf "${VERSION}" > ${RUN_PATH}/target/VERSION
  else
    # latest versions
    GITHUB="https://api.github.com/repos/${USERNAME}/${REPONAME}/releases"
    VERSION=$(curl -s ${GITHUB} | grep "tag_name" | grep "${MAJOR}.${MINOR}." | head -1 | cut -d'"' -f4 | cut -d'-' -f1)

    if [ -z ${VERSION} ]; then
      VERSION="${MAJOR}.${MINOR}.0"
    fi

    _result "VERSION=${VERSION}"

    # new version
    if [ "${BRANCH}" == "main" ] || [ "${BRANCH}" == "master" ]; then
      VERSION=$(echo ${VERSION} | awk -F. '{$NF = $NF + 1;} 1' | sed 's/ /./g')
    else
      if [ "${CIRCLE_PULL_REQUEST}" != "" ]; then
        PR_NUM=$(echo "${CIRCLE_PULL_REQUEST}" | cut -d'/' -f7)
      fi

      if [ "${PR_NUM}" != "" ]; then
        VERSION="${VERSION}-${PR_NUM}"
        echo ${PR_NUM} > ${RUN_PATH}/target/PR
      else
        VERSION=""
      fi
    fi

    if [ "${VERSION}" != "" ]; then
      printf "${VERSION}" > ${RUN_PATH}/target/VERSION
    fi
  fi

  _result "VERSION=${VERSION}"
}

_publish() {
  if [ "${BRANCH}" != "main" ] && [ "${BRANCH}" != "master" ]; then
    return
  fi
  if [ ! -f ${RUN_PATH}/target/VERSION ]; then
    _result "not found target/VERSION"
    return
  fi
  if [ -f ${RUN_PATH}/target/PR ]; then
    _result "found target/PR"
    return
  fi
  if [ -z ${PUBLISH_PATH} ]; then
    _result "not found PUBLISH_PATH"
    return
  fi

  BUCKET="$(echo "${PUBLISH_PATH}" | cut -d'/' -f1)"

  # aws s3 sync
  _command "aws s3 sync ${RUN_PATH}/target/publish/ s3://${PUBLISH_PATH}/ --acl public-read"
  aws s3 sync ${RUN_PATH}/target/publish/ s3://${PUBLISH_PATH}/ --acl public-read

  # aws cf reset
  CFID=$(aws cloudfront list-distributions --query "DistributionList.Items[].{Id:Id,Origin:Origins.Items[0].DomainName}[?contains(Origin,'${BUCKET}')] | [0]" | grep 'Id' | cut -d'"' -f4)
  if [ "${CFID}" != "" ]; then
    aws cloudfront create-invalidation --distribution-id ${CFID} --paths "/*"
  fi
}

_release() {
  if [ ! -f ${RUN_PATH}/target/VERSION ]; then
    _result "not found target/VERSION"
    return
  fi
  if [ -z ${GITHUB_TOKEN} ]; then
    _result "not found GITHUB_TOKEN"
    return
  fi

  VERSION=$(cat ${RUN_PATH}/target/VERSION | xargs)
  _result "VERSION=${VERSION}"

  # printf "${VERSION}" > ${RUN_PATH}/target/release/${VERSION}

  # if [ -f ${RUN_PATH}/target/PR ]; then
  #   GHR_PARAM="-delete -prerelease"
  # else
  #   GHR_PARAM="-delete"
  # fi

  # _command "go get github.com/tcnksm/ghr"
  # go get github.com/tcnksm/ghr

  # # github release
  # _command "ghr ${VERSION} ${RUN_PATH}/target/release/"
  # ghr -t ${GITHUB_TOKEN:-EMPTY} \
  #   -u ${USERNAME} \
  #   -r ${REPONAME} \
  #   -c ${CIRCLE_SHA1} \
  #   ${GHR_PARAM} \
  #   ${VERSION} ${RUN_PATH}/target/release/

  _command "hub release create ${VERSION}"
  hub release create ${VERSION}
}

_docker() {
  if [ ! -f ${RUN_PATH}/target/VERSION ]; then
    _result "not found target/VERSION"
    return
  fi
  if [ -z ${DOCKER_PASS} ]; then
    _result "not found DOCKER_USER"
    return
  fi

  VERSION=$(cat ${RUN_PATH}/target/VERSION | xargs)
  _result "VERSION=${VERSION}"

  _command "docker login -u $DOCKER_USER"
  docker login -u $DOCKER_USER -p $DOCKER_PASS

  _command "docker build -t ${USERNAME}/${REPONAME}:${VERSION} ."
  docker build -f ${PARAM:-Dockerfile} -t ${USERNAME}/${REPONAME}:${VERSION} .

  _command "docker push ${USERNAME}/${REPONAME}:${VERSION}"
  docker push ${USERNAME}/${REPONAME}:${VERSION}

  # if [ "${PARAM}" == "latest" ]; then
  #   _command "sudo docker tag ${USERNAME}/${REPONAME}:${VERSION} ${USERNAME}/${REPONAME}:latest"
  #   sudo docker tag ${USERNAME}/${REPONAME}:${VERSION} ${USERNAME}/${REPONAME}:latest

  #   _command "docker push ${USERNAME}/${REPONAME}:latest"
  #   docker push ${USERNAME}/${REPONAME}:latest
  # fi

  _command "docker logout"
  docker logout
}

_buildx() {
  if [ ! -f ${RUN_PATH}/target/VERSION ]; then
    _result "not found target/VERSION"
    return
  fi
  if [ -z ${DOCKER_PASS} ]; then
    _result "not found DOCKER_USER"
    return
  fi

  VERSION=$(cat ${RUN_PATH}/target/VERSION | xargs)
  _result "VERSION=${VERSION}"

  if [ ! -f ~/.docker/cli-plugins/docker-buildx ]; then
    mkdir -p ~/.docker/cli-plugins
    url="https://github.com/docker/buildx/releases/download/v0.5.1/buildx-v0.5.1.linux-amd64"
    curl -sSL -o ~/.docker/cli-plugins/docker-buildx ${url}
    chmod a+x ~/.docker/cli-plugins/docker-buildx
  fi

  _command "docker buildx version"
  docker buildx version

  _command "docker login -u $DOCKER_USER"
  docker login -u $DOCKER_USER -p $DOCKER_PASS

  _command "docker buildx build -t ${USERNAME}/${REPONAME}:${VERSION} ."
  docker buildx build --push -f ${PARAM:-Dockerfile} \
    --platform linux/arm/v7,linux/arm64/v8,linux/amd64 \
    -t ${USERNAME}/${REPONAME}:${VERSION} .

  # _command "docker push ${USERNAME}/${REPONAME}:${VERSION}"
  # docker push ${USERNAME}/${REPONAME}:${VERSION}

  # if [ "${PARAM}" == "latest" ]; then
  #   _command "sudo docker tag ${USERNAME}/${REPONAME}:${VERSION} ${USERNAME}/${REPONAME}:latest"
  #   sudo docker tag ${USERNAME}/${REPONAME}:${VERSION} ${USERNAME}/${REPONAME}:latest

  #   _command "docker push ${USERNAME}/${REPONAME}:latest"
  #   docker push ${USERNAME}/${REPONAME}:latest
  # fi

  _command "docker logout"
  docker logout
}

_trigger() {
  if [ ! -f ${RUN_PATH}/target/VERSION ]; then
    _result "not found target/VERSION"
    return
  fi
  if [ -z ${CIRCLE_BUILDER} ]; then
    _result "not found CIRCLE_BUILDER"
    return
  fi
  if [ -z ${PERSONAL_TOKEN:-$CIRCLE_TOKEN} ]; then
    _result "not found PERSONAL_TOKEN"
    return
  fi

  VERSION=$(cat ${RUN_PATH}/target/VERSION | xargs)
  _result "VERSION=${VERSION}"

  PERSONAL_TOKEN=${PERSONAL_TOKEN:-$CIRCLE_TOKEN}

  # CIRCLE_API="https://circleci.com/api/v1.1/project/github/${CIRCLE_BUILDER}"
  # CIRCLE_URL="${CIRCLE_API}?circle-token=${PERSONAL_TOKEN}"

  # https://circleci.com/docs/api/v2/#get-a-pipeline-39-s-workflows
  CIRCLE_API="https://circleci.com/api/v2/project/gh/${CIRCLE_BUILDER}/pipeline"
  CIRCLE_URL="${CIRCLE_API}?circle-token=${PERSONAL_TOKEN}"

  # build_parameters
  PAYLOAD="{\"parameters\":{"
  PAYLOAD="${PAYLOAD}\"username\":\"${TG_USERNAME:-${USERNAME}}\","
  PAYLOAD="${PAYLOAD}\"project\":\"${TG_PROJECT:-${REPONAME}}\","
  PAYLOAD="${PAYLOAD}\"version\":\"${TG_VERSION:-${VERSION}}\""
  PAYLOAD="${PAYLOAD}}}"

  _result "PAYLOAD=${PAYLOAD}"

  curl -X POST \
    -u ${PERSONAL_TOKEN}: \
    -H "Content-Type: application/json" \
    -d "${PAYLOAD}" "${CIRCLE_API}"
}

_slack() {
  if [ ! -f ${RUN_PATH}/target/VERSION ]; then
    _result "not found target/VERSION"
    return
  fi
  if [ -z ${SLACK_TOKEN} ]; then
    _result "not found SLACK_TOKEN"
    return
  fi

  VERSION=$(cat ${RUN_PATH}/target/VERSION | xargs)
  _result "VERSION=${VERSION}"

  # send slack
  curl -sL opspresso.github.io/tools/slack.sh | bash -s -- \
    --token="${SLACK_TOKEN}" --username="${USERNAME}" \
    --footer="<https://github.com/${USERNAME}/${REPONAME}/releases/tag/${VERSION}|${USERNAME}/${REPONAME}>" \
    --footer_icon="https://opspresso.github.io/tools/favicon/github.png" \
    --color="good" --title="${REPONAME}" "\`${VERSION}\`"
}

################################################################################

_prepare

case ${CMD} in
  build|package)
    _build
    ;;
  publish)
    _publish
    ;;
  release)
    _release
    ;;
  docker)
    _docker
    ;;
  buildx)
    _buildx
    ;;
  trigger)
    _trigger
    ;;
  slack)
    _slack
    ;;
esac

_success
