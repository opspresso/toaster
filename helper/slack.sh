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
    echo " Usage: slack.sh -w {webhook} -n {channel} -i {icon} -u {username} -c {color} -m {message}"
    echo "================================================================================"

    exit 1
}

url=
channel=
icon_emoji=
username=
color=
text=

while getopts ":w:c:m:n:u:i:" opt; do
  case ${opt} in
    w)
      url="$OPTARG"
      ;;
    n)
      channel="$OPTARG"
      ;;
    c)
      color="$OPTARG"
      ;;
    i)
      icon_emoji="$OPTARG"
      ;;
    u)
      username="$OPTARG"
      ;;
    m)
      text="$OPTARG"
      ;;
    \?)
      echo "Invalid option: -$OPTARG"
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument."
      exit 1
      ;;
  esac
done

if [ "${url}" == "" ]; then
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
json="$json}]}"

#echo "url=$url"
#echo "payload=$json"

curl -s -d "payload=$json" "$url"
