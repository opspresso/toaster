#!/bin/bash

############################################################

function usage() {
  echo "Usage: $0 {user} {host} {port:22}"
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
PARAM3=${7}
PARAM4=${8}
PARAM5=${9}
PARAM6=${10}

if [ "${HOST}" == "" ]; then
  usage
  exit 1
fi

if [ "${PORT}" == "" ]; then
  PORT=22
fi

COMMAND="~/toaster/toast.sh ${CMD} ${PARAM1} ${PARAM2} ${PARAM3} ${PARAM4} ${PARAM5} ${PARAM6}"

ssh -t ${USER}@${HOST} -p ${PORT} "${COMMAND}"
