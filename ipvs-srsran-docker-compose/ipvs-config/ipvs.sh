#!/usr/bin/bash

exec 1> /var/log/ipvsadm-log.txt 2>&1
set -x

IPVS=/usr/sbin/ipvsadm
VIP=172.18.0.103 #Define VIP
VPORT=36412 #Define the virtual port of LVS
RPORT=36412 #Define the port of Realserver

$IPVS -A --sctp-service $VIP:$VPORT -s rr -m

del_realserver() { #Define the function to delete Realserver
  $IPVS -ln | grep -w $1
  if [ "$?" = 0 ]
  then
    echo "Host $i is in the ipvsadm table, proceeding to delete it"
    $IPVS -d --sctp-service $VIP:$VPORT -r $1:$RPORT
    echo "Proceeding to delete Host $1"
  else
    echo "Host $1 is already deleted, no further action needed"
  fi
}

add_realserver() {  #Define the function of adding Realserver
  $IPVS -ln | grep -w $1
  if [ "$?" = 0 ]
  then
    echo "Host $1 is already in the ipvsadm table, no further action needed"
  else
     echo "Host $i is not in the ipvsadm table, proceeding to add it"
     $IPVS -a --sctp-service $VIP:$VPORT -r $Host:$RPORT -m
     echo "Host $1 has been added"
  fi
}

while true; do
    for I in {73,74};do 

        Host=10.240.216.$I

        fping -c3 -t300 $Host 2>/dev/null 1>/dev/null

        if [ "$?" = 0 ]
        then
          echo "Host $Host is up, proceeding to check if it is in the ipvsadm table and add if it is not in the ipvsadm table"
          add_realserver $Host
        else
          echo "Host $Host is down, proceeding to check if it is in the ipvsadm"
          del_realserver $Host
        fi
    sleep 3
    done
done