#!/bin/bash

# curl -sL toast.sh/install | bash

OS_NAME="$(uname | awk '{print tolower($0)}')"

THIS_VERSION=v0.0.0

CMD=$1
SUB=$2

NAME=
BRANCH=master
VERSION=0.0.0
NAMESPACE=
CLUSTER=

BASE_DOMAIN=
JENKINS=
REGISTRY=
CHARTMUSEUM=
SONARQUBE=
NEXUS=

CONFIG=${HOME}/.toaster

touch ${CONFIG} && . ${CONFIG}

for v in "$@"; do
    case ${v} in
    --name=*)
        NAME="${v#*=}"
        shift
        ;;
    --branch=*)
        BRANCH="${v#*=}"
        shift
        ;;
    --version=*)
        VERSION="${v#*=}"
        shift
        ;;
    --namespace=*)
        NAMESPACE="${v#*=}"
        shift
        ;;
    --cluster=*)
        CLUSTER="${v#*=}"
        shift
        ;;
    *)
        shift
        ;;
    esac
done

################################################################################

command -v tput > /dev/null || TPUT=false

_bar() {
    _echo "================================================================================"
}

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

_logo() {
    #figlet toaster
    _bar
    _echo " | |_ ___   __ _ ___| |_ ___ _ __  "
    _echo " | __/ _ \ / _' / __| __/ _ \ '__| "
    _echo " | || (_) | (_| \__ \ ||  __/ | "
    _echo "  \__\___/ \__,_|___/\__\___|_|  ${THIS_VERSION}"
    _bar
}

_usage() {
    _logo
    _echo " Usage: $0 {update|bastion|scan|build|helm|draft} "
    _bar
    _error
}

_replace() {
    if [ "${OS_NAME}" == "darwin" ]; then
        sed -i "" -e "$1" $2
    else
        sed -i -e "$1" $2
    fi
}

################################################################################

_toast() {
    case ${CMD} in
        u|update)
            _update
            ;;
        t|bastion)
            _bastion
            ;;
        h|helper)
            _helper
            ;;
        s|scan)
            _scan
            ;;
        b|build)
            _build
            ;;
        h|helm)
            _helm
            ;;
        d|draft)
            _draft
            ;;
        v|version)
            _version
            ;;
        *)
            _usage
    esac
}

