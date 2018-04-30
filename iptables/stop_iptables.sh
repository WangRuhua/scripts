#!/bin/sh
. /etc/profile
IPT="/usr/sbin/iptables"

#
# reset the default policies in the filter table.
#
$IPT -P INPUT ACCEPT
$IPT -P FORWARD ACCEPT
$IPT -P OUTPUT ACCEPT

#
# reset the default policies in the nat table.
#
$IPT -t nat -P PREROUTING ACCEPT
$IPT -t nat -P POSTROUTING ACCEPT
$IPT -t nat -P OUTPUT ACCEPT

#
# reset the default policies in the mangle table.
#
$IPT -t mangle -P PREROUTING ACCEPT
$IPT -t mangle -P OUTPUT ACCEPT

#
# flush all the rules in the filter and nat tables.
#
$IPT -F
$IPT -t nat -F
$IPT -t mangle -F
#
# erase all chains that's not default in filter and nat table.
#
$IPT -X
$IPT -t nat -X
$IPT -t mangle -X




###the rulers
$IPT -A INPUT -i lo -j ACCEPT


echo "now iptables is ..."
$IPT -nvL
$IPT -t nat -nvL

date +%T
exit
