readarray -t names < names.txt 
i=0 
while [ $i -lt ${#names[@]} ]; do 
  echo "Name $i: ${names[$i]}" 
  ((i++)) 
done
