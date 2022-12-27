#!/bin/sh

if [ "$1" == "stop" ]; then
  killall dnsmasq_watch.sh
  exit 0
fi

while true; do
  instances=$(ps | grep /usr/sbin/dnsmasq | wc -l)
  echo $instances
  [ "$instances" -le 2 ] && sleep 2 && continue
  logger -s -t "dnsmasq instances > 2" "restart!"
  #killall dnsmasq && /usr/sbin/dnsmasq
done
