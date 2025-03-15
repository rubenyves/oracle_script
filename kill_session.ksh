#!/bin/ksh

[ $(whoami) != 'oracle' ] && echo "Please run this script as oracle user" && exit 1
[ $# -lt 1 ] && echo "Usage: $0 [ORACLE SID]" && exit 1

ORACLE_SID=$1 

echo -n > /tmp/${ORACLE_SID}_vsession.txt

RAS_ID=$(echo $ORACLE_SID | sed "s/^AML/RAS/")
EMB_ID=$(echo $ORACLE_SID | sed "s/^AML/EMB/")

sqlplus -L -s / as sysdba <<-EOF
 spool '/tmp/${ORACLE_SID}_vsession.txt';
 SELECT sid, serial# FROM v\$session where username in ('$ORACLE_SID','$RAS_ID','$EMB_ID');
 exit; 
EOF

sed -i '1,3d' /tmp/${ORACLE_SID}_vsession.txt
sed -i "s/^\s*//g;s/\s*$//g;s/ /,/;s/ //g" /tmp/${ORACLE_SID}_vsession.txt

while read line; do 
 if [ ! -z $line ]; then 
  echo "ALTER SYSTEM KILL SESSION '$line' IMMEDIATE;"
  sqlplus -L -s / as sysdba <<< "ALTER SYSTEM KILL SESSION '$line' IMMEDIATE;"
 fi
done <  /tmp/${ORACLE_SID}_vsession.txt

rm /tmp/${ORACLE_SID}_vsession.txt



