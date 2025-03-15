#!/bin/ksh

[ "$(whoami)" != "oracle" ] && echo "Please run this script as oracle user." && exit 1
[ $# -lt 1 ] && echo "Usage: $0 [ORACLE_SID]" && exit 1

DISK_USAGE_THRESHOLD=96
DISK_USAGE=$(df -h /oradata/${1}/a01 | tail -1 | awk '{print $5}' | sed 's/%//')

if  [ "$DISK_USAGE" == "" ]; then
  echo "Disk usage could not be determined."
elif [ $DISK_USAGE -gt $DISK_USAGE_THRESHOLD ]; then
  echo "$(date +'%Y-%m-%d %H:%M:%S') INFO - Disk usage > ${DISK_USAGE_THRESHOLD}%  (=${DISK_USAGE}%) => Trigger purge"
  /opt/oracle/operating/bin/purge_archive_logs.ksh $1 > /tmp/purge_archivelog_${1}.log
else
  echo "$(date +'%Y-%m-%d %H:%M:%S') INFO - Disk usage is OK (${DISK_USAGE}%)"
fi

