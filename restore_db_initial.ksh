#!/bin/ksh


LOG() {
 echo "$(date +'%Y-%m-%d %H:%M:%S') INFO $1"
}

[ "$(whoami)" != "oracle" ] && echo "Please run this script as Oracle user." && exit 1
[ $# -lt 1 ] && echo "Usage $0 [CLIENT ID]" && exit 0

export ORACLE_SID=AML${1}
export UNTIL_TIME="to_date('19/07/2021 23:59:59', 'DD/MM/YYYY HH24:MI:SS')"

case $1 in
 CONF)
  export DBID=2666151747
  export SEQUENCE=11561
  ;;
 
 LR01)
  export DBID=284208442
  export SEQUENCE=12188
  export UNTIL_TIME="to_date('23/07/2021 23:59:59', 'DD/MM/YYYY HH24:MI:SS')"
  ;;
 
 MA01)
  export DBID=1907853728
  export SEQUENCE=7164
  export SCN=12670794
  ;;
 CM01)
  export DBID=3985753802
  export SEQUENCE=7608
  ;;

 CD01)
  export DBID=3609972928
  export SEQUENCE=5553
  ;;

 CI01)
  export DBID=3371880690
  export SEQUENCE=3739
  ;;

 SL01)
  export DBID=3165669468
  export SEQUENCE=6845
  ;;

 ML01)
  export DBID=2684651032
  export SEQUENCE=3506
  ;;

 *)
 LOG "Invalid CLIENT."
 exit 1 
 ;; 
esac 

LOG "Proceeding with database instance $ORACLE_SID. DBID=$DBID, SEQUENCE=$SEQUENCE"
LOG "Stop the database $ORACLE_SID"
sqlplus / as sysdba << EOF
shutdown immediate;
exit
EOF

LOG "Done."
LOG "Restore the control file for database $ORACLE_SID"
rman target / << EOF
startup nomount;
set dbid=$DBID;
restore controlfile from autobackup;
alter database mount;
exit;
EOF

LOG "Done."

LOG "Restore and recover the database $ORACLE_SID"

rman target / << EOF
RESET DATA
RUN {
SET UNTIL SEQUENCE $SEQUENCE;
restore database;
recover database;
}
#delete noprompt archivelog from time "$UNTIL_TIME";
#delete noprompt archivelog until time "$UNTIL_TIME";
exit;
EOF

LOG "Done."

LOG "Open database with RESETLOGS option."

sqlplus  / as sysdba << EOF
alter database open resetlogs;
exit;
EOF

LOG "End of restoration of database $ORACLE_SID"

