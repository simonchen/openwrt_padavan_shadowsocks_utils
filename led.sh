#!/bin/sh

y=13 #d3
r=14 #d1
b=16 #sys

timer() {
  $(for i in $(seq 1 1000); do i=$i; done) 
}

blink() {
  led=$1
  times=2
  if [ ! -z "$2" ]; then
    times=$2
  fi
  
  mtk_gpio -w $r 1 && mtk_gpio -w $b 1 && mtk_gpio -w $y 1
  for i in $(seq 1 $times); do
    #echo blink="$i"
    mtk_gpio -w $led 1
    timer
    mtk_gpio -w $led 0
    timer
  done
}

blink_yellow() {
  blink $y "$1"
}

blink_red() {
  blink $r "$1"
}

blink_blue() {
  blink $b "$1"
}

case "$1" in
  yellow)
    blink_yellow "$2"
    ;;
  red)
    blink_red "$2"
    ;;
  blue)
    blink_blue "$2"
    ;;
  *)
  echo "Usage: $0 {yellow|red|blue} {times}"
  exit 1
esac 
