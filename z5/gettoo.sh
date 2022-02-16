#!/bin/bash
#Создать bash сценарий который будет скачивать свежий gentoo install-amd64-minimal.iso образ отсюда: http://distfiles.gentoo.org/releases/amd64/autobuilds/current-install-amd64-minimal/ #и осуществлять его ремастеринг. А именно модификацию iso образа с внедрением публичного ssh ключа и добавление sshd сервиса в автозагрузку. Результат - это запуск виртуальной машины или #ПК с этого образа должен получать по dhcp ip адрес и запускать ssh сервер к которому можно подключится по приватному ssh ключу без пароля.  Приватный и публичный ssh ключи представлены #ниже:
#
#private_ssh_key:
#P.S. информация об актуальном iso образе содержится тут: http://distfiles.gentoo.org/releases/amd64/autobuilds/latest-install-amd64-minimal.txt

gARC=amd64
gBILD=$(curl -s http://distfiles.gentoo.org/releases/$gARC/autobuilds/latest-install-$gARC-minimal.txt | grep -oE '^[^#\/]+')
gISO="install-$gARC-minimal-$gBILD.iso"
#gSTATE=admincd)
#gMIRr=http://ftp.vectranet.pl/gentoo/releases/amd64/autobuilds/current-install-amd64-minimal/
gURL="http://distfiles.gentoo.org/releases/$gARC/autobuilds/current-install-$gARC-minimal/$gISO"
gDIR="$(pwd)"/ISO
#DIGESTS.asc
#-o "$gDIR" grep -Eo '\b.+asc$'

update-key() {
wget -O - https://qa-reports.gentoo.org/output/service-keys.gpg | gpg --import #impory new key
#list=$(ls "$gDIR" | grep -Eo '\w+asc$')

if ! [ -f "$gDIR/$gISO.asc" ] #if not exist
  then
    wget -P "$gDIR" "$gURL.asc"  #download sign
elif ! [ -f "$gDIR/$gISO.DIGESTS" ] #if not exist
  then
    wget -P "$gDIR" "$gURL.DIGESTS" #download SHA512
else
  echo "Latest version already exist in $gDIR"
fi

# verefi all gpg key
for file in "$gDIR"/*asc
  do
    if ! gpg --verify "$file"
      then
        echo "ERROR! failed verify $file"
    fi
done
}

resdownload() {

if ! [ -f "$gDIR/$gISO" ] #if not exist iso
  then
    wget -P "$gDIR" "$gURL" # download iso
  else 
    echo "Latest version .iso already exist in $gDIR"
fi

if ! [ -f "$gDIR/$gISO".CONTENTS.gz ]
  then
    wget -P "$gDIR" "$gURL.CONTENTS.gz" # download cont
  else
    echo "Latest version CONTENTS already exist in $gDIR"
fi

update-key

sha-verifi

}


sha-verifi() {

gSHA=$(sha512sum "$gDIR"/"$gISO" | cut -d ' ' -f 1) #get SHA512
fSHA=$(grep -E '^\w+.+iso$' "$gDIR"/"$gISO".DIGESTS | cut -d ' ' -f 1) #get SHA512 too

if [ "$gSHA" = "$fSHA" ]
  then
    echo "SHA256 verification successful!"
  else
    echo "ERROR! SHA256 verification failed!"
fi
}

#remaster() {}



#todo*************************remastering!!
echo "SH script for download latest Gentoo Linux and optionally add company ssh keys to .iso"
select number in "Check, download and verifi new .iso" "Verifi existing .iso" "Remastering" "4-Exit"
do  
  case $number in
    1) resdownload;;
    2) update-key && sha-verifi;;
    3) remaster;;
    4) break;;
    *) echo something wrong;;
  esac
done
