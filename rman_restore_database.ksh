#!/bin/ksh
# @(#):Version:1.4.0
#----------------------------------------------------------------------------------------------------
# Copyright(c) 2005 France Telecom Corporation. All Rights Reserved.
#
# NAME
#   rman_restore_database.ksh
#
# DESCRIPTION                           
#   Complete restore of the database via RAMN
#
# REMARKS
#
#    The script must be executed by the owner of the oracle product (oracle account)
#
#    Input parameters : 
#            ORACLE_SID --> instance name
#
#    Output : 
#            Log file /oradata/<SID>/adm/dbalog/rman_restore_database_jjmmyyyy_hhHmm.log
#
# MODIFICATIONS
#    Fabrice CHAILLOU (FT/DROSI/DPS/ISS) - 09/02/2005 - 1.0.0 - Creation
#    Fabrice CHAILLOU (FT/DROSI/DPS/ISS) - 04/04/2005 - 1.1.0 - Evolution
#    Fabrice CHAILLOU (FT/DROSI/DPS/ISS) - 11/09/2006 - 1.2.0 - Modification fonction database_role
#    Adrian Benga (FT/OLNC/IBNF/ITE/ECV) - 24/01/2013 - Evolution 1.3.0
#                                          Prepared for CB standard
#                                          Added start/stop of the logical standby replication
#    Adrian BENGA     (OR/IMT/INBF/ITE/ECV) - 29/07/2014 - 1.4.0 - Adaptation for OM G4R4 architecture
#----------------------------------------------------------------------------------------------------

#----------------------------------------------------------------------------------------------------
# Debug mode activation
#----------------------------------------------------------------------------------------------------
set +x

#----------------------------------------------------------------------------------------------------
# Display function
#----------------------------------------------------------------------------------------------------
banner()
{
timeb=`date +"%d/%m/%Y %HH%M"`
echo "---------------------------------------------------------------------------------------------------------"|tee -a $log
echo "  $1\t\tDatabase: ${ORACLE_SID}\t\t$2:\t$timeb"|tee -a $log
echo "---------------------------------------------------------------------------------------------------------"|tee -a $log
}

#----------------------------------------------------------------------------------------------------
# Check parameter files
#----------------------------------------------------------------------------------------------------
check_parfiles()
{
if [[ -r $ora_paramfile && -r $ora_kernelparamfile && -r $ora_sidparamsDB ]]
then 
    return 0
elif [[ ! -r $ora_paramfile ]]
then
    echo "\nPARAMETER FILE $ora_paramfile IS NOT PRESENT.\n" 
    return 1
elif [[ ! -r $ora_kernelparamfile ]]
then
    echo "\nPARAMETER FILE $ora_kernelparamfile IS NOT PRESENT.\n" 
    return 1
elif [[ ! -r $ora_sidparamsDB ]]
then
     echo "\nPARAMETER FILE $ora_sidparamsDB IS NOT PRESENT.\n"  
    return 1
fi
}

#----------------------------------------------------------------------------------------------------
# Set environment variables
#----------------------------------------------------------------------------------------------------
set_var_ora()
{
export ORACLE_SID=$sid
os=`uname -a | awk '{print $1}'`
if [ $os = 'SunOS' ]
   then
     ORATAB=/var/opt/oracle/oratab
   else
     ORATAB=/etc/oratab
fi
export ORACLE_HOME=`grep ${ORACLE_SID} $ORATAB | awk -F: '{print $2'}`
export PATH=${ORACLE_HOME}/bin:$PATH
}

#----------------------------------------------------------------------------------------------------
# Listener startup
#     $1 : listener name
#----------------------------------------------------------------------------------------------------
start_listener()
{
${ORACLE_HOME}/bin/lsnrctl status $1 1>/dev/null 2>&1
if [ $? -eq 0 ]
   then 
     echo "\nThe listener $1 is already started.\n"|tee -a $log
     ps -ef|grep "[t]ns.*$1[ ]" | tee -a $log
     return 0
   else
     ${ORACLE_HOME}/bin/lsnrctl start $1 | tee -a $log
fi
${ORACLE_HOME}/bin/lsnrctl status $1 1>/dev/null 2>&1
if [ $? -eq 0 ]
   then
     echo "\nThe listener $1 is started.\n"|tee -a $log
     ps -ef|grep "[t]ns.*$1[ ]" | tee -a $log
     return 0
   else
     echo "\nThe listener $1 is not started.\n"|tee -a $log
     return 1
fi
}

#----------------------------------------------------------------------------------------------------
# Listener stop
#      $1 : listener name
#----------------------------------------------------------------------------------------------------
stop_listener()
{
if [ `ps -ef|grep -c "[t]ns.*$1[ ]"` -eq 0 ]
   then
     echo "\nThe listener $1 is already stopped.\n"|tee -a $log
     return 0
   else
     ${ORACLE_HOME}/bin/lsnrctl stop $1 | tee -a $log
     sleep 2
fi
if [ `ps -ef|grep -c "[t]ns.*$1[ ]"` -eq 0 ]
   then
     echo "\nThe listener $1 is stopped.\n"|tee -a $log
     return 0
   else
     echo "\nThe listener $1 is not stopped.\n"|tee -a $log
     return 1
fi
}

