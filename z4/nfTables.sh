#!/bin/bash
#4. Имеется две приватных сети: 172.20.0.0/24 (интерфейс eth0) и 192.168.0.0/24 (интерфейс eth1), а так же доступ в интернет через провайдера с динамическим ip, подключённым к wan0 #интерфейсу (провайдер раздаёт настройки tcp/ip и dns по dhcp протоколу). Необходимо с помощью iptables и route на ОС linux (дистрибутив любой) дать доступ в интернет выделенной группе ip #адресов из обеих подсетей: 172.20.0.100-172.20.0.200 и 192.168.0.30-192.168.0.44 по следующим протоколам - icmp, dns, http, https, ssh, ntp, всё остальное закрыть. При этом дать #возможность обмениваться данными между двумя подсетями по smb протоколу. Хост имеющий ip - 172.20.0.100, может обмениваться данными с любым хостом из сети 192.168.0.0/24 по любому #протоколу без ограничений. Результат сгенерировать с помощью команды iptables-save, route -n (или netstat -rn) и представить в ответе.
#wont du this from Ansible