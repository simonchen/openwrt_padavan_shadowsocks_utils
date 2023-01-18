#!/bin/sh

##################################################################
#
#  守护udp2raw
#
##################################################################
udp2raw_sh="cron_udp2raw.sh"
cat >/tmp/$udp2raw_sh <<'EOF'
#!/bin/sh
#start udp2raw
if [ ! -f "/opt/bin/udp2raw" ]; then
  exit 1
fi
udp2raw_port_file=/tmp/udp2raw_port.txt
get_udp2raw_port() {
  if [ ! -f "$udp2raw_port_file" ]; then
    echo ""
    return
  fi
  echo $(cat "$udp2raw_port_file")
}

set_udp2raw_port() {
  echo $1 > $udp2raw_port_file
}

clear_udp2raw_port() {
  echo "" > $udp2raw_port_file
}

while true; do
  avail_port=
  # 打开下面一行，用IPV6端口，ICMP协议
  for port in 14097 14098 14087 14088; do
  # 打开下面一行，用IPV6端口，FAKETCP协议
  #for port in 4099 4100; do
    cur_port=$(get_udp2raw_port)
    #echo "cur_port="$cur_port
    val=$(echo "$cur_port" | grep $port)
    #echo "val="$val
    if [ ! -z "$val" ]; then
      continue
    fi
    if [ -z "$cur_port" ]; then
      cur_port="$port"
    else
      cur_port="$cur_port:$port"
    fi
    set_udp2raw_port "$cur_port"
    avail_port=$port
    break
  done

  if [ -z "$avail_port" ]; then
    clear_udp2raw_port
    set_udp2raw_port "14097"
    avail_port=$(get_udp2raw_port)
  fi
  echo "avail_port="$avail_port
  logger -t "【启动udp2raw】" "用服务端口$avail_port"
  killall udp2raw
  /opt/bin/udp2raw --fix-gro -c -l[::1]:3333 -r[2604:180:3:1a5::37b4]:$avail_port -a -k "schmap1221" --cipher-mode xor --raw-mode icmp >/dev/null 2>&1 &
  sleep 21600
done
EOF

##################################################################
#
#  启动本地应用守护kcptun/udp2raw/frpc
#
##################################################################
logger -s -t "【 启动本地应用守护kcptun/udp2raw/frpc】" "加速启动"
daemon_sh="cron_$(basename $0)"

cat >/tmp/$daemon_sh <<'EOF'
#!/bin/sh
#auto-link local apps to /opt/bin/
#auto-startup kcptun/udp2raw 

start_udp2raw() {
  udp2raw_sh="cron_udp2raw.sh"
  killall $udp2raw_sh
  chmod +x /tmp/$udp2raw_sh && /tmp/$udp2raw_sh 2>&1 &
}

start_kcptun() {
  if [ ! -f "/opt/bin/kcptun" ]; then
    return
  fi
  killall kcptun
  /opt/bin/kcptun -conn 4 -sockbuf 8388608 -l [::1]:8388 -r "[::1]:3333" -l ":8388" -key schmap1221 -mtu 1350 -sndwnd 192 -rcvwnd 900 -crypt xor -mode fast3 -dscp 0 -datashard 0 -parityshard 0 -autoexpire 0 -nocomp  &
}

while true
do
  if [ ! -f "/opt/bin/kcptun" ]; then
    logger -s -t "【 本地应用守护】" "找不到/opt/bin/kcptun, 重新链接!"
    ln -s /etc/storage/apps/kcptun /opt/bin/kcptun
  fi
  if [ ! -f "/opt/bin/udp2raw" ]; then  
    logger -s -t "【 本地应用守护】" "找不到/opt/bin/udp2raw, 重新链接!"
    ln -s /etc/storage/apps/udp2raw /opt/bin/udp2raw
  fi
  if [ ! -f "/opt/bin/frpc" ]; then
    logger -s -t "【 本地应用守护】" "找不到/opt/bin/frpc, 重新链接!"
    ln -s /etc/storage/apps/frpc /opt/bin/frpc
  fi
  if [ $(ps | grep -E [u]dp2raw | wc -l) == 0 ]; then
    logger -s -t "【 本地应用守护】" "udp2raw没有启动, 重新开始!"
    start_udp2raw
  fi
  if [ $(ps | grep -E [k]cptun | wc -l) == 0 ]; then
    logger -s -t "【 本地应用守护】" "kcptun没有启动, 重新开始!"
    start_kcptun
  fi
  
  sleep 2
done
EOF

killall $daemon_sh
chmod +x /tmp/$daemon_sh && /tmp/$daemon_sh 2>&1 &

exit 0
