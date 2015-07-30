#!/bin/sh
# removes all iptables rules
# https://en.wikipedia.org/wiki/Tear_down_this_wall!
echo "flushing all iptables rules.."
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
echo "done"
