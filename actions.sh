#!/bin/bash

OS_NAME="$(uname | awk '{print tolower($0)}')"

SHELL_DIR=$(dirname $0)

RUN_PATH="."

CMD=${1}

REPOSITORY=${GITHUB_REPOSITORY}

USERNAME=${GITHUB_ACTOR}
REPONAME=$(echo "${REPOSITORY}" | cut -d'/' -f2)

# _build
BRANCH=${GITHUB_REF}

# _publish
PUBLISH_PATH=${PUBLISH_PATH}

# _release
GITHUB_TOKEN=${GITHUB_TOKEN}

# _docker
DOCKER_USER=${DOCKER_USER:-$USERNAME}
DOCKER_PASS=${DOCKER_PASS}
DOCKER_ORG=${DOCKER_ORG:-$DOCKER_USER}

# _slack
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

################################################################################

_prepare() {
    mkdir -p ${RUN_PATH}/target/publish
    mkdir -p ${RUN_PATH}/target/release
}

_build() {
    if [ ! -f ${RUN_PATH}/VERSION ]; then
        _error "not found VERSION"
    fi

    _result "USERNAME=${USERNAME}"
    _result "REPONAME=${REPONAME}"

    _result "REPOSITORY=${REPOSITORY}"

    # refs/heads/master
    # refs/pull/1/merge
    _result "BRANCH=${BRANCH}"

    # release version
    MAJOR=$(cat ${RUN_PATH}/VERSION | xargs | cut -d'.' -f1)
    MINOR=$(cat ${RUN_PATH}/VERSION | xargs | cut -d'.' -f2)
    PATCH=$(cat ${RUN_PATH}/VERSION | xargs | cut -d'.' -f3)

    if [ "${PATCH}" != "x" ]; then
        VERSION="${MAJOR}.${MINOR}.${PATCH}"
        printf "${VERSION}" > ${RUN_PATH}/target/VERSION
    else
        # latest versions
        URL="https://api.github.com/repos/${REPOSITORY}/releases"
        VERSION=$(curl -s ${URL} | grep "tag_name" | grep "${MAJOR}.${MINOR}." | head -1 | cut -d'"' -f4 | cut -d'-' -f1)

        if [ -z ${VERSION} ]; then
            VERSION="${MAJOR}.${MINOR}.0"
        fi

        _result "VERSION=${VERSION}"

        # new version
        if [ "${BRANCH}" == "refs/heads/master" ]; then
            VERSION=$(echo ${VERSION} | perl -pe 's/^(([v\d]+\.)*)(\d+)(.*)$/$1.($3+1).$4/e')
        else
            if [ "${BRANCH}" != "" ]; then
                # refs/pull/1/merge
                PR_CMD=$(echo "${BRANCH}" | cut -d'/' -f2)
                PR_NUM=$(echo "${BRANCH}" | cut -d'/' -f3)
            fi

            if [ "${PR_CMD}" == "pull" ] && [ "${PR_NUM}" != "" ]; then
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
    if [ "${BRANCH}" != "refs/heads/master" ]; then
        _result "nat match master == ${BRANCH}"
        return
    fi
    if [ ! -f ${RUN_PATH}/target/VERSION ]; then
        _result "not found target/VERSION"
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

_release_id() {
    URL="https://api.github.com/repos/${REPOSITORY}/releases"
    RELEASE_ID=$(curl -s ${URL} | VERSION=${VERSION} jq '.[] | select(.tag_name == env.VERSION) | .id')
}

_release_assets() {
    LIST=/tmp/release-list
    ls ${RUN_PATH}/target/release/ | sort > ${LIST}

    while read FILENAME; do
        FILEPATH=${RUN_PATH}/target/release/${FILENAME}
        FILESIZE=$(stat -c%s "${FILEPATH}")

        CONTENT_TYPE_HEADER="Content-Type: application/zip"
        CONTENT_LENGTH_HEADER="Content-Length: ${FILESIZE}"

        _command "github releases assets ${REPOSITORY} ${RELEASE_ID} ${FILENAME} ${FILESIZE}"
        URL="https://api.github.com/repos/${REPOSITORY}/releases/${RELEASE_ID}/assets?name=${FILENAME}"
        curl \
            -sSL \
            -X POST \
            -H "${AUTH_HEADER}" \
            -H "${CONTENT_TYPE_HEADER}" \
            -H "${CONTENT_LENGTH_HEADER}" \
            -F "file1=@${FILEPATH}" \
            ${URL}
    done < ${LIST}
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

    printf "${VERSION}" > ${RUN_PATH}/target/release/${VERSION}

    AUTH_HEADER="Authorization: token ${GITHUB_TOKEN}"

    _release_id
    if [ "${RELEASE_ID}" != "" ]; then
        _command "github releases delete ${REPOSITORY} ${RELEASE_ID}"
        URL="https://api.github.com/repos/${REPOSITORY}/releases/${RELEASE_ID}"
        curl \
            -sSL \
            -X DELETE \
            -H "${AUTH_HEADER}" \
            ${URL}
    fi

    if [ -f ${RUN_PATH}/target/PR ]; then
        PRERELEASE="true"
    else
        PRERELEASE="false"
    fi

    _command "github releases create ${REPOSITORY} ${VERSION} ${PRERELEASE}"
    URL="https://api.github.com/repos/${REPOSITORY}/releases"
    curl \
        -sSL \
        -X POST \
        -H "${AUTH_HEADER}" \
        --data @- \
        ${URL} <<END
{
 "tag_name": "${VERSION}",
 "target_commitish": "master",
 "name": "${VERSION}",
 "prerelease": ${PRERELEASE}
}
END

    _release_id
    if [ "${RELEASE_ID}" == "" ]; then
        _error "not found RELEASE_ID"
    fi

    _release_assets
}

_docker() {
    if [ ! -f ${RUN_PATH}/target/VERSION ]; then
        _result "not found target/VERSION"
        return
    fi
    if [ -z ${DOCKER_USER} ] || [ -z ${DOCKER_PASS} ]; then
        _result "not found DOCKER_USER or DOCKER_PASS"
        return
    fi

    VERSION=$(cat ${RUN_PATH}/target/VERSION | xargs)
    _result "VERSION=${VERSION}"

    _command "docker login -u $DOCKER_USER"
    docker login -u $DOCKER_USER -p $DOCKER_PASS

    _command "docker build -t ${DOCKER_ORG}/${REPONAME}:${VERSION} ."
    docker build -t ${DOCKER_ORG}/${REPONAME}:${VERSION} .

    _command "docker push ${DOCKER_ORG}/${REPONAME}:${VERSION}"
    docker push ${DOCKER_ORG}/${REPONAME}:${VERSION}

    _command "docker logout"
    docker logout
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
    curl -sL opspresso.com/tools/slack | bash -s -- \
        --token="${SLACK_TOKEN}" --username="${USERNAME}" \
        --footer="<https://github.com/${REPOSITORY}/releases/tag/${VERSION}|${REPOSITORY}>" \
        --footer_icon="https://repo.opspresso.com/favicon/github.png" \
        --color="good" --title="${REPONAME}" "\`${VERSION}\`"
}

################################################################################

_prepare

case ${CMD} in
    build)
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
    slack)
        _slack
        ;;
esac

_success
