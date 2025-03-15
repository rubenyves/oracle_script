#!/bin/ksh

[ $(whoami) != 'oracle' ] && echo "Please run this script as oracle user" && exit 1
[ $# -lt 2 ] && echo "Usage: $0 [ORACLE_SID] [enable|disable|status]" && exit 1

export ORACLE_SID=$1
grep $ORACLE_SID /etc/oratab > /dev/null
test $? -ne 0 && echo "Incorrect SID." && exit 1

case "$2" in 
	enable)
	  MODE="ARCHIVELOG"
	  ;;
	disable)
	  MODE="NOARCHIVELOG"
	  ;;
        status) 
          sqlplus -L -s / as sysdba <<< "
          archive log list;
          exit;
          "
          exit 0
          ;;	
	*) 
	echo "Usage: $0 [ORACLE_SID] [enable|disable]"
	exit 0
	;;
esac

/opt/operating/bin/OperateOracleAll.ksh -stop instance $ORACLE_SID

if [ $MODE == "NOARCHIVELOG" ]; then 
 echo "Disable log archiving"
 sqlplus -L -s / as sysdba <<< "
startup mount; 
ALTER DATABASE NOARCHIVELOG;
shutdown immediate;
exit;
"
else
 echo "Enable log archiving"
 sqlplus -L -s / as sysdba <<< "
startup mount;
ALTER DATABASE ARCHIVELOG;
shutdown immediate;
exit;
"
fi

/opt/operating/bin/OperateOracleAll.ksh -start instance $ORACLE_SID
