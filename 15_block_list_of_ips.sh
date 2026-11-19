#!/bin/bash

ips="1.1.1.1 2.2.2.2 3.3.3.3"
for ip in $ips
do
echo "Dropping packets from $ip" 
iptables -I INPUT -s $ip -j DROP 
done