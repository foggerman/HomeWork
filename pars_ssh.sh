#!/bin/bash
var1=$(grep -Eo "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" sshd-test.log | sort | uniq -c)
IFS=$'\n'
for ip in $var1
do 
    if [ "$(echo $ip | sed 's/^[ \t]*//' | cut -d ' ' -f 1)" -gt 10 ]
    then
    echo $(echo $ip | sed 's/^[ \t]*//' | cut -d ' ' -f 2)
    #echo $ip
    fi
done