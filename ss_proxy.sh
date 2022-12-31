#!/bin/bash
# 支持并发4个上游dnsproxy服务
pre_start() {
    echo "ss-tproxy 启动前执行脚本"
    logger -t "【删除dnsmasq定制配置】" "完成"
    sed -i '/all-servers/d' /etc/storage/dnsmasq/dnsmasq.conf
    sed -i '/server=127.0.0.1#8054/d' /etc/storage/dnsmasq/dnsmasq.conf
    sed -i '/server=127.0.0.1#8055/d' /etc/storage/dnsmasq/dnsmasq.conf
    sed -i '/server=127.0.0.1#8056/d' /etc/storage/dnsmasq/dnsmasq.conf
    logger -t "【添加dnsmasq定制配置】" "完成"
    echo all-servers >> /etc/storage/dnsmasq/dnsmasq.conf
    echo server=127.0.0.1#8054 >> /etc/storage/dnsmasq/dnsmasq.conf
    echo server=127.0.0.1#8055 >> /etc/storage/dnsmasq/dnsmasq.conf
    echo server=127.0.0.1#8056 >> /etc/storage/dnsmasq/dnsmasq.conf
    logger -t "【监控dnsmasq】" "完成"
    /etc/storage/apps/dnsmasq_watch.sh stop
    /etc/storage/apps/dnsmasq_watch.sh >/dev/null 2>&1 </dev/null &
}
post_start() {
    echo "ss-tproxy 启动后执行脚本"
    logger -t "【启动多个dnsproxy - 5053,5054,5055,5056】" "完成"
    sed -i '/dns-forward-max=1000/d' /etc/storage/dnsmasq/dnsmasq.conf
    killall dnsmasq && /usr/sbin/dnsmasq
    killall dnsproxy && dnsproxy -d -p 8053 && dnsproxy -d -p 8054 && dnsproxy -d -p 8055 && dnsproxy -d -p 8056
}
pre_stop() {
    echo "ss-tproxy 停止前执行脚本"
    
}
post_stop() {
    echo "ss-tproxy 停止后执行脚本"
    
}