#----------------------------------------------------------------------------------------------------
# Database stop 
#----------------------------------------------------------------------------------------------------
shutdown_immediate()
{
if [ `ps -ef|grep -c "[o]ra_pmon_${ORACLE_SID}"` -eq 0 ]
   then
     echo "The database ${ORACLE_SID} is already closed.\n"|tee -a $log
     return 0
   else
${ORACLE_HOME}/bin/sqlplus -s "/ as sysdba"<<FINSI|tee -a $log
Prompt SQL>shutdown immediate
shutdown immediate
exit
FINSI
fi
if [ `ps -ef |grep -c "[o]ra_pmon_${ORACLE_SID}"` -eq 0 ]
   then
     echo " "
     echo "The database ${ORACLE_SID} is stopped.\n"|tee -a $log
     return 0
   else
     echo " "
     echo "The database ${ORACLE_SID} is not stopped."|tee -a $log
     echo "View the log /oradata/${ORACLE_SID}/adm/bdump/alert_${ORACLE_SID}.log\n"|tee -a $log
     return 1
fi
}

#----------------------------------------------------------------------------------------------------
# Database startup
#       $1 = startup option
#----------------------------------------------------------------------------------------------------
startup()
{
mode=$1
if [ `ps -ef|grep -c "[o]ra_pmon_${ORACLE_SID}"` -eq 1 ]
   then
     echo "The database ${ORACLE_SID} is not closed.\n"|tee -a $log
     return 1
   else
${ORACLE_HOME}/bin/sqlplus -s "/ as sysdba"<<FINS|tee -a $log
Prompt SQL>startup $1
startup $1
exit
FINS
fi
}

#----------------------------------------------------------------------------------------------------
# Open database
#----------------------------------------------------------------------------------------------------
alter_database()
{
if [ $Ora_Env = "DBRef" ]
then
	${ORACLE_HOME}/bin/sqlplus -s "/ as sysdba"<<-FINAD|tee -a $log
	Prompt SQL>alter database open;
	alter database open;
	Prompt SQL> alter system set log_archive_dest_state_2=enable;
	alter system set log_archive_dest_state_2=enable;
	ALTER DATABASE START LOGICAL STANDBY APPLY IMMEDIATE;
	exit
	FINAD
else
	${ORACLE_HOME}/bin/sqlplus -s "/ as sysdba"<<-FINAD|tee -a $log
	Prompt SQL>alter database open;
	alter database open;
	exit
	FINAD
fi

}

#----------------------------------------------------------------------------------------------------
# Check database status
#----------------------------------------------------------------------------------------------------
database_test()
{
cde=`${ORACLE_HOME}/bin/sqlplus -s "/ as sysdba"<<-FINIS
set head off
select open_mode from v\\$database;
exit
FINIS`
istatus=`echo "$cde"|egrep "^ORA-|READ|MOUNTED"`
case "$istatus" in
     'READ ONLY')  msgis="The database ${ORACLE_SID} is read only opened.\n" ; return 1;;
     'READ WRITE') msgis="The database ${ORACLE_SID} is read write opened.\n"; return 0;;
     'MOUNTED')    msgis="The database ${ORACLE_SID} is mounted (not opened).\n" ; return 2;;
     *ORA-01507*)  msgis="The database ${ORACLE_SID} is not mounted.\n" ; return 3;;
     *ORA-01034*)  msgis="The database ${ORACLE_SID} is not available.\n" ; return 3;;
     *ORA-01090*)  msgis="Shutdown in progress on database ${ORACLE_SID}.\n" ; return 3;;
     *       )     msgis=$istatus ; return 3;;
esac
}

#----------------------------------------------------------------------------------------------------
# execute a select in the database and return the result
#     $1 : SQL request without select word
#----------------------------------------------------------------------------------------------------
oracle_var()
{
VAR_SHELL=$1    DISTINCT=
eval $VAR_SHELL=
[ "$2" = distinct ] &&  DISTINCT=distinct && shift
SCRIPT_SQL="select $DISTINCT 'BiDoN='||$2 ;"

OutputSql=`echo "whenever sqlerror exit 1
$SCRIPT_SQL" |\
sqlplus -s "/ as sysdba" | grep "^BiDoN=" `

if [ $? = 0  -a  "$OutputSql" != "BiDoN=" ]
   then
     SaNsBiDoN=`echo "$OutputSql" | sed -e "s/^BiDoN=//g"`
     eval $VAR_SHELL=\$SaNsBiDoN
     return 0
   else
     echo "\n\nSCRIPT_SQL=$SCRIPT_SQL"
     echo "$SCRIPT_SQL" | sqlplus -s "/ as sysdba"
     return 1
fi
}

