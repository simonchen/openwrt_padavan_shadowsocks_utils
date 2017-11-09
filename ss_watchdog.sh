#!/bin/sh
 
LOGTIME=$(date "+%Y-%m-%d %H:%M:%S")
wget --spider --quiet http://www.google.com/
if [ "$?" == "0" ]; then
	echo '['$LOGTIME'] No Problem.'
	exit 0
else
	wget --spider --quiet http://www.baidu.com/
	if [ "$?" == "0" ]; then
		echo '['$LOGTIME'] Problem decteted, restarting shadowsocks.'
		/etc/init.d/shadowsocks restart >/dev/null
	else
		echo '['$LOGTIME'] Network Problem. Do nothing.'
	fi
fi
