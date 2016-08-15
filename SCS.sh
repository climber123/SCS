#!/bin/bash

#This script is written by Ilshat Akhmetzaynov in 2014
#to copy files over SSH 
#to find IPs available for pinging 
#to make a list of those IPs and logged users
#to manual correction of that list
#to chacnge file attributes on remote machines
#

#variables

eth_iface=0
localIP=127.0.0.1
networkIP=127.0.0
end_message="SCS script has finished"

#functions

function GetCurrentIp ()
{
	IPs=$( /sbin/ifconfig | grep addr: | awk -F "inet addr:" '{print $2}' | awk -F " " '{print $1}' | tr -s '\r\n' ' ')
	echo "IP in one string (\$IPs) is: $IPs" >> ./SCS.log
	IP_addresses=0
		for num in $IPs
		do
			if [ ! $num = "127.0.0.1" ]
        	then
        		IP_addresses[$eth_iface]=$num
       			echo "IP addresses of eth$eth_iface are defined: ${IP_addresses[$eth_iface]}" >> ./SCS.log
				((eth_iface +=1))
			fi
    	done
}

function PingSequence ()
{
	num=0
	echo "Network interfaces found on this machine:"
		while [ ! -z ${IP_addresses[$num]} ] #IP addresses of this machine
		do
    		echo ${IP_addresses[$num]}
    		((num +=1))
		done
	echo ""
	echo "Enter IP of the subnet like XXX.XXX.XXX"
	read networkIP
	TestInput  #checks input is ip-like
	currentIP=1
	echo "$IP_addresses"
	while [ "$currentIP" -le 254 ]
    do
		for num in $IP_addresses
		do
			if [ $num != $Abyte.$Bbyte.$Cbyte.$currentIP ]
	    	then
	    		ping $Abyte\.$Bbyte\.$Cbyte\.$currentIP -c 1 | grep 64\ bytes | awk -F "from " '{print $2}' | awk -F ":" '{print $1}'>> ./SCS_up_machines.txt &
			fi
		done
		echo -n "*"
		((currentIP +=1))
    done

	MakeAChoice #Shows menu
}

function TestInput () #Checking the network IP for its OKability
{
	if [ -z $networkIP ] 
    	then 
    		WrongIp
	fi
	Abyte=$( echo "$networkIP" | awk -F "." '{print $1}' ) 
	Bbyte=$( echo "$networkIP" | awk -F "." '{print $2}' )
	Cbyte=$( echo "$networkIP" | awk -F "." '{print $3}' )
	Dbyte=$( echo "$networkIP" | awk -F "." '{print $4}' )
	if [ $Abyte -gt 255 -o  $Bbyte -gt 255 -o $Cbyte -gt 255 ] # checks if a number is less then 255, asking again if not
    	then 
    		WrongIp
	fi
}

function WrongIp ()
{
    echo "You have entered wrong subnet IP"
    echo "Enter IP of the subnet like XXX.XXX.XXX"
    read networkIP
	echo ""
	TestInput
}

function CleanTemp ()
{
	date > ./SCS.log
	echo "Script situates in: $currentDIR" >> ./SCS.log
}

function MakeAChoice ()
{

	echo ""
	echo "(0) Write list of active machines into ./SCS_up_machines.txt"
	echo "(1) Make list of current users at machines into ./SCS_up_users.txt"
	echo "(2) Make SSH friends with machines from ./SCS_up_machines.txt"

	echo "(3) Copy files to machines from ./SCS_up_users.txt"
	echo "(4) Change file owners for machines from ./SCS_up_users.txt"
	echo "(5) Change file attributes for machines from ./SCS_up_users.txt"

	echo "(6) Power off machines from ./SCS_up_users.txt"

	echo "(9) Quit from the script"

	echo ""
	echo ""
	read -n 1 yourchoice

	case "$yourchoice" in
		0)
		    echo ""
		    MakeMachinesList
		    ;;
		1)
		    echo ""
		    GetCurrentUsers
		    ;;
		2)
		    echo ""
		    ShakeSSHHAnds
		    ;;
		3)
		    echo ""
		    CopyFiles
		    ;;
		4)
		    echo ""
		    CHattr
		    ;;
		5)
		    echo ""
		    ChangeAttributes
		    ;;
		6)
		    echo ""
		    ;;
		9)
		    echo "Script finished"
		    exit
		    ;;
		*)
			echo "Wrong choice"
			MakeAChoice
			;;
	esac
}

