#!/bin/bash

fruits=("apple" "banana" "cherry")

# Method 1: Loop over values 
for item in "${fruits[@]}"; do 
echo "Fruit: $item" 
done 

# Method 2: Loop over indices 
for i in "${!fruits[@]}"; do 
echo "Index $i -> ${fruits[$i]}" 
done
