#!/bin/ksh


LOG() {
 echo "$(date +'%Y-%m-%d %H:%M:%S') INFO $1"
}

[ "$(whoami)" != "oracle" ] && echo "Please run this script as Oracle user." && exit 1
[ $# -lt 1 ] && echo "Usage $0 [CLIENT ID]" && exit 0

export ORACLE_SID=AML${1}
case $1 in
 CONF)
  export DBID=2666151747
  export SEQUENCE=11561
  export UNTIL_TIME="to_date('19/07/2021 00:00:00', 'DD/MM/YYYY HH24:MI:SS')"
  ;;
 
 LR01)
  export DBID=284208442
  export SEQUENCE=12188
  export UNTIL_TIME="to_date('23/07/2021 00:00:00', 'DD/MM/YYYY HH24:MI:SS')"
  ;;
 
 MA01)
  export DBID=1907853728
  export SEQUENCE=7164
  export UNTIL_TIME="to_date('19/07/2021 00:00:00', 'DD/MM/YYYY HH24:MI:SS')"

  ;;
 CM01)
  export DBID=3985753802
  export SEQUENCE=7608
  export UNTIL_TIME="to_date('19/07/2021 00:00:00', 'DD/MM/YYYY HH24:MI:SS')"
  export UNTIL_SCN=28720394
  ;;

 CD01)
  export DBID=3609972928
  export SEQUENCE=5553
  export UNTIL_TIME="to_date('19/07/2021 00:00:00', 'DD/MM/YYYY HH24:MI:SS')"
  export UNTIL_SCN=22211014
  ;;

 CI01)
  export DBID=3371880690
  export SEQUENCE=3739
  export UNTIL_TIME="to_date('19/07/2021 00:00:00', 'DD/MM/YYYY HH24:MI:SS')"
  export UNTIL_SCN=13817513

  ;;

 SL01)
  export DBID=3165669468
  export SEQUENCE=6845
  export UNTIL_TIME="to_date('19/07/2021 00:00:00', 'DD/MM/YYYY HH24:MI:SS')"
  export UNTIL_SCN=15195168
  ;;

 ML01)
  export DBID=2684651032
  export SEQUENCE=3506
  export UNTIL_TIME="to_date('19/07/2021 00:00:00', 'DD/MM/YYYY HH24:MI:SS')"
  export UNTIL_SCN=10621892
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

if [ ! -z "$UNTIL_SCN" ]; then 
LOG "Restore and recover database using UNTIL SCN=$UNTIL_SCN"
rman target / << EOF
RESET DATABASE TO INCARNATION 1;
RUN {
SET UNTIL SCN = $UNTIL_SCN;
restore database;
recover database;
}
exit;
EOF
else
LOG "Restore and recover database using UNTIL TIME=$UNTIL_TIME"
rman target / << EOF
RESET DATABASE TO INCARNATION 1;
RUN {
SET UNTIL TIME = "$UNTIL_TIME";
restore database;
recover database;
}
exit;
EOF


fi

LOG "Done."
LOG "Open database with RESETLOGS option."

sqlplus  / as sysdba << EOF
alter database open resetlogs;
exit;
EOF

#rman target / << EOF
#delete noprompt archivelog from time "$UNTIL_TIME";
#EOF

LOG "End of restoration of database $ORACLE_SID"

