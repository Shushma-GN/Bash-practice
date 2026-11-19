#!/bin/bash
read -p "enter the ip address:" $ip
echo "blocking $ip"
sudo iptables -I INPUT -s "$ip" -j DROP
sleep 2
echo "blocked $ip"