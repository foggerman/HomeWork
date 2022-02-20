#!/bin/bash

#4. Имеется две приватных сети: 172.20.0.0/24 (интерфейс eth0) и 192.168.0.0/24 (интерфейс eth1), а так же доступ в интернет через провайдера с 
#динамическим ip, подключённым к wan0 #интерфейсу (провайдер раздаёт настройки tcp/ip и dns по dhcp протоколу). 
#Необходимо с помощью iptables и route на ОС linux (дистрибутив любой) дать доступ в интернет выделенной группе ip 
#адресов из обеих подсетей: 172.20.0.100-172.20.0.200 и 192.168.0.30-192.168.0.44 по следующим протоколам - icmp, dns, http, https, ssh, ntp, 
#всё остальное закрыть. При этом дать #возможность обмениваться данными между двумя подсетями по smb протоколу. Хост имеющий ip - 172.20.0.100, 
#может обмениваться данными с любым хостом из сети 192.168.0.0/24 по любому #протоколу без ограничений. Результат сгенерировать с помощью команды 
#iptables-save, route -n (или netstat -rn) и представить в ответе.
#iptables -L -nv
#sudo iptables-save
#wont do this with Ansible
#I hate iptables!

#ls /sys/class/net
#enp0s10  enp0s3  enp0s8  enp0s9  lo

#vagrant@bastion:~$ cat /etc/netplan/50-vagrant.yaml
#---
#network:
#  version: 2
#  renderer: networkd
#  ethernets:
#    enp0s8:
#      addresses:
#      - 172.20.0.1/24
#    enp0s9:
#      addresses:
#      - 192.168.0.1/24
#    enp0s10:
#      dhcp4: true
#prot="icmp, dns, http, https, ssh, ntp"

#INTERF
wan0=enp0s10
eth0=enp0s8
eth1=enp0s8

#**********ROUTE************************
route add -net 192.168.0.0 netmask 255.255.255.0 dev $eth1 metric 10
route add -net 172.20.0.0 netmask 255.255.255.0 dev $eth0 metric 10
route add -net 0.0.0.0 netmask 0.0.0.0 dev $wan0 metric 100
#route add -host 172.20.0.1 netmask 255.255.255.255 dev $eth0
#route add -host 192.168.0.1 netmask 255.255.255.255 dev $eth1

#************ADD PORT FORWARD***************
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf #sudo tee -a /etc/sysctl.conf
sysctl -p /etc/sysctl.conf #reset


#*************DEFAULTS******************
iptables -P INPUT DROP #drop all defaults
iptables -P OUTPUT DROP #drop all defaults
iptables -P FORWARD DROP #drop all defaults

#LO
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

#drop all invalid
iptables -A INPUT -m state --state INVALID -j DROP
iptables -A FORWARD -m state --state INVALID -j DROP

######################################################################################

#*******cliar internet*************************************
#OUTPUT
#OUT HTTP(S)
iptables -A OUTPUT -o $wan0 -p tcp --sport 80 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -o $wan0 -p tcp --sport 443 -m state --state NEW,ESTABLISHED -j ACCEPT
#OUT ICMP
iptables -A OUTPUT -o $wan0 -p icmp -p icmp --icmp-type echo-request -j ACCEPT
#ssh
iptables -A OUTPUT -o $wan0 -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
#DNS
iptables -A OUTPUT -o $wan0 -p udp --sport 53 -j ACCEPT
#NTP
iptables -A OUTPUT -o $wan0 -p udp --sport 123 -j ACCEPT
#INPUT
#HTTP(S) #SSH 
iptables -A INPUT -i $wan0 -p tcp -m multiport --dports 22,80,443 -m state --state NEW,ESTABLISHED -j ACCEPT
#DNS NTP
iptables -A INPUT -i $wan0 -p udp -m multiport --dports 53,123 -j ACCEPT
#ICMP
iptables -A INPUT -i $wan0 -p icmp --icmp-type echo-reply -j ACCEPT
#*******cliar internet*************************************

