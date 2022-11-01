#!/bin/sh
# detecting if the child router is disconnected from parent router with http://192.168.0.1

LOGTIME=$(date "+%Y-%m-%d %H:%M:%S")
wget --spider --quiet http://admin:admin@192.168.123.1:8080
if [ "$?" == "0" ]; then
        echo '['$LOGTIME'] No Problem.'
        exit 0
else
        echo '['$LOGTIME'] Problem decteted, restart aliyundrive-webdav.'
        echo '启动阿里云webdav'
        /opt/bin/aliyundrive-webdav --host 0.0.0.0 -I -p 8080 -r {refresh-token} -U admin -W admin > /dev/null &
fi
