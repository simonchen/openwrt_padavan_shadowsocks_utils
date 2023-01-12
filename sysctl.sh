#!/bin/bash
# optimize for udp2raw > icmp
# orig val is 1000
sysctl -w net.ipv4.icmp_ratelimit=0
# orig val is 6168
sysctl -w net.ipv4.icmp_ratemask=0
# orig val is 1000
sysctl -w net.ipv6.icmp.ratelimit=0
# orig val is 30
sysctl -w net.netfilter.nf_conntrack_icmp_timeout=10
# orig val is 30
sysctl -w net.netfilter.nf_conntrack_icmpv6_timeout=10
