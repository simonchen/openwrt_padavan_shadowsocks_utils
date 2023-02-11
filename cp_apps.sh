#!/bin/sh
#copyright by simonchen
# the script run as daemon prieodically binding the symbolic link in /opt/bin for the existing apps (kcptun/udp2raw)
# auto-monitor and restart kcptun/udp2raw with specific parameters - [server] [ports] [key]
# udp2raw listen [::1]:8388
# kcptun listen [::1]:3333
# In addition,
# 1. disabling the logs with crond, ntp sync.
# 2. auto-restart kcptun/udp2raw if it continously failed to visit google.com
# 3. Replace dnsmasq with latest version 2.89
# 4. Restart WAN if internet connection fails with continuous 10 retries.

basedir=$(cd $(dirname $0) && pwd)
basename=$(basename $0)

server="$1"
ports="$2"
key="$3"
if [[ -z "$server" || -z "$ports" || -z "$key" ]]; then
  echo "Usage: $basename [server] [ports] [key]"
  exit 1
fi

daemon_sh="padavan-d.sh"
daemon_status="padavan-d.status"
daemon_sub_sh="padavan-ds.sh"
daemon_sub_status="padavan-ds.status"

# Reset daemon 
pgrep padavan | xargs kill >/dev/nulll 2>&1 
rm -f /tmp/$daemon_sub_status 
rm -f /tmp/$daemon_status

# Replace dnsmasq with latest version 2.89
restart_dnsmasq() {
  if [ -f $basedir/dnsmasq ]; then
    umount -fl /usr/sbin/dnsmasq
    mount -o bind $basedir/dnsmasq /usr/sbin/dnsmasq
    killall dnsmasq >/dev/null 2>&1
    /usr/sbin/dnsmasq 2>&1 &
  fi
}

##################################################################
#
#  sub-daemon守护
#
##################################################################
cat >/tmp/$daemon_sub_sh <<'EOF'
#!/bin/sh
#daemon sub-process
EOF
cat <<EOF >> /tmp/$daemon_sub_sh
logger -s -t "【 sub-daemon 本地应用守护】" "启动"
basedir="$basedir"
daemon_sh="$daemon_sh"
daemon_status="$daemon_status"
daemon_sub_sh="daemon_sub_sh"
daemon_sub_status="$daemon_sub_status"

server="$server"
ports="$ports"
key="$key"
EOF
cat >>/tmp/$daemon_sub_sh <<'EOF'
udp2raw_port_file=/tmp/udp2raw_port.txt

read_total_secs() {
  s=""
  if [ -f "/tmp/$daemon_sub_status" ]; then
    s="$(cat /tmp/$daemon_sub_status | grep "runtime=" | sed -E "s/runtime=([0-9]+)/\1/")"
  fi
  echo "$s"
}

write_total_secs() {
  s="$1"
  if [ -f /tmp/$daemon_sub_status ]; then
    sed -i "/runtime=/d" /tmp/$daemon_sub_status
  fi
  echo "runtime=$s" >> /tmp/$daemon_sub_status
}

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

selfkill_secs=3600 # must be even number
interval_secs=21600 # must be even number
total_secs=$(read_total_secs)
if [ -z "$total_secs" ]; then
  total_secs=0
fi
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
  #echo "avail_port="$avail_port
  if [[ -z "$(pgrep udp2raw)" && -f "/opt/bin/udp2raw" ]]; then
    logger -t "【启动udp2raw】" "用服务端口$avail_port"
    killall udp2raw >/dev/null 2>&1 
    /opt/bin/udp2raw --fix-gro -c -l[::1]:3333 -r$server:$avail_port -a -k "$key" --cipher-mode xor --raw-mode icmp >/dev/null 2>&1 &
  fi
  while true; do
    # see if main daemon_sh is dead?
    if [ -z "$(pgrep $daemon_sh)" ]; then
      killall $daemon_sh >/dev/null 2>&1
      chmod +x /tmp/$daemon_sh && /tmp/$daemon_sh 2>&1 &
    fi
    sleep $sleep_secs
    total_secs=$(expr $total_secs \+ $sleep_secs)
    $(write_total_secs $total_secs)
    total_mins=$(expr $total_secs \/ 60)
    if [ $(expr $total_secs \% $interval_secs) -eq 0 ]; then
      logger -t "【udp2raw】" "已经运行$total_mins分钟, 开始切换端口."
      break
    fi
    if [[ $(expr $total_secs \% $selfkill_secs) -eq 0 && ! -z "$(pgrep $daemon_sh)" ]]; then
      logger -t "【sub-daemon守护】" "已经运行$total_mins分钟, 自重启."
      killall $daemon_sub_sh >/dev/null 2>&1
    fi
  done
