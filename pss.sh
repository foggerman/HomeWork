#!/bin/bash
var=$(ps -eo rss,vsz,pid,user --sort=-rss | head -n 16) #to do list
echo "$var" | awk '
    function human(x) {
        if (x<1000) {return x} else {x/=1024}
        s="KMG";
        while (x>=1000 && length(s)>1)
            {x/=1024; s=substr(s,2)}
        return int(x+0.5) substr(s,1,1)
    }
    {sub(/^[0-9]+/, human($1)); print}'