#FORWARDing
eth0=enp0s8
eth1=enp0s8
#******betwin network***************************************************
iptables -A FORWARD -i $eth1 -o $eth0 -s 192.168.0.0/24 -d 172.20.0.0/24 -j ACCEPT
iptables -A FORWARD -i $eth0 -o $eth1 -s 172.20.0.0/24 -d 192.168.0.0/24 -j ACCEPT
#SMB
openTCP="138,139,445" #-p tcp -m multiport --dports 138,139,445
openUDP="137,445" #-p udp -m multiport --dports 137,445
# for p in $SMBports
# do 
#xarg?
iptables -A INPUT -i $eth0 -p tcp -m multiport --dports $openTCP -j ACCEPT
iptables -A INPUT -i $eth0 -p udp -m multiport --dports $openUDP -j ACCEPT
iptables -A OUTPUT -o $eth0 -p tcp -m multiport --sport $openTCP -j ACCEPT
iptables -A OUTPUT -o $eth0 -p udp -m multiport --sport $openUDP -j ACCEPT
iptables -A INPUT -i $eth1 -p tcp -m multiport --dports $openTCP -j ACCEPT
iptables -A INPUT -i $eth1 -p udp -m multiport --dports $openUDP -j ACCEPT
iptables -A OUTPUT -o $eth1 -p tcp -m multiport --sport $openTCP -j ACCEPT
iptables -A OUTPUT -o $eth1 -p udp -m multiport --sport $openUDP -j ACCEPT
#*********FORWARD to the Internet******************************
#-m iprange --src-range 192.168.0.0/24 --dst-range 172.20.0.0/24
inet192="192.168.0.31-192.168.0.44"
inet172="172.20.0.101-172.20.0.200"
# 192.168.0.1/24 > inet
iptables -A FORWARD -i $eth1 -o $wan0 -m iprange --src-range $inet192 -j ACCEPT
# 192.168.0.1/24 < inet
iptables -A FORWARD -i $wan0 -o $eth1 -m iprange --dst-range $inet192 -j ACCEPT
# 172.20.0.0/24 > inet
iptables -A FORWARD -i $eth0 -o $wan0 -m iprange --src-range $inet172 -j ACCEPT
# 172.20.0.0/24 < inet
iptables -A FORWARD -i $wan0 -o $eth0 -m iprange --dst-range $inet172 -j ACCEPT
#Close lan явно)
iptables -A FORWARD -i $wan0 -o $eth0 -j REJECT
iptables -A FORWARD -i $wan0 -o $eth1 -j REJECT
# only exist connections
iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
#****************NAT****************************************
# sNAT
iptables -t nat -A POSTROUTING -s 192.168.0.0/24 -o $wan0 -j MASQUERADE #SNAT --to-source 192.168.199.106 #DHCP!!
iptables -t nat -A POSTROUTING -s 172.20.0.0/24 -o $wan0 -j MASQUERADE #SNAT --to-source 192.168.199.106 #DHCP!!





#sudo tcpdump -ni enp0s8
#On client
#sudo route del default
#sudo route add -net 0.0.0.0 netmask 0.0.0.0 gw 192.168.0.1 dev enp0s8

# conntrack

# This module, when combined with connection tracking, allows access to more connection tracking information than the "state" match. (this module is present only if iptables was compiled under a kernel supporting this feature)
# --ctstate state
#     Where state is a comma separated list of the connection states to match. Possible states are INVALID meaning that the packet is associated with no known connection, ESTABLISHED meaning that the packet is associated with a connection which has seen packets in both directions, NEW meaning that the packet has started a new connection, or otherwise associated with a connection which has not seen packets in both directions, and RELATED meaning that the packet is starting a new connection, but is associated with an existing connection, such as an FTP data transfer, or an ICMP error. SNAT A virtual state, matching if the original source address differs from the reply destination. DNAT A virtual state, matching if the original destination differs from the reply source. 
# --ctproto proto
#     Protocol to match (by number or name) 
# --ctorigsrc [!] address[/mask]
#     Match against original source address 
# --ctorigdst [!] address[/mask]
#     Match against original destination address 
# --ctreplsrc [!] address[/mask]
#     Match against reply source address 
# --ctrepldst [!] address[/mask]
#     Match against reply destination address 
# --ctstatus [NONE|EXPECTED|SEEN_REPLY|ASSURED][,...]
#     Match against internal conntrack states 
# --ctexpire time[:time]
#     Match remaining lifetime in seconds against given value or range of values (inclusive) 