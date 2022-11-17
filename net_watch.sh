#!/bin/sh
# detecting if the child router is disconnected from parent router with http://192.168.0.1

LOGTIME=$(date "+%Y-%m-%d %H:%M:%S")
wget --spider --quiet http://192.168.0.1
if [ "$?" == "0" ]; then
        echo '['$LOGTIME'] No Problem.'
        net_port=$(netstat -a | grep "9100")
        echo "$net_port"
        if [ -z "$net_port" ]; then
                echo "print service was down. restarting..."
                /etc/init.d/p910nd start > /dev/null
        fi
        exit 0
else
        echo '['$LOGTIME'] Problem decteted, restarting network.'
        # restarts USB printer
        /etc/init.d/p910nd restart > /dev/null
        # restarts network
        /etc/init.d/network restart >/dev/null
fi
