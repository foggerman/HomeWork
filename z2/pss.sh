#!/bin/bash

#2. Написать bash скрипт, который выведет top 15 процессов, потребляющие больше всего резидентной памяти в системе, используя стандартные утилиты linux. Значение памяти вывести в "human" #виде (G, M, K), округлить до первого знака. При этом не использовать готовых утилит типа numfmt (сделать свою реализацию перевода в human вид, можно использовать awk).
#******************************************************************
var=$(ps -eo rss,vsz,pid,user --sort=-rss | head -n 16) #to do readble list and vsz
echo "$var" | awk '
    function human(x) { #get this F(x) in StackOverflow. Can I do better?)
        if (x<1000) {return x} else {x/=1024}
        s="KMG";
        while (x>=1000 && length(s)>1)
            {x/=1024; s=substr(s,2)}
        return int(x+0.5) substr(s,1,1)
    }
    {sub(/^[0-9]+/, human($1)); print}'
#*****************************************************************

