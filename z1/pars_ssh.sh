#!/bin/bash
#need root
#1. Написать bash скрипт который осуществляет поиск количества попыток #взлома по протоколу ssh с каждого ip и блокировку последнего с #помощью iptables, если количество попыток превысило 10. В данном #случае используйте регулярные выражения для поиска ip, отсортируйте #результат по количеству попыток взлома для вывода результата. Пример #файла журнала: sshd-test.log

#********************************
logPATH=sshd-test.log
#iptSET=/etc/network/iptables.rules
bIP=$(grep -Eo "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" "$logPATH" | sort | uniq -c) #фильтруем все ip, нужно предусмотреть защиту белых, кто просто часто логинится или забывает пароль) 

if [[ $EUID -ne 0 ]]; then
	echo "This script must be run as root"
    echo "but, at least you can see the bad guys"
    echo "$bIP"
	exit 1
fi

IFS=$'\n' #change default delimiter

sudo iptables-restore < iptables.rules #restore iptables settings
for ip in $bIP
do 
    if [ "$(echo "$ip" | sed 's/^[ \t]*//' | cut -d ' ' -f 1)" -gt 10 ]
    then
    badIP=$(echo "$ip" | sed 's/^[ \t]*//' | cut -d ' ' -f 2)
        if ! sudo iptables -I INPUT -s "$badIP" -j DROP #to do block nftables
        then 
        echo "ERROR! $badIP do not DROPd"
        fi
    fi
done

sudo iptables-save > iptables.rules #save iptables settings
IFS=$' ' #return  default delimiter

#****************************
#с готовым логом просто, но нужно придумать вариант работы в виде демона с фильтрацией в реальном времени.
#tail -f "$logPATH" | grep -Eo "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"
