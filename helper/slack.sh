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
    echo " Usage: slack.sh [args] message "
    echo " "
    echo " Arguments: "
    echo "   webhook_url"
    echo "   channel"
    echo "   icon_emoji"
    echo "   username="
    echo "   color"
    echo "   message"
    echo "================================================================================"

    exit 1
}

debug=
webhook_url=
channel=
icon_emoji=
username=
color=
text=

for v in "$@"; do
    case ${v} in
    -w=*|--webhook_url=*)
        webhook_url="${v#*=}"
        shift
        ;;
    --channel=*)
        channel="${v#*=}"
        shift
        ;;
    --icon_emoji=*)
        icon_emoji="${v#*=}"
        shift
        ;;
    --username=*)
        username="${v#*=}"
        shift
        ;;
    --color=*)
        color="${v#*=}"
        shift
        ;;
    *)
        text=$*
        break
        ;;
    esac
done

if [ "${webhook_url}" == "" ]; then
    usage
fi
if [ "${text}" == "" ]; then
    usage
fi

message=$(echo ${text} | sed 's/"/\"/g' | sed "s/'/\'/g")

json="{"
    if [ "${channel}" != "" ]; then
        json="$json\"channel\":\"${channel}\","
    fi
    if [ "${icon_emoji}" != "" ]; then
        json="$json\"icon_emoji\":\"${icon_emoji}\","
    fi
    if [ "${username}" != "" ]; then
        json="$json\"username\":\"${username}\","
    fi
    json="$json\"attachments\":[{"
        if [ "${color}" != "" ]; then
            json="$json\"color\":\"${color}\","
        fi
        json="$json\"text\":\"${message}\""
    json="$json}]"
json="$json}"

if [ "${debug}" == "" ]; then
    curl -s -d "payload=${json}" "${webhook_url}"
else
    echo "url=${webhook_url}"
    echo "payload=${json}"
fi
