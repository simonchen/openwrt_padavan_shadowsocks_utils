#!/bin/sh
#copyright by simonchen
#the script run as daemon prieodically binding the symbolic link in /opt/bin for the existing apps (kcptun/udp2raw/frpc)
#auto-monitor and restart kcptun/udp2raw with specific parameters - [server] [ports] [key]
#udp2raw listen [::1]:8388
#kcptun listen [::1]:3333
#in addition, disabling the logs with crond, ntp sync.

server="$1"
ports="$2"
key="$3"
if [[ -z "$server" || -z "$ports" || -z "$key" ]]; then
  echo "Usage: $(basename $0) [server] [ports] [key]"
  exit 1
fi

##################################################################
#
#  守护udp2raw
#
##################################################################
udp2raw_sh="cron_udp.sh"
cat >/tmp/$udp2raw_sh <<'EOF'
#!/bin/sh
#start udp2raw
EOF
cat <<EOF >> /tmp/$udp2raw_sh
server="$server"
ports="$ports"
key="$key"
EOF
cat >>/tmp/$udp2raw_sh <<'EOF'
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
  for port in $ports; do
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
    continue
  fi
  echo "avail_port="$avail_port
  logger -t "【启动udp2raw】" "用服务端口$avail_port"
  killall udp2raw
  /opt/bin/udp2raw --fix-gro -c -l[::1]:3333 -r$server:$avail_port -a -k "$key" --cipher-mode xor --raw-mode icmp >/dev/null 2>&1 &
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
EOF
cat <<EOF >> /tmp/$daemon_sh
key="$key"
EOF
cat >>/tmp/$daemon_sh <<'EOF'
start_udp2raw() {
  udp2raw_sh="cron_udp.sh"
  killall $udp2raw_sh
  chmod +x /tmp/$udp2raw_sh && /tmp/$udp2raw_sh 2>&1 &
}

start_kcptun() {
  if [ ! -f "/opt/bin/kcptun" ]; then
    return
  fi
  killall kcptun
  /opt/bin/kcptun -conn 4 -sockbuf 8388608 -l [::1]:8388 -r "[::1]:3333" -l ":8388" -key "$key" -mtu 1350 -sndwnd 192 -rcvwnd 900 -crypt xor -mode fast3 -dscp 0 -datashard 0 -parityshard 0 -autoexpire 0 -nocomp  >/dev/null 2>&1 &
}

ntp_log() {
  LOGTIME=$(date "+%Y-%m-%d %H:%M:%S")
  logger -t "【ntpd时间同步】" "$LOGTIME"
}

total_secs=0
sleep_secs=2
ntp_secs=600

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
  if [ $(ps | grep -E "[u]dp2raw" | wc -l) == 0 ]; then
    logger -s -t "【 本地应用守护】" "udp2raw没有启动, 重新开始!"
    start_udp2raw
  fi
  if [ $(ps | grep -E "[k]cptun" | wc -l) == 0 ]; then
    logger -s -t "【 本地应用守护】" "kcptun没有启动, 重新开始!"
    start_kcptun
  fi

  # crond daemon - no logging output
  if [ $(ps | grep -E "[c]rond -l 15" | wc -l) == 0 ]; then
    logger -s -t "【 本地应用守护】" "crond不输出日志!"
    killall crond
    crond -l 15 >/dev/null 2>&1 &
  fi

  if [ "$(expr $total_secs \% $ntp_secs)" == "0" ]; then    
    ntpd -n -q -p cn.pool.ntp.org >/dev/null 2>&1
    LOGTIME=$(date "+%Y-%m-%d %H:%M:%S")
    logger -t "【ntpd时间同步】" "$LOGTIME"
  fi
  
  sleep $sleep_secs
  total_secs=$(expr $total_secs \+ $sleep_secs)
done
EOF

killall $daemon_sh
chmod +x /tmp/$daemon_sh && /tmp/$daemon_sh 2>&1 &

exit 0