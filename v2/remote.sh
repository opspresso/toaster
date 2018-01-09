#!/bin/bash

############################################################

function usage() {
    echo "Usage: $0 {user} {host} {port:22}"
    exit 1
}

############################################################

BASEDIR=$(dirname $0)
cd ${BASEDIR}

USER=${1}
HOST=${2}
PORT=${3}

CMD=${4}

PARAM1=${5}
PARAM2=${6}

if [ "${HOST}" == "" ]; then
    usage
fi

if [ "${PORT}" == "" ]; then
    PORT=22
fi

COMMAND="~/toaster/toast.sh ${CMD} ${PARAM1} ${PARAM2}"

ssh -t ${USER}@${HOST} -p ${PORT} "${COMMAND}"
