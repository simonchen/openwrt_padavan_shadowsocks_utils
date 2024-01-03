#!/bin/sh

#watch -n1 echo -e '\\rRX total: $(cat /sys/class/net/$(nvram get wan0_ifname)/statistics/rx_bytes) bytes, TX total: $(cat /sys/class/net/$(nvram get wan0_ifname)/statistics/tx_bytes) bytes'

while true; do
  r1=$(cat /sys/class/net/$(nvram get wan0_ifname)/statistics/rx_bytes)
  sleep 1
  r2=$(cat /sys/class/net/$(nvram get wan0_ifname)/statistics/rx_bytes)
  rate=$(expr $(expr $r2 \- $r1) \/ 1024)
  echo -e "\\r$rate" kb/s
done
