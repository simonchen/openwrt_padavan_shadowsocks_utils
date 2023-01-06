#!/bin/sh
#copyright by simonchen
#this script aims to optimize dnsmasq can query upstreaming multiple-dnsproxy servers in parallel.

function remove_dnsproxy_config(){
    logger -t "【删除dnsmasq定制配置】" "完成"
    sed -i '/all-servers/d' /etc/storage/dnsmasq/dnsmasq.conf
    #sed -i '/server=127.0.0.1#8053/d' /etc/storage/dnsmasq/dnsmasq.conf
    sed -i '/server=127.0.0.1#8054/d' /etc/storage/dnsmasq/dnsmasq.conf
    sed -i '/server=127.0.0.1#8055/d' /etc/storage/dnsmasq/dnsmasq.conf
    sed -i '/server=127.0.0.1#8056/d' /etc/storage/dnsmasq/dnsmasq.conf
}

function add_dnsproxy_config(){
    logger -t "【添加dnsmasq定制配置】" "完成"
    echo all-servers >> /etc/storage/dnsmasq/dnsmasq.conf
    #echo server=127.0.0.1#8053 >> /etc/storage/dnsmasq/dnsmasq.conf
    echo server=127.0.0.1#8054 >> /etc/storage/dnsmasq/dnsmasq.conf
    echo server=127.0.0.1#8055 >> /etc/storage/dnsmasq/dnsmasq.conf
    echo server=127.0.0.1#8056 >> /etc/storage/dnsmasq/dnsmasq.conf
}

function start_dnsproxy(){
    logger -t "【启动多个dnsproxy - 5053,5054,5055,5056】" "完成"
    killall dnsproxy && dnsproxy -d -p 8053 && dnsproxy -d -p 8054 && dnsproxy -d -p 8055 && dnsproxy -d -p 8056
    killall dnsmasq && /usr/sbin/dnsmasq
}

function reset_dnsproxy(){
    logger -t "【Reset dnsproxy 】" "完成"
    remove_dnsproxy_config
    killall dnsproxy && dnsproxy -d
    killall dnsmasq && /usr/sbin/dnsmasq
}

param=$1
if [ $(ps | grep dnsproxy | wc -l) -ge 2 ]; then
    echo "dnsproxy is running"
    if [ "$param" == "start" ]; then
        remove_dnsproxy_config
        add_dnsproxy_config
        start_dnsproxy
    fi
    if [ "$param" == "stop" ]; then
        remove_dnsproxy_config
        reset_dnsproxy
    fi
fi
