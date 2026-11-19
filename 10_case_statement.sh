#!/bin/bash
read -p "enter the animal:" animal
case "$animal" in 
"dog" ) 
  echo "your fav animal is dog" 
  ;; 
"cat" | "CAT" | "kitty" ) 
  echo "your fav animal is cat" 
  ;; 
fish | "aquatic animals" ) 
  echo "your fav is water animals" 
  ;; 
* ) 
echo "all are your fav"
esac
