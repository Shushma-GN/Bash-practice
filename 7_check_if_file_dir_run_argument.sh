#!/bin/bash

if [[ $# -eq 1 ]]
then
    if [[ -f $1 ]]
    then
    echo "$1 is a file"
    cat $1
    elif [[ -d $1 ]]
    then
    echo "$1 is a dirtory"
    cd $1
    ls -ll
    else
    echo "invalid!"
    fi
else
echo "run with an argument"
fi
