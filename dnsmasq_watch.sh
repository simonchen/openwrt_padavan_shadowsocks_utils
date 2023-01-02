#!/bin/sh

if [ "$1" == "stop" ]; then
  killall dnsmasq_watch.sh
  exit 0
fi

while true; do
  instances=$(ps | grep /usr/sbin/dnsmasq | wc -l)
  min_free_kb=$(expr $(cat /proc/sys/vm/min_free_kbytes) \* 3)
  cur_free_kb=$(cat /proc/meminfo | grep 'MemFree:' | sed -E 's/MemFree\:[^0-9]+(.+) kb/\1/i')
  f=$(expr $cur_free_kb \<= $min_free_kb)
  echo 'dnsmasq insts='$instances
  echo 'min_free_kb='$min_free_kb
  echo 'cur_free_kb='$cur_free_kb
  echo 'f='$f
  [ $f -eq 0 ] && [ "$instances" -le 10 ] && sleep 1 && continue
  logger -s -t ">>> dnsmasq instances > 10 and the available memory is too low: $cur_free_kb kB" "restart!"
  killall dnsmasq && /usr/sbin/dnsmasq
done
