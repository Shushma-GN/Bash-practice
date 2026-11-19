#!/bin/bash

if [[ -f $1 ]]
then
echo "$1 is a file"
cat $1
elif [[ -d $1 ]]
then
echo "$1 is a directory"
cd $1
ls -ll
else
echo "$1 is neither file nor directory"
fi
