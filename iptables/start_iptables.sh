#!/bin/sh
# a simple firewall initialization script

white_list=./whitelist.txt
black_list=./blacklist.txt
port_list=./portlist.txt

IPT=/usr/sbin/iptables
if [ ! -x $IPT ];then
	echo "some problem $IPT "
	exit
fi

function check_file ()
{
	if [ ! -r $1 ];then
		echo "no file $1"
		exit
	fi
		
}

##check config files
check_file $white_list
check_file $port_list
check_file $black_list

##add your ip to white list

yourip=`last -i |awk  --re-interval '/still logged/{if ( $3 ~ /([0-9]{1,3}\.){3}[0-9]{1,3}/ ) print $3}'|head -1 `

if  ! grep $yourip $white_list>> /dev/null 2>&1;then
	echo "now add yourip into $white_list"
	echo $yourip >> $white_list
fi

#
# Drop all existing filter rules

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
$IPT -I INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT


#
#whitelist

echo $white_list
echo good
for x in `grep -v ^# $white_list |grep -v ^$| awk '{print $1}'`;do
	echo "Permitting $x..."
	$IPT -A INPUT -t filter -s $x -j ACCEPT
done
echo good




###read blacklist.txt,dropping all traffic from the hosts
#and networks 

for x in `grep -v ^# $black_list|grep -v ^$| awk '{print $1}'`;do
	echo "Blocking $x..."
	$IPT -A INPUT -t filter -s $x -j DROP
done


#
##permitted ports: what will we accept from hosts not appering on the blacklist
#
for line in `cat $port_list |grep -v ^#|grep -v ^$|grep -iE "^tcp|^udp|^icmp"`;do
        eval `echo $line |awk -F: '{print "protocol="$1,"port="$2,"srcip="$3}' `
        echo -e "Accepting protocol:$protocol port:$port source ip:$srcip\n"

        if [ "x$srcip" = x ];then
                srcip="0/0"
        fi

	if  echo $port |grep "[0-9]\-[0-9]" >>/dev/null 2>&1 ;then
		ports=`echo $port |sed 's/\-/\:/'`
		echo "multiport $ports ..."

        	$IPT -A INPUT -t filter -p $protocol -s $srcip -m multiport --destination-port  $ports -j ACCEPT

	else
         	$IPT -A INPUT -t filter -p $protocol -s $srcip --dport $port -j ACCEPT
	fi
done    



##finally , unless it's mentioned above,and it's an inbound startup reguest,
#just drop it

$IPT -A INPUT -t filter -p tcp --syn -j DROP
$IPT -A INPUT -j DROP

echo -e "\nfinished the rules...\n"
echo -e "show the rules now ..."
$IPT -vnL
