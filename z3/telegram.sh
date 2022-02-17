#!/bin/bash
export LC_ALL="C"
export LANG="en_US.UTF-8"
#------------------------------------------------------------------------------
.
 BOT_AUTH_TOKEN="$4"
 #https_proxy=
 LOG_FILE="/home/logs/telegram.log"
..
  DATETIME=$(date '+%Y/%m/%d %H:%M:%S')
  CHAT_ID="$1"
  SUBJ=$(echo "$2" | grep -v '.UNKNOWN. = .UNKNOWN.' | sed 's/\"//g')
  TEXT=$(echo "$3" | grep -v '.UNKNOWN. = .UNKNOWN.' | sed 's/\"//g')
...
   #------------------------------------------------------------------------------
....
    if [[ "${CHAT_ID}" == "getid" ]]; then
    #RESULT=$(curl -x "$https_proxy" -sS -i --max-time 30 "https://api.telegram.org/bot${BOT_AUTH_TOKEN}/getUpdates" 2>&1)
    RESULT=$(curl -- "https://api.telegram.org/bot${BOT_AUTH_TOKEN}/getUpdates" 2>&1)
    #curl --silent "https://api.telegram.org/bot${TOKEN}/getUpdates" | jq
    RC=$?
    if [ ${RC} -ne 0 ]; then
    echo "${RESULT}"
    exit 1
    elif ! echo "${RESULT}" | grep -iq '"ok":true'; then
    echo "${RESULT}"
    exit 1
    fi
    echo "${RESULT}" | awk -F'"chat":' '{print $2}' | awk -F'"date":' '{print $1}' | sort -u | grep --color -E "\-?[0-9]{7,}"
    exit 0
    elif [[ "${CHAT_ID}" =~ ^-?[0-9]+$ && -n "${TEXT}" ]]; then
    echo "[${DATETIME}] CHAT_ID:\"${CHAT_ID}\" TEXT=\"${SUBJ}\n$(echo ${TEXT}| tr "\r" " ")\"" >> "${LOG_FILE}"
    #RESULT=$(curl -x "$https_proxy" -sS -i --max-time 30 \
    #--header 'Content-Type: application/json' \
    #--request 'POST' \
    #--data '{"chat_id": "'"${CHAT_ID}"'", "text": "'"${SUBJ}\n${TEXT}"'","parse_mode": "HTML"}' \
    #"https://api.telegram.org/bot${BOT_AUTH_TOKEN}/sendMessage" 2>&1)
    RESULT=$(curl --sS -i --max-time 30 \
    --header 'Content-Type: application/json' \
    --request 'POST' \
    --data '{"chat_id": "'"${CHAT_ID}"'", "text": "'"${SUBJ}\n${TEXT}"'","parse_mode": "HTML"}' \
    "https://api.telegram.org/bot${BOT_AUTH_TOKEN}/sendMessage" 2>&1)
    RC=$?
    if [ ${RC} -ne 0 ]; then
    echo "${RESULT}" | tee -a "${LOG_FILE}"
    echo '' >> "${LOG_FILE}"
    exit 1
    elif ! echo "${RESULT}" | grep -iq '"ok":true'; then
    echo "${RESULT}" | tee -a "${LOG_FILE}"
    echo '' >> "${LOG_FILE}"
    exit 1
    fi
    #echo "${RESULT}" >> "${LOG_FILE}"
    #echo '' >> "${LOG_FILE}"
    echo "[OK] Message was sent"
    exit 0
    else
    echo "[${DATETIME}] CHAT_ID:\"${CHAT_ID}\" TEXT=\"${SUBJ}:${TEXT}\"" >> "${LOG_FILE}"
    echo "[EE] Invalid arguments" | tee -a "${LOG_FILE}"
    echo '' >> "${LOG_FILE}"
    exit 1
    fi

exit 0
