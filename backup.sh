#!/bin/bash
# $1 - task; #### $2 - bSORC $3 - bDIR

#path***************************
bSORC=/home/mtbuser/Documents/ #what we back up 
#bSORC="$2"
bDIR=$(pwd)/backup #where do we backup 
#bDIR="$3"
bDEST="$bDIR"/last #inc arh for this week 
bOLD="$bDIR"/old #for the last week 

#OPT****************************
bDATE=$(date +'%d.%m.%Y') 
bNAME=$(hostname)_$(date +'%d.%m.%Y_%H.%M') #tar.gz name
bTIME=13
mailTO="admin@vizor.com"
#erroraction=
#bLOG=$bDEST/log.log
#all logs in syslog

notyfi() {
    /usr/bin/sendmail -t <<ERRMAIL
    To: $mailTO
    From: <backup@$HOSTNAME>
    Subject: "$1"
    Content-Type: text/plain; charset=UTF-8

"$2"
ERRMAIL
}

backup() {
         if ! [ -d "$bDEST" ] #if dir not exist 
         then
         mkdir -p "$bDEST"/"$bDATE" 
         fi
         
         if [ -d "$bSORC" ] #not to back up emptiness
         then
            if ! tar -g "$bDEST"/snar -czvf "$bDEST"/"$bDATE"/"$bNAME".tar.gz -C "$bSORC" . #>> "$bDEST"/"$bNAME".log
            then
            echo "ERROR! $bNAME" #to do: send alert if failure
            return 1
            else
            echo "Completed! $bNAME" #to do: send alert
            return 0
            fi 
         
         else
         echo "Warning. Nothing to do, wrong path $bSORC"
         return 1
         fi
}

delete() {
         find "$bOLD"/ -mtime +"$bTIME" -type f -delete #delete archives older than 13 days  
}

full() {
    if ! [ -d "$bOLD" ] #if dir not exist
    then
    mkdir -p "$bOLD"
    fi
    if tar -czvf "$bOLD"/"$bNAME".full.tar.gz -C "$bDEST" . #>> "$bOLD"/"$bNAME".full.log #if OK
    then 
    rm -fr "$bDEST" #flush last week
        if backup #start new
        then 
        delete #remove old backup level 0 if OK
        return 0
        else
        return 1
        fi
    return 1
    fi
}

#work***********************
case $1 in #check $1
   inc) backup ;; # notyfi() 
   full) full ;; # notyfi() 
   del) delete ;;
   *) echo "Start with options: inc(incremental,new), full, del(remove old)" ;;
esac

