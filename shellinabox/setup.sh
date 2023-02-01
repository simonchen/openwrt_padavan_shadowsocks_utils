#!/bin/sh

basedir=$(cd $(dirname $0) && pwd)
basename=$(basename $0)

stop() {
  killall shellinaboxd
}

start() {
disable_ssl=""
if [ "$1" == "http" ]; then
  disable_ssl="-t"
fi
bin_path=$basedir/opt_bin.tar.gz
logger -t "【安装shellinabox】" "解压/复制程序"
mkdir /opt/bin

tar -xzf "$bin_path" -C "/opt/bin/" && 
chmod +x /opt/bin/shellinaboxd &&
/opt/bin/shellinaboxd -b --user=admin --css=$basedir/custom.css -f /favicon.ico:/www/images/favicon.ico $disable_ssl
if [ "$?" == "0" ]; then
  logger -t "【安装shellinabox】" "启动shellinabox成功"
else
  logger -t "【安装shellinabox】" "启动shellinabox失败, $?"
fi
}

restart() {
  stop
  start "$1"
}

case "$1" in
  start)
    start "$2"
    ;;
  stop)
    stop
    ;;
  restart)
    restart "$2"
    ;;
  *)
  echo "Usage: $0 {start|stop|restart} {http|https}"
  exit 1
esac 