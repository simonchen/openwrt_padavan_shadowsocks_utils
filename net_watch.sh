#!/bin/sh
# detecting if the child router is disconnected from parent router with http://192.168.0.1
#!/bin/sh
# detecting if the child router is disconnected from parent router

LOGTIME=$(date "+%Y-%m-%d %H:%M:%S")
ok=0
for i in {1..10};do
  wget --spider --quiet http://192.168.0.1
  if [ "$?" == "0" ]; then
    ok=1
    break
  fi
  sleep 1
done
echo network is $ok

if [ $ok == 1 ]; then
        echo '['$LOGTIME'] No Problem.'
        echo 'check print service port 9100'
        net_port=$(netstat -a | grep "9100")
        echo "$net_port"
        if [ -z "$net_port" ]; then
                echo "print service was down. restarting..."
                /etc/init.d/p910nd restart > /dev/null
        fi
        exit 0
else
        echo '['$LOGTIME'] Problem decteted, restarting network.'
        /etc/init.d/network restart >/dev/null
fi
