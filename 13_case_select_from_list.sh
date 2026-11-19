#!/bin/bash 

# (COMBINE CASE AND SELECT) select the language they speak from the list of countries

PS3="choose your country:" 
select COUNTRY in Germany France "United Kingdom" 
do 
case $REPLY in 
1) 
echo "you speak Germany" 
;; 
2) 
echo "you speak French" 
;; 
3) echo "you speak English" 
;; 
4) 
echo "you speak all 3 languages" 
;; 
*) 
echo "invalid $REPLY" 
echo "quitting..." 
exit 
;; 
esac 
done