_update() {
    VERSION=$(curl -s https://api.github.com/repos/nalbam/toaster/releases/latest | grep tag_name | cut -d'"' -f4)

    if [ "${VERSION}" == "${THIS_VERSION}" ]; then
        _success "Latest version already installed. [${THIS_VERSION}]"
    fi

    curl -sL toast.sh/install | bash
    exit 0
}

_bastion() {
    curl -sL toast.sh/helper/bastion.sh | bash
    exit 0
}

_version() {
    _echo ${THIS_VERSION} 2
    exit 0
}

_helper() {
    _result "helper package version: ${THIS_VERSION}"

    DIST=/tmp/helper.tar.gz
    rm -rf ${DIST}

    # download
    curl -sL -o ${DIST} https://github.com/nalbam/toaster/releases/download/${THIS_VERSION}/helper.tar.gz

    if [ ! -f ${DIST} ]; then
        _error "Can not download."
    fi

    _result "helper package downloaded."

    HELPER_DIR="${HOME}/helper"
    mkdir -p ${HELPER_DIR}

    BASH_ALIAS="${HOME}/.bash_aliases"

    # install
    tar -zxf ${DIST} -C ${HELPER_DIR}

    # alias
    if [ -f ${HELPER_DIR}/alias.sh ]; then
        cp -rf ${HELPER_DIR}/alias.sh ${BASH_ALIAS}
        chmod 644 ${BASH_ALIAS}
    fi

    if [ -f ${BASH_ALIAS} ]; then
        touch ~/.bashrc
        HAS_ALIAS="$(cat ${HOME}/.bashrc | grep bash_aliases | wc -l | xargs)"

        if [ "x${HAS_ALIAS}" == "x0" ]; then
            echo "if [ -f ~/.bash_aliases ]; then" >> ${HOME}/.bashrc
            echo "  . ~/.bash_aliases" >> ${HOME}/.bashrc
            echo "fi" >> ${HOME}/.bashrc
        fi

        . ${BASH_ALIAS}
    fi

    # chmod 755
    find ${HELPER_DIR}/** | grep [.]sh | xargs chmod 755
}

_scan() {
    case ${SUB} in
        domain)
            _scan_domain
            _config_save_all
            ;;
        source)
            _scan_source
            _config_save_all
            ;;
        clean)
            _config_remove
            ;;
        *)
            _scan_domain
            _scan_source
            _config_save_all
    esac
}

_build() {
    case ${SUB} in
        chart)
            _build_chart
            ;;
        image)
            _build_image
            ;;
        *)
            _usage
    esac
}

_helm() {
    case ${SUB} in
        init)
            _helm_init
            ;;
        install)
            _helm_install
            ;;
        delete)
            _helm_delete
            ;;
        *)
            _helm_init
    esac
}

_draft() {
    case ${SUB} in
        init)
            _draft_init
            ;;
        pack)
            _draft_pack
            ;;
        up)
            _draft_up
            ;;
        *)
            _draft_init
    esac
}

_scan_domain() {
    JENKINS=$(_domain_find jenkins)

    if [ ! -z ${JENKINS} ]; then
        BASE_DOMAIN=${JENKINS:$(expr index ${JENKINS} \.)}
    fi

    CHARTMUSEUM=$(_domain_find chartmuseum)
    REGISTRY=$(_domain_find docker-registry)
    SONARQUBE=$(_domain_find sonarqube)
    NEXUS=$(_domain_find sonatype-nexus)

    _maven_mirror
}

_scan_source() {
    _version_build

    SOURCE_ROOT="."
    [ ! -z ${SOURCE_LANG} ] || _language_scan pom.xml java
    [ ! -z ${SOURCE_LANG} ] || _language_scan package.json nodejs
    [ ! -z ${SOURCE_LANG} ] || SOURCE_LANG="-"

    if [ -z ${NAME} ]; then
        _error "NAME is empty."
    fi
    if [ -z ${VERSION} ]; then
        _error "VERSION is empty."
    fi

    if [ -f charts/acme/Chart.yaml ]; then
        _command "sed -i -e s/name: .*/name: $NAME/ charts/acme/Chart.yaml"
        _replace "s/name: .*/name: $NAME/" charts/acme/Chart.yaml

        _command "sed -i -e s/version: .*/version: $VERSION/ charts/acme/Chart.yaml"
        _replace "s/version: .*/version: $VERSION/" charts/acme/Chart.yaml
    fi

    if [ -f charts/acme/values.yaml ]; then
        _command "sed -i -e s|basedomain: .*|basedomain: $BASE_DOMAIN| charts/acme/values.yaml"
        _replace "s|basedomain: .*|basedomain: $BASE_DOMAIN|" charts/acme/values.yaml

        if [ ! -z ${REGISTRY} ]; then
            _command "sed -i -e s|repository: .*|repository: $REGISTRY/$NAME| charts/acme/values.yaml"
            _replace "s|repository: .*|repository: $REGISTRY/$NAME|" charts/acme/values.yaml
        fi

        _command "sed -i -e s|tag: .*|tag: $VERSION| charts/acme/values.yaml"
        _replace "s|tag: .*|tag: $VERSION|" charts/acme/values.yaml
    fi

    if [ -d charts/acme ]; then
        _command "mv charts/acme charts/$NAME"
        mv charts/acme charts/$NAME
    fi
}

_build_chart() {
    _helm_init

    if [ -z ${NAME} ]; then
        _error "NAME is empty."
    fi
    if [ ! -d charts/$NAME ]; then
        error "Not found charts/$NAME"
    fi

    pushd charts/$NAME

    _command "helm lint ."
    helm lint .

    if [ ! -z ${CHARTMUSEUM} ]; then
        _command "helm push . chartmuseum"
        helm push . chartmuseum
    fi

    _command "helm repo update"
    helm repo update

    _command "helm search $NAME"
    helm search $NAME

    popd
}

_build_image() {
    if [ ! -f Dockerfile ]; then
        _error "Not found Dockerfile"
    fi

    if [ -z ${REGISTRY} ]; then
        _error "REGISTRY is empty."
    fi

    if [ -z ${NAME} ]; then
        _error "NAME is empty."
    fi
    if [ -z ${VERSION} ]; then
        _error "VERSION is empty."
    fi

    _command "docker build -t $REGISTRY/$NAME:$VERSION ."
    docker build -t $REGISTRY/$NAME:$VERSION .

    _command "docker push $REGISTRY/$NAME:$VERSION"
    docker push $REGISTRY/$NAME:$VERSION
}

_helm_init() {
    _command "helm init --client-only"
	helm init --client-only

    _command "helm version"
	helm version

    if [ ! -z ${CHARTMUSEUM} ]; then
        _command "helm repo add chartmuseum https://${CHARTMUSEUM}"
        helm repo add chartmuseum https://${CHARTMUSEUM}
    fi

    _command "helm repo list"
	helm repo list

    _command "helm repo update"
	helm repo update

    COUNT=$(helm plugin list | grep 'Push chart package' | wc -l | xargs)

    if [ "x${COUNT}" == "x0" ]; then
        _command "helm plugin install https://github.com/chartmuseum/helm-push"
    	helm plugin install https://github.com/chartmuseum/helm-push
    fi

    _command "helm plugin list"
    helm plugin list
}

_helm_install() {
    _helm_init

    if [ -z ${NAME} ]; then
        _error "NAME is empty."
    fi
    if [ -z ${NAMESPACE} ]; then
        _error "NAMESPACE is empty."
    fi
    if [ -z ${VERSION} ]; then
        _error "VERSION is empty."
    fi

    _command "helm upgrade --install $NAME-$NAMESPACE --version $VERSION --namespace $NAMESPACE"
    helm upgrade --install $NAME-$NAMESPACE chartmuseum/$NAME \
                --version $VERSION --namespace $NAMESPACE --devel \
                --set fullnameOverride=$NAME-$NAMESPACE

    _command "helm history $NAME-$NAMESPACE"
    helm history $NAME-$NAMESPACE --max 5
}

_helm_delete() {
    _helm_init

    if [ -z ${NAME} ]; then
        _error "NAME is empty."
    fi
    if [ -z ${NAMESPACE} ]; then
        _error "NAMESPACE is empty."
    fi

    _command "helm search $NAME"
    helm search $NAME

    _command "helm history $NAME-$NAMESPACE"
    helm history $NAME-$NAMESPACE

    _command "helm delete --purge $NAME-$NAMESPACE"
    helm delete --purge $NAME-$NAMESPACE --max 5
}

_draft_init() {
    _command "draft version"
    draft version

    _command "draft init"
    draft init

    if [ ! -z ${REGISTRY} ]; then
        _command "draft config set registry ${REGISTRY}"
        draft config set registry ${REGISTRY}
    fi
}

_draft_pack() {
    if [ ! -f Dockerfile ]; then
        _error "File not found. [Dockerfile]"
    fi

    if [ -f draft.toml ]; then
        _read "Do you really want to apply? (YES/[no]) : "

        if [ "${ANSWER}" != "YES" ]; then
            exit 0
        fi
    fi

    _result "draft package version: ${THIS_VERSION}"

    mkdir -p charts/acme/templates

    DIST=/tmp/draft.tar.gz
    rm -rf ${DIST}

    # download
    curl -sL -o ${DIST} https://github.com/nalbam/toaster/releases/download/${THIS_VERSION}/draft.tar.gz

    if [ ! -f ${DIST} ]; then
        _error "Can not download."
    fi

    _result "draft package downloaded."

    # untar here
    tar -zxf ${DIST}

    mv -f dockerignore .dockerignore
    mv -f draftignore .draftignore

    # Jenkinsfile IMAGE_NAME
    DEFAULT=$(basename "$PWD")
    _chart_replace "Jenkinsfile" "IMAGE_NAME" "${DEFAULT}"

    if [ -d .git ]; then
        # Jenkinsfile REPOSITORY_URL
        DEFAULT=$(git remote -v | head -1 | awk '{print $2}')
        _chart_replace "Jenkinsfile" "REPOSITORY_URL" "${DEFAULT}"

        # Jenkinsfile REPOSITORY_SECRET
        DEFAULT=
        _chart_replace "Jenkinsfile" "REPOSITORY_SECRET" "${DEFAULT}"
    fi

    # Jenkinsfile SLACK_TOKEN
    DEFAULT=
    _chart_replace "Jenkinsfile" "SLACK_TOKEN" "${DEFAULT}"

    # values.yaml internalPort
    DEFAULT=8080
    _chart_replace "charts/acme/values.yaml" "internalPort" "${DEFAULT}" "yaml"
}

_draft_up() {
    _draft_init

    if [ ! -f draft.toml ]; then
        _error "Not found draft.toml"
    fi

    if [ -z ${NAME} ]; then
        _error "NAME is empty."
    fi
    if [ -z ${NAMESPACE} ]; then
        _error "NAMESPACE is empty."
    fi

    _command "sed -i -e s/NAMESPACE/${NAMESPACE}/g draft.toml"
    _replace "s/NAMESPACE/${NAMESPACE}/g" draft.toml

    _command "sed -i -e s/NAME/${NAME}-${NAMESPACE}/g draft.toml"
    _replace "s/NAME/${NAME}-${NAMESPACE}/g" draft.toml

    _command "draft up -e ${NAMESPACE}"
	draft up -e ${NAMESPACE}
}

_chart_replace() {
    REPLACE_FILE=$1
    REPLACE_KEY=$2
    DEFAULT_VAL=$3
    REPLACE_TYPE=$4

    if [ "${DEFAULT_VAL}" == "" ]; then
        _read "${REPLACE_KEY} : "
    else
        _read "${REPLACE_KEY} [${DEFAULT_VAL}] : "
    fi

    if [ -z ${ANSWER} ]; then
        REPLACE_VAL=${DEFAULT_VAL}
    else
        REPLACE_VAL=${ANSWER}
    fi

    if [ "${REPLACE_TYPE}" == "yaml" ]; then
        _command "sed -i -e s|${REPLACE_KEY}: .*|${REPLACE_KEY}: ${REPLACE_VAL}| ${REPLACE_FILE}"
        _replace "s|${REPLACE_KEY}: .*|${REPLACE_KEY}: ${REPLACE_VAL}|" ${REPLACE_FILE}
    else
        _command "sed -i -e s|${REPLACE_KEY} = .*|${REPLACE_KEY} = ${REPLACE_VAL}| ${REPLACE_FILE}"
        _replace "s|${REPLACE_KEY} = .*|${REPLACE_KEY} = \"${REPLACE_VAL}\"|" ${REPLACE_FILE}
    fi
}

_config_save_all() {
    echo "# toaster" > ${CONFIG}

    _config_save NAME ${NAME}
    _config_save BRANCH ${BRANCH}
    _config_save VERSION ${VERSION}
    _config_save NAMESPACE ${NAMESPACE}
    _config_save CLUSTER ${CLUSTER}
    _config_save SOURCE_LANG ${SOURCE_LANG}
    _config_save SOURCE_ROOT ${SOURCE_ROOT}
    _config_save BASE_DOMAIN ${BASE_DOMAIN}
    _config_save JENKINS ${JENKINS}
    _config_save REGISTRY ${REGISTRY}
    _config_save CHARTMUSEUM ${CHARTMUSEUM}
    _config_save SONARQUBE ${SONARQUBE}
    _config_save NEXUS ${NEXUS}
}

_config_save() {
    CONFIG_NAME=$1
    CONFIG_VALUE=$2

    echo "${CONFIG_NAME}=${CONFIG_VALUE}" >> ${CONFIG}
    printf "${CONFIG_VALUE}" > ${HOME}/${CONFIG_NAME}

    _result "${CONFIG_NAME}: ${CONFIG_VALUE}"
}

_config_remove() {
    rm -rf ${CONFIG}
    rm -rf ${HOME}/NAME BRANCH ${HOME}/VERSION ${HOME}/NAMESPACE ${HOME}/CLUSTER ${HOME}/SOURCE_LANG ${HOME}/SOURCE_ROOT
    rm -rf ${HOME}/BASE_DOMAIN ${HOME}/JENKINS ${HOME}/REGISTRY ${HOME}/CHARTMUSEUM ${HOME}/SONARQUBE ${HOME}/NEXUS
}

_domain_find() {
    TARGET_NAME=${1}

    DOMAIN=$(kubectl get ing -n ${NAMESPACE} -o wide | grep ${TARGET_NAME} | head -1 | awk '{print $2}' | cut -d',' -f1 | xargs)

    if [ ! -z ${DOMAIN} ] && [ ! -z ${BASE_DOMAIN} ]; then
        DOMAIN="${TARGET_NAME}-${NAMESPACE}.${BASE_DOMAIN}"
    fi

    echo "${DOMAIN}"
}

_maven_mirror() {
    if [ -f .m2/settings.xml ]; then
        cp -rf .m2/settings.xml ${HOME}/settings.xml
    else
        if [ -f /root/.m2/settings.xml ]; then
            cp -rf /root/.m2/settings.xml ${HOME}/settings.xml
        fi
    fi

    if [ -f ${HOME}/.NEXUS ]; then
        NEXUS=$(cat ${HOME}/.NEXUS)
    fi

    if [ -f ${HOME}/settings.xml ] && [ ! -z ${NEXUS} ]; then
        PUBLIC="http://${NEXUS}/repository/maven-public/"
        MIRROR="<mirror><id>mirror</id><url>${PUBLIC}</url><mirrorOf>*</mirrorOf></mirror>"
        _replace "s|<!-- ### configured mirrors ### -->|${MIRROR}|" ${HOME}/settings.xml
    fi
}

_version_build() {
    PATCH=
    REVISION=

    # SAMPLE=$(kubectl get ing sample-node -n default -o json | jq -r '.spec.rules[0].host')
    # SAMPLE=$(kubectl get ing -n default -o wide | grep sample-node | head -1 | awk '{print $2}')

    # if [ ! -z ${SAMPLE} ]; then
    #     PATCH=$(curl -sL -X POST http://${SAMPLE}/counter/${NAME} | xargs)
    # fi

    if [ -z ${PATCH} ]; then
        PATCH="1"
        REVISION=$(TZ=Asia/Seoul date +%Y%m%d-%H%M%S)
    elif [ -d .git ]; then
        REVISION=$(git rev-parse --short=6 HEAD)
    else
        REVISION="sample"
    fi

    if [ "${BRANCH}" == "master" ]; then
        VERSION="0.1.${PATCH}-${REVISION}"
    else
        VERSION="0.0.${PATCH}-${BRANCH}"
    fi
}

_language_scan() {
    TARGET_FILE=${1}
    TARGET_LANG=${2}

    TARGET_FIND=$(find . -name ${TARGET_FILE} | head -1)

    if [ ! -z ${TARGET_FIND} ]; then
        TARGET_ROOT=$(dirname ${TARGET_FIND})

        if [ ! -z ${TARGET_ROOT} ]; then
            SOURCE_LANG=${TARGET_LANG}
            SOURCE_ROOT=${TARGET_ROOT}
        fi
    fi
}

_toast

_success "done."
