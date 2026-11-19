lambda_functions="fun1,fun2,fun3"
IFS=,
for function in $lambda_functions
do
echo $function
done
