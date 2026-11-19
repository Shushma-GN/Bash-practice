#!/bin/bash 

# break the loop when ping is not working.

while true 
do 
ping -c 1 $1 &> /dev/null 
if [[ $? -eq 0 ]] 
then 
echo "OK" 
else 
echo "im exiting while loop!" 
break 
fi 
sleep 2 
done
echo "ping to $1 is not working, im sending email to the admin"
