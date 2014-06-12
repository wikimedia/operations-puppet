#! /bin/bash
#
#  Copyright © 2013 Marc-André Pelletier <mpelletier@wikimedia.org>
#
#  Permission to use, copy, modify, and/or distribute this software for any
#  purpose with or without fee is hereby granted, provided that the above
#  copyright notice and this permission notice appear in all copies.
#
#  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
#  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
#  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
#  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
#  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
#  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
#  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#
##
## THIS FILE IS MANAGED BY PUPPET
##
## Source: modules/toollabs/files/server-tc.sh
##

tc qdisc add dev eth1 root handle 1: htb default 20
tc class add dev eth1 parent 1: classid 1:1 htb rate 800mbit
tc class add dev eth1 parent 1:1 classid 1:10 htb rate 400mbit ceil 500mbit
tc class add dev eth1 parent 1:1 classid 1:20 htb rate 400mbit ceil 800mbit
tc qdisc add dev eth1 parent 1:10 handle 10: sfq perturb 10
tc qdisc add dev eth1 parent 1:20 handle 20: sfq perturb 10

iptables -t mangle -I FORWARD 1 -d 10.64.37.10 -j MARK --set-mark 10
iptables -t mangle -I POSTROUTING 1 -m mark --mark 10 -j CLASSIFY --set-class 1:10
