#!/bin/ksh 

[ $(whoami) != 'oracle' ] && echo "Please run this script as oracle user" && exit 1
[ $# -lt 2 ] && echo "Usage: $0 [ORACLE_SID] [DATE] [OPTIONS]" && exit 1 

export ORACLE_SID=$1
DATE=$2
NOW=$(date +'%Y%m%d')
shift 2
IMP_OPTIONS="$@"

grep $ORACLE_SID /etc/oratab > /dev/null
test $? -ne 0 && echo "Incorrect SID." && exit 1

[ ! -d /oradata/${ORACLE_SID}/u04 ] && echo "Missing /oradata/${ORACLE_SID}/u04 partition. Exit" && exit 1 
[ ! -d /oradata/${ORACLE_SID}/u05 ] && echo "Missing /oradata/${ORACLE_SID}/u05 partition. Exit" && exit 1

ls /oradata/${ORACLE_SID}/e01/${ORACLE_SID}_${DATE}*.dmp > /dev/null
test $? -ne 0 && echo "Dump files for the date ${DATE} not found in /oradata/${ORACLE_SID}/e01 directory. Exit." && exit 1

RAS_SCHEMA="RAS$(echo ${ORACLE_SID} | cut -b4-7)"
SCHEMAS="${RAS_SCHEMA}"

# Kill open session if exists

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

# Drop existing database 

echo -n > /oradata/${ORACLE_SID}/adm/create/ResetRASDbOra.sql
for schema in $SCHEMAS; do
 echo "drop user ${schema} cascade;" >> /oradata/${ORACLE_SID}/adm/create/ResetRASDbOra.sql
done
echo "exit;" >> /oradata/${ORACLE_SID}/adm/create/ResetRASDbOra.sql
sqlplus -L / as sysdba @/oradata/${ORACLE_SID}/adm/create/ResetRASDbOra.sql > /oradata/${ORACLE_SID}/adm/create/ResetRASDbOra.log
cat /oradata/${ORACLE_SID}/adm/create/ResetRASDbOra.log

echo "Import database $ORACLE_SID."
SCHEMAS=$(echo $SCHEMAS | tr ' ' ',')
echo -n "Schemas=$SCHEMAS, Options=$IMP_OPTIONS"
echo ""
nohup impdp \"/ as sysdba\" schemas=${SCHEMAS} $IMP_OPTIONS directory=DMPDIR dumpfile=${ORACLE_SID}_${DATE}_%U.dmp logfile=impdp${ORACLE_SID}_RAS-${NOW}.log parallel=8 > /dev/null &