done
EOF

##################################################################
#
#  main-daemon 本地应用守护
#
##################################################################
logger -s -t "【 main-daemon 本地应用守护】" "启动"

cat >/tmp/$daemon_sh <<'EOF'
#!/bin/sh
#auto-link local apps to /opt/bin/
#auto-monitor apps such as kcptun/udp2raw 
EOF
cat <<EOF >> /tmp/$daemon_sh
key="$key"
basedir="$basedir"
daemon_sh="$daemon_sh"
daemon_status="$daemon_status"
daemon_sub_sh="$daemon_sub_sh"
daemon_sub_status="$daemon_sub_status"
EOF
cat >>/tmp/$daemon_sh <<'EOF'


# LED control

y=13 #d3
r=14 #d1
b=16 #sys

timer() {
  $(for i in $(seq 1 1000); do i=$i; done) 
}

led_state() {
  led=$1
  echo $(mtk_gpio -r $led | sed -E 's/gpio[^\=]+\= ([0-9]+)/\1/')
}

led_red_state() {
  if [ "$(led_state $r)" -eq "0" ]; then
    echo "on"
  else
    echo "off"
  fi
}

led_yellow_state() {
  if [ "$(led_state $y)" -eq "0" ]; then
    echo "on"
  else
    echo "off"
  fi
}

led_blue_state() {
  if [ "$(led_state $b)" -eq "0" ]; then
    echo "on"
  else
    echo "off"
  fi
}

blink() {
  led=$1
  times=2
  restore=1
  if [ ! -z "$2" ]; then
    times=$2
  fi
  if [ ! -z "$3" ]; then
    restore=$3
  fi

  led_y=$(led_state $y)
  led_r=$(led_state $r)
  led_b=$(led_state $b)
  
  mtk_gpio -w $r 1 && mtk_gpio -w $b 1 && mtk_gpio -w $y 1
  for i in $(seq 1 $times); do
    #echo blink="$i"
    mtk_gpio -w $led 1
    timer
    mtk_gpio -w $led 0
    timer
  done

  if [ "$restore" == "1" ]; then
    mtk_gpio -w $r $led_r && mtk_gpio -w $b $led_b && mtk_gpio -w $y $led_y
  fi
}

blink_yellow() {
  blink $y "$1" "$2"
}

blink_red() {
  blink $r "$1" "$2"
}

blink_blue() {
  blink $b "$1" "$2"
}

read_total_secs() {
  s=""
  if [ -f "/tmp/$daemon_status" ]; then
    s="$(cat /tmp/$daemon_status | grep "runtime=" | sed -E "s/runtime=([0-9]+)/\1/")"
  fi
  echo "$s"
}

write_total_secs() {
  s="$1"
  if [ -f /tmp/$daemon_status ]; then
    sed -i "/runtime=/d" /tmp/$daemon_status
  fi
  echo "runtime=$s" >> /tmp/$daemon_status
}

# Replace dnsmasq with latest version 2.89
restart_dnsmasq() {
  if [ -f $basedir/dnsmasq ]; then
    umount -fl /usr/sbin/dnsmasq
    mount -o bind $basedir/dnsmasq /usr/sbin/dnsmasq
    killall dnsmasq >/dev/null 2>&1
    /usr/sbin/dnsmasq 2>&1 &
  fi
}

start_sub_daemon() {
  killall $daemon_sub_sh >/dev/null 2>&1
  chmod +x /tmp/$daemon_sub_sh && /tmp/$daemon_sub_sh 2>&1 &
}

