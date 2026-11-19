#!/bin/bash

read -p "enter the age:" age

if [[ $age -lt 18 && $age -gt 0 ]]
then
echo "person is a MINOR!"
elif [[ $age -gt 18 && $age -lt 100 ]]
then
echo "person is MAJOR!"
else
echo "invalid age"
fi