#----------------------------------------------------------------------------------------------------
# Get the current role of the database PRIMARY ou PHYSICAL STANDBY
#----------------------------------------------------------------------------------------------------
database_role()
{
database_test
if [ $? -eq 1 ]
   then
     ls -l ${ORACLE_HOME}/dbs/spfile${ORACLE_SID}.ora 1>>/dev/null 2>&1
     if [ $? -eq 0 ]
        then
          role="PRIMARY"
        else
          role=`ls -l ${ORACLE_HOME}/dbs/init${ORACLE_SID}.ora | awk -F"_" '{print $2}'`
          if [ "$role" = "STANDBY" ]
             then
               role="PHYSICAL STANDBY"
          fi
     fi
   else
     oracle_var role "database_role from v\$database"
fi
}

#----------------------------------------------------------------------------------------------------
# Database restore via RMAN
#----------------------------------------------------------------------------------------------------
rman_restore()
{
target=/
${ORACLE_HOME}/bin/rman target $target nocatalog <<EOF|tee -a $log
run {
     restore database;
     recover database;
 }
exit 0;
EOF
}

#----------------------------------------------------------------------------------------------------
# Main
#----------------------------------------------------------------------------------------------------

export ora_paramfile=/etc/oraconf
export ora_kernelparamfile=/etc/orakernelparams
export ora_sidparamsDB=/etc/orasidparams

# check for configuration files. if not found, exit
check_parfiles
[ $? = 1 ] && exit 1

. ${ora_paramfile} > /dev/null 2>&1

sid=$1
if [ -z "$sid" ]
   then
     echo "The parameter ORACLE_SID is missing. Exit."
     exit 1
fi

set_var_ora

time=`date "+%d%m%Y_%HH%M"`
log=/oradata/${ORACLE_SID}/adm/dbalog/rman_restore_database_$time.log
history=/oradata/${ORACLE_SID}/adm/dbalog/${ORACLE_SID}_history.log
text="Rman Restore Database            "

if [ `uname -s` = "Linux" ]
   then
     alias echo='echo -e'
fi

if [ -w $log ]
   then
     rm $log
fi

banner "$text" Begin
database_role
if [ "$role" != "PRIMARY" ]
   then
    if [ "$role" != "LOGICAL STANDBY" ]
      then
      echo "The database ${ORACLE_SID} is in ${role} role."|tee -a $log
      banner "$text" End
      echo "$time\t\t$text\t\tNE">>$history
      exit 0
    fi
fi

echo "\nStep 1 : STOP APPLICATION LISTENERS\n"|tee -a $log
[ ! -z $Ora_ListenerAppName ] && stop_listener $Ora_ListenerAppName
rc1=$?
[ ! -z $Ora_ListenerAdmName ] && stop_listener $Ora_ListenerAdmName
rc2=$?
[ ! -z $Ora_ListenerRepName ] && stop_listener $Ora_ListenerRepName
rc3=$?
case "-${rc1}-${rc2}-${rc3}-" in
 -0-0-0-)  ;;
     *1*)  
	  banner "$text" End
      echo "$time\t\t$text\t\tNOK">>$history
      exit 1
	 ;;
esac

echo "\nStep 2 : SHUTDOWN IMMEDIATE\n"|tee -a $log
shutdown_immediate
if [ $? -eq 1 ]
   then
     echo "$time\t\t$text\t\tNOK">>$history
     banner "$text" End
     exit 1
fi

echo "\nStep 3 : STARTUP MOUNT\n"|tee -a $log
startup mount
database_test
if [ $? -ne 2 ]
   then
     echo "The database is not mounted."| tee -a $log
     echo "$time\t\t$text\t\tNOK">>$history
     banner "$text" End
     exit 1
fi

echo "\nStep 4 : RESTORE\n"|tee -a $log
rman_restore
if grep "RMAN-00569" $log 1>/dev/null 2>&1
   then
     echo "$time\t\t$text\t\tNOK">>$history
     banner "$text" End
     exit 1
fi

echo "\nStep 5 : OPEN DATABASE\n"|tee -a $log
alter_database
database_test
if [ $? -ne 0 ]
   then
     echo "$msgis"|tee -a $log
     echo "$time\t\t$text\t\tNOK">>$history
     banner "$text" End
     exit 1
fi

echo "\nStep 6 : START APPLICATION LISTENER\n"|tee -a $log
[ ! -z $Ora_ListenerAppName ] && start_listener $Ora_ListenerAppName
rc1=$?
[ ! -z $Ora_ListenerAdmName ] && start_listener $Ora_ListenerAdmName
rc2=$?
[ ! -z $Ora_ListenerRepName ] && start_listener $Ora_ListenerRepName
rc3=$?
case "-${rc1}-${rc2}-${rc3}-" in
 -0-0-0-) rc=0 ;;
     *1*) rc=1 ;;
esac
if [ $rc -eq 0 ]
   then
     echo "$time\t\t$text\t\tOK">>$history
     banner "$text" End
     exit 0
   else
     echo "$time\t\t$text\t\tNOK">>$history
     banner "$text" End
     exit 1
fi