start_kcptun() {
  if [ ! -f "/opt/bin/kcptun" ]; then
    return
  fi
  killall kcptun >/dev/null 2>&1
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

total_secs=$(read_total_secs)
if [ -z "$total_secs" ]; then
  total_secs=0
fi
sleep_secs=2
selfkill_secs=3600 # must be even number
ntp_secs=600 # must be even number
inet_check_interval=60
inet_fail_count=0
inet_fail_max=3 # this value will be increased on restart

while true; do
  if [[ ! -f "/opt/bin/kcptun" && -f "$basedir/kcptun" ]]; then
    logger -s -t "【 本地应用守护】" "找不到/opt/bin/kcptun, 重新链接!"
    ln -s $basedir/kcptun /opt/bin/kcptun
  fi
  if [[ ! -f "/opt/bin/udp2raw" && -f "$basedir/udp2raw" ]]; then  
    logger -s -t "【 本地应用守护】" "找不到/opt/bin/udp2raw, 重新链接!"
    ln -s $basedir/udp2raw /opt/bin/udp2raw
  fi

  kcptun=
  udp2raw=
  ssredir=
  nginx=
  php8fmp=
  padavand=
  padavands=
  ttyd=
  mtd_write=
  mtd_storage=

  eval `ps | awk '/udp2raw/ || /kcptun/ || /ss-redir/ || /nginx/ || /php8-fpm/p || /padavan-d.sh/ || /padavan-ds.sh/ || /ttyd/ || /mtd_write/ || /mtd_storage/ {print $5"="$1}' | sed -E 's/\{(.+)\}/\1/' | sed -E 's/\[(.+)\]/\1/' | sed -E 's/\/.*\/|[^0-9a-zA-Z\=]//' | sed -E 's/.sh//' | grep -v 'awk'`

  if [ -z "$udp2raw" ]; then
    logger -s -t "【 本地应用守护】" "udp2raw没有启动, 重新开始!"
    start_sub_daemon
  fi
  if [ -z "$padavands" ]; then
    logger -s -t "【 sub-daemon 本地应用守护】" "没有启动, 重新开始!"
    start_sub_daemon
  fi
  if [ -z "$kcptun" ]; then
    logger -s -t "【 本地应用守护】" "kcptun没有启动, 重新开始!"
    start_kcptun
  fi

  # crond daemon - no logging output
  if [ $(ps | grep -E "[c]rond -l 15" | wc -l) -eq 0 ]; then
    logger -s -t "【 本地应用守护】" "crond不输出日志!"
    killall crond >/dev/null 2>&1
    crond -l 15 >/dev/null 2>&1 &
  fi
  orig_crond_proc_id="$(ps | grep -E "[c]rond$" | awk {'print$1'})"
  if [ ! -z "$orig_crond_proc_id" ]; then
    kill $orig_crond_proc_id
  fi

  if [ "$(expr $total_secs \% $ntp_secs)" -eq "0" ]; then    
    ntpd -n -q -p cn.pool.ntp.org >/dev/null 2>&1
    LOGTIME=$(date "+%Y-%m-%d %H:%M:%S")
    logger -t "【ntpd时间同步】" "$LOGTIME"
  fi

  if [ "$(expr $total_secs \% $inet_check_interval)" -eq "0" ]; then
    if [ "$(inet_check)" -eq "0" ]; then
      if [ $inet_fail_count -ge 1 ]; then
        blink_blue 10 0
        logger -t "【科学上网】" "恢复正常"
      fi
      if [ "$(led_blue_state)" == "off" ]; then
        blink_blue 1 0
      fi
      inet_fail_count=0
      inet_fail_max=3
    else
      inet_fail_count=$(expr $inet_fail_count \+ 1)
      logger -t "【科学上网】" "连续失败$inet_fail_count次"
      blink_yellow 10 0
      if [ $inet_fail_count -ge $inet_fail_max ]; then
        inet_fail_count=0
	if [ $inet_fail_max -ge 6 ]; then
	  logger -t "【重启WAN】" "尝试连接google.com失败, 达到连续失败次数$inet_fail_max"
	  blink_red 10 0
	  restart_wan
	else
	  logger -t "【自动重启kcptun/udp2raw】" "原因：无法正常访问google.com"
	  restart_dnsmasq
          start_sub_daemon
	  start_kcptun
	fi
	inet_fail_max=$(expr $inet_fail_max \+ 1) # max failures increased by 1
      fi
    fi
  fi
  
  sleep $sleep_secs
  total_secs=$(expr $total_secs \+ $sleep_secs)
  $(write_total_secs $total_secs)
  if [[ $(expr $total_secs \% $selfkill_secs) -eq 0 && ! -z "$(pgrep $daemon_sub_sh)" ]]; then
    total_mins=$(expr $total_secs \/ 60)
    logger -t "【main-daemon守护】" "已经运行$total_mins分钟, 自重启."
    killall $daemon_sh >/dev/null 2>&1
  fi

done
EOF

# install daemons!!!
chmod +x /tmp/$daemon_sh && /tmp/$daemon_sh 2>&1 &
restart_dnsmasq

exit 0
