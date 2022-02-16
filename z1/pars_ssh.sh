#!/bin/bash

#1. Написать bash скрипт который осуществляет поиск количества попыток #взлома по протоколу ssh с каждого ip и блокировку последнего с #помощью iptables, если количество попыток превысило 10. В данном #случае используйте регулярные выражения для поиска ip, отсортируйте #результат по количеству попыток взлома для вывода результата. Пример #файла журнала: sshd-test.log

#********************************
bIP=$(grep -Eo "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" sshd-test.log | sort | uniq -c)
IFS=$'\n'
for ip in $bIP
do 
    if [ "$(echo $ip | sed 's/^[ \t]*//' | cut -d ' ' -f 1)" -gt 10 ]
    then
    echo $ip | sed 's/^[ \t]*//' | cut -d ' ' -f 2
    #to do block nftables
    fi
done
IFS=$' '
#****************************
#с готовым логом просто, но нужно придумать вариант работы в виде демона с фильтром в реальном времени.
