#!/bin/sh

start_eth(){
  eth="$1"
  while true; do
    if [ `ip link | grep eth2 | awk '{print $3}' | grep 'UP'` ]; then
      break
    else
      logger -t "eth.sh" "try to restart $eth"
      ifconfig $eth up
    fi
  done
}

stop_eth(){
  eth="$1"
  ifconfig $eth down
  logger -t "eth.sh" "$eth is stopped"
}

case $1 in
start)
        start_eth $2
        ;;
stop)
        stop_eth $2
        ;;
esac
