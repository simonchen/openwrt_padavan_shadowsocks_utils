#!/bin/sh

basedir=$(cd $(dirname $0) && pwd)
basename=$(basename $0)

stop() {
  killall php8-fpm
  killall nginx
}

start() {

bin_path=$basedir/opt_bin.tar.gz
lib_path=$basedir/opt_lib.tar.gz
etc_path=$basedir/opt_etc.tar.gz
var_path=$basedir/opt_var.tar.gz

logger -t "【安装Nginx+php-fpm】" "解压/复制程序，链接库，配置"
mkdir /opt/bin
mkdir /opt/lib
mkdir /opt/etc
mkdir /opt/var

tar -xzf "$bin_path" -C "/opt/bin/"
tar -xzf "$lib_path" -C "/opt/lib/"
tar -xzf "$etc_path" -C "/opt/etc/"
tar -xzf "$var_path" -C "/opt/var/"

chmod +x /opt/bin/nginx
chmod +x /opt/bin/php8-fpm

ret=$(nginx)
if [ -z "$ret" ]; then
  logger -t "【安装Nginx+php-fpm】" "启动Nginx成功"
else
  logger -t "【安装Nginx+php-fpm】" "启动Nginx失败, $ret"
fi
ret=$(php8-fpm -R -y /opt/etc/php8-fpm.d/www.conf)
if [ -z "$ret" ]; then
  logger -t "【安装Nginx+php-fpm】" "启动php-fpm成功"
else
  logger -t "【安装Nginx+php-fpm】" "启动php失败, $ret"
fi

logger -t "【安装Nginx+php-fpm】" "设置web服务根目录/home/root/www"
chmod 755 /home/root
mkdir /home/root/www 
echo "<?php phpinfo(); ?>" > /home/root/www/index.php
}

restart() {
  stop
  start
}

case "$1" in
  start)
    start
    ;;
  stop)
    stop
    ;;
  restart)
    restart
    ;;
  *)
  echo "Usage: $0 {start|stop|restart}"
  exit 1
esac 