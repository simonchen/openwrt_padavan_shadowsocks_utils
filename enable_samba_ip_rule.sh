#!/bin/sh
# delete any ip rule that have comment with 'netbios'

# deleting existing rules
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

# adding new rules
iptables -I INPUT 1 -p udp -m multiport --dport 137,138 -j ACCEPT 
iptables -I INPUT 1 -p tcp -m state --state NEW,RELATED,ESTABLISHED -m multiport --dport 139,445 -j ACCEPT
iptables -I INPUT -p icmp -j ACCEPT
