#!/bin/bash

#4. Имеется две приватных сети: 172.20.0.0/24 (интерфейс eth0) и 192.168.0.0/24 (интерфейс eth1), а так же доступ в интернет через провайдера с 
#динамическим ip, подключённым к wan0 #интерфейсу (провайдер раздаёт настройки tcp/ip и dns по dhcp протоколу). 
#Необходимо с помощью iptables и route на ОС linux (дистрибутив любой) дать доступ в интернет выделенной группе ip 
#адресов из обеих подсетей: 172.20.0.100-172.20.0.200 и 192.168.0.30-192.168.0.44 по следующим протоколам - icmp, dns, http, https, ssh, ntp, 
#всё остальное закрыть. При этом дать #возможность обмениваться данными между двумя подсетями по smb протоколу. Хост имеющий ip - 172.20.0.100, 
#может обмениваться данными с любым хостом из сети 192.168.0.0/24 по любому #протоколу без ограничений. Результат сгенерировать с помощью команды 
#iptables-save, route -n (или netstat -rn) и представить в ответе.
#
#sudo iptables-save
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
eth1=enp0s9

#Lacky
inet192="192.168.0.31-192.168.0.44"
inet172="172.20.0.101-172.20.0.200"
BOSS="172.20.0.100"


if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

#Check the network
checkNET () {
    interf=$(ls /sys/class/net)
    Echo "existed interface: $interf"
}
checkNET

#Add static
netplan () {
    #echo $(cat /etc/netplan/50-*)
echo -e '''
 ---
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s8:
      addresses:
      - 172.20.0.1/24
    enp0s9:
      addresses:
      - 192.168.0.1/24
    enp0s10:
      dhcp4: true''' >> 50-vagrant.yaml

if ! netplan --debag generate
   then
    retern 1
   else
    netplan --debug apply
fi
}

#**********ROUTE************************'
    route -n
    routrule () {
    route add -net 192.168.0.0 netmask 255.255.255.0 dev $eth1 metric 10
    route add -net 172.20.0.0 netmask 255.255.255.0 dev $eth0 metric 10
    route add -net 0.0.0.0 netmask 0.0.0.0 gw 192.168.199.1 dev $wan0 metric 100
    route add -host 172.20.0.2 dev $eth0
    route add -host 192.168.0.2 dev $eth1
    }
    read  -r -p "Add new route? " answer
    case $answer in
        y) routrule;;
        n) echo "fuh";;
    esac
    

  
#************ADD PORT FORWARD***************
addFOR () {
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf #sudo tee -a /etc/sysctl.conf
    sysctl -p /etc/sysctl.conf #reset
}
cat /etc/sysctl.conf
read  -r -p "Add intrface PORT FORWARD? " answer
    case $answer in
        y) addFOR;;
        n) echo "fuh";;
    esac

#Flush
flush () {
    iptables -F
    iptables -F -t nat
    #iptables -F -t mangle
    iptables -X
    iptables -t nat -X
    #iptables -t mangle -X
}


#LO
read  -r -p "ADD LO exception?" answer
    case $answer in
        n) addLO=false;;
        y) addLO=true;;
    esac


read  -r -p "Show old tables?" answer
    case $answer in
        y) iptables -L -nv && iptables -L -t nat -nv;;
        n) echo "fuh";;
    esac

read  -r -p "SAVE & Flush old tables?" answer
    case $answer in
        n) flush;;
        y) iptables-save > old_tables && flush;;
    esac

#service lan 
srvLAN=enp0s3
iptables -A INPUT -i $srvLAN -j ACCEPT
iptables -A OUTPUT -o $srvLAN -j ACCEPT

if $addLO 
then
iptables -A INPUT -i lo -j ACCEPT 
iptables -A INPUT -i lo -j ACCEPT
fi

#*************DEFAULTS******************'
iptables -P INPUT DROP #drop all defaults
iptables -P OUTPUT DROP #drop all defaults
iptables -P FORWARD DROP #drop all defaults

