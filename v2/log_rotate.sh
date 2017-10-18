#!/bin/bash

#### 매 시간 1회 돌려 주세요...

_BACKUP_DELETE_DATE="3"
_MIN=`date +%M`
_HOUR=`date +%H`

SLACK_HOOK="https://hooks.slack.com/services/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"
SLACK_CHANNEL="#alert_backup"
SLACK_USER="log-bot"
SLACK_ICON=":ghost:"

NGINX_LOG() {

    local _DATE="`date +%Y%m%d%H --date '-1 hours'`"
    local _DELETE_DAYS="`date +%Y%m%d --date '-2 days'`"

    FILENAME=`[[ -d /data/logs ]] && find /data/logs -name "*.log" ; \
              [[ -d /data/logs ]] && find /data/logs -name "*.json" ; \
              [[ -d /data/weblog ]] && find /data/weblog -name "*.log" ; \
              [[ -d /data/weblog ]] && find /data/weblog -name "*.json"`

    for i in ${FILENAME}
    do
    	cp $i $i-"$_DATE"
    	cp /dev/null $i
    done
    [ -f /usr/local/nginx/logs/nginx.pid ] && kill -USR1 `cat /usr/local/nginx/logs/nginx.pid`

    [[ -d /data/logs ]] && find /data/logs -name "*-$_DELETE_DAYS*" -exec rm -fv {} \;
    [[ -d /data/weblog ]] && find /data/weblog -name "*-$_DELETE_DAYS*" -exec rm -fv {} \;

}

BACKUP_NGINX() {

    [[ -d /data/weblog ]] && \
        /usr/bin/rsync -avzr --rsh="/usr/bin/sshpass -p LogServer1! ssh -p 2230 -o ConnectTimeout=3 -o StrictHostKeyChecking=no -o ServerAliveInterval=60 -l logserver" \
        /data/weblog/* 12.0.1.164:/aws_s3/nginx_log/${HOSTNAME}/ ; find /data/weblog -mtime +${_BACKUP_DELETE_DATE} -exec rm -fv {} \;
    [[ -d /data/logs ]] && \
        /usr/bin/rsync -avzr --rsh="/usr/bin/sshpass -p LogServer1! ssh -p 2230 -o ConnectTimeout=3 -o StrictHostKeyChecking=no -o ServerAliveInterval=60 -l logserver" \
        /data/logs/* 12.0.1.164:/aws_s3/nginx_log/${HOSTNAME}/ ; find /data/logs -mtime +${_BACKUP_DELETE_DATE} -exec rm -fv {} \;

}

BACKUP_JAVA() {

    [[ -d /data/weblog ]] && \
        /usr/bin/rsync -avzr --rsh="/usr/bin/sshpass -p LogServer1! ssh -p 2230 -o ConnectTimeout=3 -o StrictHostKeyChecking=no -o ServerAliveInterval=60 -l logserver" \
        /data/weblog/* 12.0.1.164:/aws_s3/tomcat_log/${HOSTNAME}/ ; find /data/weblog -mtime +${_BACKUP_DELETE_DATE} -exec rm -fv {} \;
    [[ -d /data/logs ]] && \
        /usr/bin/rsync -avzr --rsh="/usr/bin/sshpass -p LogServer1! ssh -p 2230 -o ConnectTimeout=3 -o StrictHostKeyChecking=no -o ServerAliveInterval=60 -l logserver" \
        /data/logs/* 12.0.1.164:/aws_s3/tomcat_log/${HOSTNAME}/ ; find /data/logs -mtime +${_BACKUP_DELETE_DATE} -exec rm -fv {} \;
    [[ -d /data/apps/tomcat8/logs ]] && \
        /usr/bin/rsync -avzr --rsh="/usr/bin/sshpass -p LogServer1! ssh -p 2230 -o ConnectTimeout=3 -o StrictHostKeyChecking=no -o ServerAliveInterval=60 -l logserver" \
        /data/apps/tomcat8/logs/* 12.0.1.164:/aws_s3/tomcat_log/${HOSTNAME}/ ; find /data/apps/tomcat8/logs/ -mtime +${_BACKUP_DELETE_DATE} -exec rm -fv {} \;

}

BACKUP_APACHE() {

    [[ -d /data/weblog ]] && \
        /usr/bin/rsync -avzr --rsh="/usr/bin/sshpass -p LogServer1! ssh -p 2230 -o ConnectTimeout=3 -o StrictHostKeyChecking=no -o ServerAliveInterval=60 -l logserver" \
        /data/weblog/* 12.0.1.164:/aws_s3/apache_log/product/${HOSTNAME}/ ; find /data/weblog -mtime +${_BACKUP_DELETE_DATE} -exec rm -fv {} \;
    [[ -d /data/logs ]] && \
        /usr/bin/rsync -avzr --rsh="/usr/bin/sshpass -p LogServer1! ssh -p 2230 -o ConnectTimeout=3 -o StrictHostKeyChecking=no -o ServerAliveInterval=60 -l logserver" \
        /data/logs/* 12.0.1.164:/aws_s3/apache_log/product/${HOSTNAME}/ ; find /data/logs -mtime +${_BACKUP_DELETE_DATE} -exec rm -fv {} \;

}

SLACK_MESSAGE() {
    MESSAGE="$1"
    DATETIME=`date +%Y%m%d%H --date '-1 hours'`
    curl -X POST --data-urlencode \
        'payload={ "channel": "'${SLACK_CHANNEL}'", "username": "'${SLACK_USER}'", "text": "['${DATETIME}'] '${HOSTNAME}' '${MESSAGE}' ...", "icon_emoji": "'${SLACK_ICON}'" }' \
        ${SLACK_HOOK}
}

### Nginx 일 경우
if [ -f /usr/sbin/nginx ]; then
    if [ ${_MIN} == 00 ]; then
        NGINX_LOG
        if [ $? -ne 0 ]; then
            SLACK_MESSAGE "Nginx log-rotate Error"
        fi
    fi
    if [ ${_HOUR} == 03 ]; then
        BACKUP_NGINX
        if [ $? -ne 0 ]; then
            SLACK_MESSAGE "Backup server nginx log Upload Error"
        fi
    fi
fi

### JAVA & Tomcat 일 경우
if [ -f /usr/local/java/bin/java ]; then
    if [ ${_HOUR} == 04 ]; then
        BACKUP_JAVA
        if [ $? -ne 0 ]; then
            SLACK_MESSAGE "Backup server java log Upload Error"
        fi
    fi
fi

### Apache 일 경우
if [ -f /usr/sbin/httpd ]; then
    if [ ${_HOUR} == 05 ]; then
        BACKUP_APACHE
        if [ $? -ne 0 ]; then
            SLACK_MESSAGE "Backup server apache log Upload Error"
        fi
    fi
elif [ -f /usr/local/apache/bin/httpd ]; then
    if [ ${_HOUR} == 05 ]; then
        BACKUP_APACHE
        if [ $? -ne 0 ]; then
            SLACK_MESSAGE "Backup server apache log Upload Error"
        fi
    fi
fi
