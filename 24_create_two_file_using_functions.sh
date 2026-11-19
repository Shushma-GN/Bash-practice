#!/bin/bash 
create_files(){ 
echo "creating file $1" 
touch $1 
echo "creating file $2" 
touch $2 
} 
create_files file1 file2