#drop all invalid'
iptables -A INPUT -m state --state INVALID -j DROP
iptables -A FORWARD -m state --state INVALID -j DROP
######################################################################################
#*******cliar internet*************************************'
#OUTPUT
#OUT HTTP(S)
iptables -A OUTPUT -o $wan0 -p tcp --sport 80 -m state --state ESTABLISHED -j ACCEPT
iptables -A OUTPUT -o $wan0 -p tcp --sport 443 -m state --state ESTABLISHED -j ACCEPT
iptables -A OUTPUT -o $wan0 -p tcp --dport 443 -m state --state NEW,ESTABLISHED -j ACCEPT
#OUT ICMP
iptables -A OUTPUT -o $wan0 -p icmp --icmp-type echo-request -j ACCEPT
#ssh
iptables -A OUTPUT -o $wan0 -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
#DNS
iptables -A OUTPUT -o $wan0 -p udp --sport 53 -j ACCEPT
#NTP
iptables -A OUTPUT -o $wan0 -p udp --sport 123 -j ACCEPT

#INPUT'
#HTTP(S) #SSH 
iptables -A INPUT -i $wan0 -p tcp -m multiport --dports 22,80,443 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A INPUT -i $wan0 -p tcp --sport 443 -m state --state ESTABLISHED -j ACCEPT
#DNS NTP
iptables -A INPUT -i $wan0 -p udp -m multiport --dports 53,123 -j ACCEPT
#ICMP
iptables -A INPUT -i $wan0 -p icmp --icmp-type echo-reply -j ACCEPT
#*******cliar internet*************************************

#FORWARDing
#******betwin network***************************************************'
iptables -A FORWARD -i $eth1 -o $eth0 -s 192.168.0.0/24 -d 172.20.0.0/24 -j ACCEPT
iptables -A FORWARD -i $eth0 -o $eth1 -s 172.20.0.0/24 -d 192.168.0.0/24 -j ACCEPT

#SMB
openTCP="138,139,445" #-p tcp -m multiport --dports 138,139,445
openUDP="137,445" #-p udp -m multiport --dports 137,445
# for p in $SMBports
# do 
#xarg?
#HOST=172.20.0.100 is the BOSS

iptables -A INPUT -i $eth0 -s $BOSS -j ACCEPT
iptables -A INPUT -i $eth1 -s $BOSS -j ACCEPT
iptables -A OUTPUT -o $eth0 -d $BOSS -j ACCEPT
iptables -A OUTPUT -o $eth1 -d $BOSS -j ACCEPT
#Others
iptables -A INPUT -i $eth0 -p tcp -m multiport --dports $openTCP -j ACCEPT
iptables -A INPUT -i $eth0 -p udp -m multiport --dports $openUDP -j ACCEPT
iptables -A OUTPUT -o $eth0 -p tcp -m multiport --sport $openTCP -j ACCEPT
iptables -A OUTPUT -o $eth0 -p udp -m multiport --sport $openUDP -j ACCEPT
iptables -A INPUT -i $eth1 -p tcp -m multiport --dports $openTCP -j ACCEPT
iptables -A INPUT -i $eth1 -p udp -m multiport --dports $openUDP -j ACCEPT
iptables -A OUTPUT -o $eth1 -p tcp -m multiport --sport $openTCP -j ACCEPT
iptables -A OUTPUT -o $eth1 -p udp -m multiport --sport $openUDP -j ACCEPT

#*********FORWARD to the Internet******************************'

#-m iprange --src-range 192.168.0.0/24 --dst-range 172.20.0.0/24

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

#****************NAT****************************************'
# sNAT
iptables -t nat -A POSTROUTING -s 192.168.0.0/24 -o $wan0 -j MASQUERADE #SNAT --to-source 192.168.199.106 #DHCP!!
iptables -t nat -A POSTROUTING -s 172.20.0.0/24 -o $wan0 -j MASQUERADE #SNAT --to-source 192.168.199.106 #DHCP!!

read  -r -p "Save? " answer
    case $answer in
        y) iptables-save > new-iptables;;
        n) echo "fuh" && exit;;
    esac

echo "Done"

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
