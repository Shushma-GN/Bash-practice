if [[ $# != 2 ]] 
then 
echo "the script required two arguments" 
exit 1 
fi 
case "$1" in 
1 ) 
echo "sending the SIGHUP signal to $2" 
kill -SIGHUP $2 
;; 
2 ) 
echo "sending the SIGINT signal to $2" 
kill -SIGHUP $2 
;; 
3 ) 
echo "sending the SIGTERM signal to $2" 
kill -15 $2 
;; 
* ) 
echo "Signal no. $1 could not be delivered" 
;; 
esac