function ShakeSSHHAnds ()
{

	if [ ! -e $HOME/.ssh/id_rsa -o ! -e $HOME/.ssh/id_rsa.pub ]
	    then
			echo "No RSA-key in $HOME/.ssh/"
			echo "Creating RSA-key"
			ssh-keygen -q -t rsa -f $HOME/.ssh/id_rsa #MAKE RSAs if thy aren't
	fi

	for j in $(cat ./SCS_up_users.txt)
	do
		if [ ! -e j ]
			then
			juser=$( echo "$j" | awk -F "@" '{print$1}' )
			jip=$( echo "$j" | awk -F "@" '{print$2}' )

	    ssh-copy-id -i $HOME/.ssh/id_rsa.pub $juser@$jip #Copy public keys in authorized_keys of a remote machine
	    ssh-copy-id -i $HOME/.ssh/id_rsa.pub root@$jip

	    echo "ssh to $juser""@$jip added" >> ./SCS.log
		fi
	done
	MakeAChoice
}
function checkVALIDfiles ()
{
	read sourceNAME
	if [ ! -d $sourceNAME ]
	    then
	    echo "There is no such catalog"
	    elif [ ! -e $sourceNAME ]
	    then
	    echo "There is no such file"
	    checkVALIDfiles
	fi
}

function CopyFiles ()
{
	echo "What do you want to copy?"
	checkVALIDfiles
	echo "Where do you want to copy taht?"
	read targetNAME
	echo "Will copy $sourceNAME into $targetNAME of remote machines" >> ./SCS.log

	for j in $(cat ./SCS_up_users.txt)
		do
			scp -r $sourceNAME $j:$targetNAME
		done
	echo ""
}

function ChangeAttributes ()
{
	echo "Be carefull with this function!"
	echo ""
	echo ""
	echo "Which remote machines files attributes to change?"
	read what_files
	echo ""
	echo ""
	echo "If the current remote user an owner of the files on that remote machines? Y|N"
	read -n 1 yes_or_no
	case "$yes_or_no" in
	Y|y|YES|"yes"|Yes)
	    echo ""
		for j in $(cat ./SCS_up_users.txt)
		    do
			nn=$(echo $j | awk -F "@" '{print $1}')
			ssh -q root@$(echo $j | awk -F "@" '{print $2}') "if [ -e $what_files -o -d $what_files ]; then chown -R $nn $what_files; fi"
		    done
	    ;;
	N|n|NO|no|No)
	    echo ""
	    echo "Which user must be owner of that files?"
		read new_owner
	for j in $(cat ./SCS_up_users.txt)
		    do
			nn=$(echo $j | awk -F "@" '{print $1}')
			ssh -q root@$(echo $j | awk -F "@" '{print $2}') "if [ -e $what_files -o -d $what_files ]; then chown -R $new_owner $what_files; fi"
		    done
	    ;;
	*)
	    echo "Entered keys wrong, try again"
	    ChangeAttributes
	;;
	esac
	echo ""
	MakeAChoice
}


function CHattr ()
{
	echo "Be carefull with this function!"
	echo ""
	echo ""
	echo "Which remote machines files attributes to change?"
	read what_files
	echo ""
	echo ""
	echo "What new attributes must be (enter 3 digit-like attributes)?"
	read the_attributes
	attr=$(echo "$the_attributes" | wc -m ) 
	if [ $attr -eq 4 -a $the_attributes -le 777 ]
	then
	for j in $(cat ./SCS_up_users.txt)
		    do
			nn=$(echo $j | awk -F "@" '{print $1}')
		ssh -q root@$(echo $j | awk -F "@" '{print $2}') "if [ -e $what_files -o -d $what_files ]; then chmod -R $the_attributes $what_files; fi"
		    done
	else
	echo "Entered keys wrong, try again"
	CHattr
	fi
	echo ""
	MakeAChoice
}


function PowerOFF ()
{
	echo "Sending poweroff comman to remotes"
	for j in $(cat ./SCS_up_users.txt)
		do
			n=$(echo $j | awk -F "@" '{print $2}')
			ssh -q root@$n "poweroff"
		done
	echo ""

}

function MakeMachinesList ()
{
	if [ ! -e ./SCS_up_machines.txt ] 
	then
		touch ./SCS_up_machines.txt
	fi
	echo "upPCs in "$currentDIR"/scriptTMP.txt have been cleaned." >> ./SCS.log
	GetCurrentIp
	PingSequence
	echo ""
	echo "Ping available machines written to ./SCS_up_machines.txt"
	cat ./SCS_up_machines.txt
	echo "Machines in the network $Abyte.$Bbyte.$Cbyte with IP address listed above are accessable by ping."
}

function GetCurrentUsers ()
{
	echo -n "" > ./SCS_up_users.txt
	echo "Enter remote machines ROOT passwords"
	for j in $(cat ./SCS_up_machines.txt)
		do
			tmp=`ssh root@$j "who -u | grep :0"`
			curUSER=$(echo $tmp | awk '{print $1}')
			echo "$curUSER@$j" >> ./SCS_up_users.txt
		done
	echo "Current logged on remote machines users defined"
	echo "Users logged on remote machines are defined!" >> ./SCS.log
	MakeAChoice
}

function GoStart ()
{
	if [ ! -e ./SCS_up_machines.txt ] 
		then
			touch ./SCS_up_machines.txt
	fi
	if [ ! -e ./SCS_up_users.txt ] 
		then
			touch ./SCS_up_users.txt
	fi
}

#program body

#finish tests
currentDIR=`pwd`
GoStart
CleanTemp &
MakeAChoice
echo $end_message
read end_message
