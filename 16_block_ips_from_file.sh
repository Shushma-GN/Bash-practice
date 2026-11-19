#!/bin/bash


for ip in $(cat ips.txt) 
do
echo "Dropping packets from $ip" 
iptables -I INPUT -s $ip -j DROP 
done

#!/bin/bash 
while read ip 
do 
        echo "dropping the packets from $ip" 
        iptables -I INPUT -s $ip -j DROP 
        sleep 1 
done< ./ips.txt               or done< <(cat ips.txt)
