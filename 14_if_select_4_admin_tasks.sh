#!/bin/bash 

# Run list of admin tasks: like 1) ADD USER 2) List all Processes 3) Kill Processes 4) Install Program 5) Quit

PS3="your choice:" 
select ITEM in "ADD USER" "List all Processes" "Kill Processes" "Install Program" "Quit" 
do 
        if [[ $REPLY -eq 1 ]] 
        then 
                read -p "enter the username:" username 
                output="$(grep -w $username /etc/passwd)" 
                if [[ -n "$output" ]] 
                then 
                        echo "username already exists!" 
                else 
                        sudo useradd -m -s /bin/bash "$username" 
                        if [[ $? -eq 0 ]] 
                        then 
                                echo "the $username has been added successfully" 
                                tail -n 1 /etc/passwd 
                        else 
                                echo "there was an error adding user" 
                        fi 
                fi 
        elif [[ $REPLY -eq 2 ]] 
        then 
                echo "list all the processes" 
                sleep 1 
                ps -ef 
        elif [[ $REPLY -eq 3 ]] 
then 
read -p "enter the process to kill:" process 
pkill $process 
elif [[ $REPLY -eq 4 ]] 
then 
read -p "enter the app name to install" app 
sudo apt update && sudo apt install $app -y 
else [[ $REPLY -eq 5 ]] 
echo "Quitting..." 
sleep 1 
exit 
fi 
done
