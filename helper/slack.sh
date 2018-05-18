#!/bin/bash

usage() {
    #figlet slack
    echo "================================================================================"
    echo "      _            _ "
    echo "  ___| | __ _  ___| | __ "
    echo " / __| |/ _' |/ __| |/ / "
    echo " \__ \ | (_| | (__|   < "
    echo " |___/_|\__,_|\___|_|\_\  by nalbam"
    echo "================================================================================"
    echo " Usage: slack.sh {webhook_url} {channel} {message}"
    echo "================================================================================"

    exit 1
}

# ------------
webhook_url=$1
if [[ "${webhook_url}" == "" ]]; then
    usage
fi

# ------------
shift
channel=$1
if [[ "${channel}" == "" ]]; then
    usage
fi

# ------------
shift
text=$*

if [[ "${text}" == "" ]]; then
    while IFS= read -r line; do
        text="$text$line\n"
    done
fi

if [[ "${text}" == "" ]]; then
    usage
fi

message=$(echo ${text} | sed 's/"/\"/g' | sed "s/'/\'/g")

json="{\"channel\": \"$channel\", \"attachments\":[{\"text\": \"$message\"}]}"

curl -s -d "payload=$json" "$webhook_url"
