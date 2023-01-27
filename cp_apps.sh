#!/bin/sh
#copyright by simonchen
# the script run as daemon prieodically binding the symbolic link in /opt/bin for the existing apps (kcptun/udp2raw/frpc)
# auto-monitor and restart kcptun/udp2raw with specific parameters - [server] [ports] [key]
# udp2raw listen [::1]:8388
# kcptun listen [::1]:3333
# In addition,
# 1. disabling the logs with crond, ntp sync.
# 2. auto-restart kcptun/udp2raw if it continously failed to visit google.com
# 3. Replace dnsmasq with latest version 2.89
# 4. Reboot router if internet connection fails on continuous 10 retries.

basename=$(basename $0)

server="$1"
ports="$2"
key="$3"
if [[ -z "$server" || -z "$ports" || -z "$key" ]]; then
  echo "Usage: $basename [server] [ports] [key]"
  exit 1
fi

daemon_sh="cron_$(basename $0)"
udp2raw_sh="cron_udp.sh"

# Reset daemon / udp2raw 
killall $udp2raw_sh $daemon_sh

##################################################################
#
#  守护udp2raw
#
##################################################################
cat >/tmp/$udp2raw_sh <<'EOF'
#!/bin/sh
#start udp2raw
EOF
cat <<EOF >> /tmp/$udp2raw_sh
daemon_sh="$daemon_sh"
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

interval_secs=21600 # must be even number
total_secs=0
sleep_secs=2
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
  while true; do
    # see if main daemon_sh is dead?
    if [ $(ps | grep -E "[\/]$daemon_sh" | wc -l) == 0 ]; then
      killall $daemon_sh
      chmod +x /tmp/$daemon_sh && /tmp/$daemon_sh 2>&1 &
    fi
    sleep $sleep_secs
    total_secs=$(expr $total_secs \+ $sleep_secs)
    total_mins=$(expr $total_secs \/ 60)
    if [ $(expr $total_secs \% $interval_secs) == 0 ]; then
      logger -t "【udp2raw】" "已经运行$total_mins分钟, 开始切换端口."
      break
    fi
  done
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
udp2raw_sh="$udp2raw_sh"
EOF
cat >>/tmp/$daemon_sh <<'EOF'
# Replace dnsmasq with latest version 2.89
restart_dnsmasq() {
  umount -fl /usr/sbin/dnsmasq
  mount -o bind /etc/storage/apps/dnsmasq /usr/sbin/dnsmasq
  killall dnsmasq
  /usr/sbin/dnsmasq 2>&1 &
}
restart_dnsmasq

start_udp2raw() {
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

inet_check() {
  #wget --spider --quiet https://www.google.com/favicon.ico -O - >/dev/null 2>&1
  #echo $?
  r=$(curl --silent --show-error --connect-timeout 5 -I https://www.google.com | grep -E "HTTP\/.+ 200 OK")
  if [ -z "$r" ]; then
    echo "1"
  else
    echo "0"
  fi
}

total_secs=0
sleep_secs=2
ntp_secs=600 # must be even number
inet_check_interval=60
inet_fail_count=0
inet_fail_max=3 # this value will be increased on restart

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
  if [[ $(ps | grep -E "[\/]udp2raw" | wc -l) == 0 || $(ps | grep -E "[\/]$udp2raw_sh" | wc -l) == 0 ]]; then
    logger -s -t "【 本地应用守护】" "udp2raw没有启动, 重新开始!"
    start_udp2raw
  fi
  if [ $(ps | grep -E "[\/]kcptun" | wc -l) == 0 ]; then
    logger -s -t "【 本地应用守护】" "kcptun没有启动, 重新开始!"
    start_kcptun
  fi

  # crond daemon - no logging output
  if [ $(ps | grep -E "[c]rond -l 15" | wc -l) == 0 ]; then
    logger -s -t "【 本地应用守护】" "crond不输出日志!"
    killall crond
    crond -l 15 >/dev/null 2>&1 &
  fi
  orig_crond_proc_id="$(ps | grep -E "[c]rond$" | awk {'print$1'})"
  if [ ! -z $orig_crond_proc_id ]; then
    kill $orig_crond_proc_id
  fi

  if [ "$(expr $total_secs \% $ntp_secs)" == "0" ]; then    
    ntpd -n -q -p cn.pool.ntp.org >/dev/null 2>&1
    LOGTIME=$(date "+%Y-%m-%d %H:%M:%S")
    logger -t "【ntpd时间同步】" "$LOGTIME"
  fi

  if [ "$(expr $total_secs \% $inet_check_interval)" == "0" ]; then
    if [ "$(inet_check)" == "0" ]; then
      #logger -t "【科学上网】" "正常"
      inet_fail_count=0
      inet_fail_max=3
    else
      inet_fail_count=$(expr $inet_fail_count \+ 1)
      logger -t "【科学上网】" "连续失败$inet_fail_count次"
      if [ $inet_fail_count -ge $inet_fail_max ]; then
        inet_fail_count=0
	if [ $inet_fail_max -ge 10 ]; then
	  logger -t "【重启路由器】" "尝试连接google.com失败, 达到连续失败次数$inet_fail_max"
	  reboot
	else
	  logger -t "【自动重启kcptun/udp2raw】" "原因：无法正常访问google.com"
	  restart_dnsmasq
          start_udp2raw
	  start_kcptun
	fi
	inet_fail_max=$(expr $inet_fail_max \+ 1) # max failures increased by 1
      fi
    fi
  fi
  
  sleep $sleep_secs
  total_secs=$(expr $total_secs \+ $sleep_secs)
done
EOF

chmod +x /tmp/$daemon_sh && /tmp/$daemon_sh 2>&1 &

exit 0
