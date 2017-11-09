README!!!

This repository covers some utility scripts for Shadowsocks client, it helps to improve the performance 
and resolve some known issues for <a href="https://github.com/shadowsocks/openwrt-shadowsocks">Shadowsocks client</a> running on <a href="https://openwrt.org/">OpenWRT</a>.

There is no warranty here, use these scripts at your own risk!

<b>Who may use these scripts?</b>

These scripts will run on <a href="https://openwrt.org/">OpenWRT</a> (A lightweight <a href="http://lede-project.org">LEDE</a> linux system.
The people who's forbidden visiting google.com, facebook.com, twitter.com, etc. might installed Shadowsocks client on his own OpenWRT system, this will be able to reach these inaccessible sites by Shadowsocks,  wiling to use these scripts helping himself to improve performance, resolve DNS forwarding, keep watch over Shadowsocks runs, etc.

<b>List of scripts</b>

1) ss_watchdog.sh

A utility script that it can be executed by scheduling every x minutes (see below), it will keep watch over Shadowsocks runs, the theory inside the script is to check if google.com can be reached by 'wget' command, if it's not successfully then furthermore check if baidu.com can be reached successfully and finally determine restarting Shadowsocks client service.
