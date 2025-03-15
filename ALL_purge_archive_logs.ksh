#!/bin/ksh

[ "$(whoami)" != "oracle" ] && echo "Please run the script as oracle user." && exit 1

echo "$(date)"

for i in $(cat /etc/oratab | grep -v '#' | grep -v '^$' | awk -F ':' '{print $1}')
do
  USAGE=$(df /oradata/$i/a01 | grep $i | awk '{print $5}')
  echo $USAGE | grep "9[0-9]%" > /dev/null && echo "$i - Archive log disk usage is $USAGE. Procceeding with purge." && /opt/oracle/operating/bin/purge_archive_logs.ksh $i
  echo $USAGE | grep "100%" > /dev/null && echo "$i - Archive log disk usage is $USAGE. Procceeding with purge." && /opt/oracle/operating/bin/purge_archive_logs.ksh $i
  echo $USAGE | grep -v "9[0-9]%" | grep -v "100%" > /dev/null && echo "$i - Archive log disk usage is $USAGE. OK."
done
