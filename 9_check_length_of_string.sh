#!/bin/bash
read -p "enter the bappID:" bappid
if [[ -n $bappid ]]
then
echo "bappid exists"
elif [[ -z $bappid ]]
then
echo "bappid doesnt exist"
fi