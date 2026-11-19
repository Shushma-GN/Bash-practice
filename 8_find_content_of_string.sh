#!/bin/bash

#connection testing

output="$(ping -c 3 $1)"
if [[ $output == *100%* ]]
then
echo "connecting to network"
else
echo "not connecting to network"
fi