<b>Utilities for Shadowsocks client</b>

This repository covers some utility scripts for Shadowsocks client, it helps to improve the performance 
and resolve some known issues for <a href="https://github.com/shadowsocks/openwrt-shadowsocks">Shadowsocks client</a> running on <a href="https://openwrt.org/">OpenWRT</a>.

There is no warranty here, use these scripts at your own risk!

<b>Who may use these scripts?</b>

These scripts will run on <a href="https://openwrt.org/">OpenWRT</a> (A lightweight <a href="http://lede-project.org">LEDE</a> linux system.
The people who's located in China mainland and be forbidden visiting google.com, facebook.com, twitter.com, etc. have installed Shadowsocks client on his own OpenWRT system, this will be able to reach these inaccessible sites by Shadowsocks,  wiling to use these scripts helping himself to improve performance, resolve TCP/IP forwarding, keep watch over Shadowsocks runs normally, etc.

<b>List of scripts</b>

1) ss_watchdog.sh

Utility script that it can be executed by scheduling every x minutes (see below), it will keep watch over Shadowsocks runs normally, the theory inside the script is to check if google.com can be reached by 'wget' command, if it's not successfully then furthermore check if baidu.com can be reached successfully and finally determine restarting Shadowsocks client service.

Note: this script will generate log file at /var/log/ss_watchdog.log

2) update_ignore_list.sh

Utility script that it helps to update IP addresses from Asian area in which won't be forwarding by Shadowsocks client, this script also can be executed by scheduling, the list of IP addresses will be saved at file /etc/shadowsocks/ignore.list and used for Shadowsocks client configuration, therefore, Shadowsocks will ignore the list of these IP addresses on requests.

When you started Shadowsocks client, you execute command line:

ipset list

you should see the list of IP addresses same as the file /etc/shadowsocks/ignore.list

3) skype_ipset.sh

I've often confused one thing that when Shadowsocks client started, <b>Why Skype sometimes keep connectivity as signing in</b> that I can't receive / send any messages, I ever thought that it would be caused by DNS forwarding since I've already setup DnsCrypt-proxy service on OpenWRT, but it's not, now I've found the solution avoiding this issue happens, that's the script that it does append these IP list in 'ignore list' (I will explain how come these IPs are from), ignoring these IPs will help to resolve the connectivity issue on Skype.

<i>Where is these IPs from?</i>
I've just ran Skype on my windows PC, when connectivity issue happened, I went to the Shadowsocks server then checking to see which TCP/IP connections keep staying on FIN_WAIT1/2 state, this can be finished by command line:

netstat -a | grep FIN_WAIT

The results of TCP/IP connetions presented which target IPs were associated with FIN_WAIT1/2, I made testing on Google to check who's the owner of these IPs, all of them are belong to Microsoft! well, now I can figured out that they should be used for Skype connection, it's best that we don't forwarding any 'Skype' requests from these IPs.

Note: skype_ipset.sh has been included in 2) update_ignore_list.sh, if you don't need to resolve the Skype connectivity issue, you can remove from there.

4) scheduled_tasks.txt

It contains the instructions for cron jobs, it will execute the script 1) , 2) at specified time, especially, it will remove the log file generated by 1) script, running the below command line to change the cron jobs.

crontab -e
