#!/bin/sh

url="https://www.ibmnb.com/qd.php"
cookie=""
agent="User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
cur_date=$(date +"%Y-%m-%d %H:%M:%S %A")

for i in {1..3}
do
  curl -v -c /root/cookie.txt -b /root/cookie.txt -b $cookie -H $agent $url 2>/dev/null | \
	sed -n '/.*<div id="messagetext" class="alert_info">/,/<\/div>/p' | sed -e 's/window.location.href/foo/g' | \
	sed -e 's/<div id="messagetext" class="alert_info">/<div style="font-size:12px;">/' | \
	sed -e 's/<p class="alert_btnleft">.*<\/p>//' | sed -e '$a'"<font size=1>$cur_date</font>" > /www/qd.htm &
done
