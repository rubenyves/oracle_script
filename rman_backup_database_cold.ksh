#!/bin/ksh
# @(#):Version:1.3.0
#----------------------------------------------------------------------------------------------------
# Copyright(c) 2005 France Telecom Corporation. All Rights Reserved.
#
# NAME
#   rman_backup_database_cold.ksh
#
# DESCRIPTION
#   Cold database backup with RMAN (database closed)
#
# REMARKS
#
#    The script must be executed by the owner of the oracle product (oracle account)
#
#    Input parameters : 
#            ORACLE_SID --> instance name
#
#    Output : 
#            Log file /oradata/<SID>/s01/<SID>_rman_backup_database_cold_jjmmyyyy_hhHmm.log
#
# MODIFICATIONS
#    Fabrice CHAILLOU (FT/DROSI/DPS/ISS) - 15/09/2005 - Creation     - 1.0.0
#    Fabrice CHAILLOU (FT/DROSI/DPS/ISS) - 02/11/2005 - Modification - 1.1.0
#                     Ajout de l'arret/demarrage du listener applicatif lors de la sauvegarde a froid
#    Adrian Benga     (FT/OLNC/IBNF/ITE/ECV) - 24/01/2013 - Evolution 1.2.0
#                                              Prepared for CB standard
#    Adrian BENGA     (OR/IMT/INBF/ITE/ECV) - 29/07/2014 - 1.3.0 - Adaptation for OM G4R4 architecture
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
echo "-------------------------------------------------------------------------------------------------------"|tee -a $log
echo "  $1\t\tDatabase: ${ORACLE_SID}\t\t$2:\t$timeb"|tee -a $log
echo "-------------------------------------------------------------------------------------------------------"|tee -a $log
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
# Check the oracle database status
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
     'READ ONLY')  msgis="The database ${ORACLE_SID} is read only opened.\n" ; return 0;;
     'READ WRITE') msgis="The database ${ORACLE_SID} is read write opened.\n"; return 0;;
     'MOUNTED')    msgis="The database ${ORACLE_SID} is mounted (not opened).\n" ; return 0;;
     *ORA-01507*)  msgis="The database ${ORACLE_SID} is not mounted.\n" ; return 1;;
     *ORA-01034*)  msgis="The database ${ORACLE_SID} is not available.\n" ; return 1;;
     *ORA-01090*)  msgis="Shutdown in progress on database ${ORACLE_SID}.\n" ; return 1;;
     *       )     msgis=$istatus ; return 1;;
esac
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
# Backup full of the database
#----------------------------------------------------------------------------------------------------
rman_backup()
{
target=/
if [ $Ora_Env = "DBRef" ]
then
	${ORACLE_HOME}/bin/rman target $target nocatalog <<-EOF|tee -a $log
	run {
	backup full database skip readonly format='${repsvg}/%d_RMAN_DATABASE_FULL_%D%M%Y_BS%s_BP%p_%t' TAG='$ORACLE_SID FULL $time';
	sql "ALTER DATABASE BACKUP CONTROLFILE TO ''${repsvg}/${ORACLE_SID}_RMAN_CTRLFILE_BCK_$time'' REUSE";
	sql "ALTER DATABASE OPEN";
	sql "ALTER DATABASE START LOGICAL STANDBY APPLY IMMEDIATE";
	sql "alter system set log_archive_dest_state_2=enable";
	 }
	exit 0;
	EOF
else
	${ORACLE_HOME}/bin/rman target $target nocatalog <<-EOF|tee -a $log
	run {
	backup full database skip readonly format='${repsvg}/%d_RMAN_DATABASE_FULL_%D%M%Y_BS%s_BP%p_%t' TAG='$ORACLE_SID FULL $time';
	sql "ALTER DATABASE BACKUP CONTROLFILE TO ''${repsvg}/${ORACLE_SID}_RMAN_CTRLFILE_BCK_$time'' REUSE";
	sql "ALTER DATABASE OPEN";
	}
	exit 0;
	EOF
fi	
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
     echo "Usage: $0 <ORACLE_SID>"
     echo "The parameter ORACLE_SID is missing. Exit."
     exit 1
fi

set_var_ora

time=`date "+%d%m%Y_%HH%M"`
repsvg=/oradata/${ORACLE_SID}/s01
log=/oradata/${ORACLE_SID}/s01/${ORACLE_SID}_rman_backup_database_cold_$time.log
history=/oradata/${ORACLE_SID}/adm/dbalog/${ORACLE_SID}_history.log
text="Rman Backup Database Full Cold"

if [ `uname -s` = "Linux" ]
   then
     alias echo='echo -e'
fi

if [ -w $log ]
   then
     rm $log
fi

banner "$text" Begin

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

database_test
if [ $? -eq 0 ]
   then
     shutdown_immediate
fi
database_test
if [ $? -eq 1 ]
   then
     startup mount
     rman_backup
     [ ! -z $Ora_ListenerAppName ] && start_listener $Ora_ListenerAppName
     [ ! -z $Ora_ListenerAdmName ] && start_listener $Ora_ListenerAdmName
     [ ! -z $Ora_ListenerRepName ] && start_listener $Ora_ListenerRepName
     if grep "RMAN-00569" $log 1>/dev/null 2>&1
        then
          banner "$text" End
          echo "$time\t\t$text\t\tNOK">>$history
          exit 1
        else
          banner "$text" End
          echo "$time\t\t$text\t\tOK">>$history
          exit 0
     fi
   else
     echo $msgis|tee -a $log
     [ ! -z $Ora_ListenerAppName ] && start_listener $Ora_ListenerAppName
     [ ! -z $Ora_ListenerAdmName ] && start_listener $Ora_ListenerAdmName
     [ ! -z $Ora_ListenerRepName ] && start_listener $Ora_ListenerRepName
     echo "$time\t\t$text\t\tNOK">>$history
     banner "$text" End
     exit 1
fi
