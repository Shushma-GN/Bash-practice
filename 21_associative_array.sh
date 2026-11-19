declare -A capitals=( 
[India]="New Delhi" 
[France]="Paris" 
  [Japan]="Tokyo" 
) 
# Loop over keys 
for country in "${!capitals[@]}"; do 
  echo "$country -> ${capitals[$country]}" 
done
