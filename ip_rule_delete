#!/bin/sh
# delete any ip rule that have comment with 'netbios'

while ip_rule_num=$(iptables -L INPUT --line-numbers | grep netbios | cut -d" " -f1)
do
    if [ -z $ip_rule_num ]; then
        break
    fi
    for n in $ip_rule_num; do
        iptables -D INPUT $n
        echo delete ip rule no.$n - ok
        break
    done
done
