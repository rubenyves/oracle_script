#!/bin/ksh
# @(#):Version:1.4.3
#----------------------------------------------------------------------------------------------------
# Copyright(c) 2005 France Telecom Corporation. All Rights Reserved.
#
# NAME
#   rman_update_config.ksh
#
# DESCRIPTION
#   Update RMAN configuration in controlfile   
#
# REMARKS
#
#   This shell script must be executed by the owner of Oracle product (oracle)
#
#    Input Parameters : 
#          ORACLE_SID : instance name
#                 ret : retention of  RMAN backup files in days
#
#    Output : 
#          Log /oradata/<SID>/adm/dbalog/rman_update_config_<ddmmyyyy>_<hh>H<mm>.log
#
# CHANGES LOGS
#    Fabrice CHAILLOU (FT/DROSI/DPS/ISS) - 07/07/2005 - 1.0.0 - Creation
#    Fabrice CHAILLOU (FT/ROSI/DPS/ITE)  - 11/09/2006 - 1.1.0 - Modification
#                                         Evolution Oracle10g : Ajout Compression
#                                         Evolution fonction database_role
#    Fabrice CHAILLOU (FT/ROSI/DPS/ITE)  - 08/01/2007 - 1.2.0 - Modification
#                                         Evolution Oracle10g : Activation Block Change Tracking
#    Camelia BARDA    (FT/OLNC/IBNF/ITE)  - 08/10/2012 - 1.3.0 - Modification
#          English translation and Common Bundle adaptation
#    Camelia BARDA    (FT/OLNC/IBNF/ITE)  - 24/06/2014 - 1.4.0 - Modification
#          added a check to see if block change tracking is enabled. 
#          like this the script can be executed several times
#    Fabrice CHAILLOU (Orange/IMT/OLPS/IVA/VMI)  - 30/06/2014 - 1.4.1 - Modification
#    Adrian BENGA (Orange/IMT/IBNF/ITE/ITER) - 18/07/2014 - 1.4.2 - Modification - test the existance of BCT.
#                                              Don't actiavte it if it exists\
#                                              Introduced the 3 parameter files. /etc/oraconf will be sourced for 
#                                              variables setting  
#    Cristian ZAMFIRACHE (Orange/IMT/IBNF/ITE/ITER) - 11/11/2016 - 1.4.3 - Modification 
#         Changed location for SNAPSHOT CONTROLFILE
#    
#----------------------------------------------------------------------------------------------------

#----------------------------------------------------------------------------------------------------
# Activate debug mode
#----------------------------------------------------------------------------------------------------
set +x

#----------------------------------------------------------------------------------------------------
#  Display function
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
chkParfile()
{
if [[ -r $ora_paramfile && -r $ora_kernelparamfile && -r $ora_sidparamsDB ]]
then 
    return 0
elif [[ ! -r $ora_paramfile ]]
then
    echo "\n[ERROR] - PARAMETER FILE $ora_paramfile IS NOT PRESENT. - $KO \n"  | tee -a $log
    return 1
elif [[ ! -r $ora_kernelparamfile ]]
then
    echo "\n[ERROR] - PARAMETER FILE $ora_kernelparamfile IS NOT PRESENT. - $KO \n"  | tee -a $log
    return 1
elif [[ ! -r $ora_sidparamsDB ]]
then
    echo "\n[ERROR] - PARAMETER FILE $ora_sidparamsDB IS NOT PRESENT. - $KO \n"  | tee -a $log
    return 1
fi
}

#----------------------------------------------------------------------------------------------------
# Return value of execution of a SELECT
#     $1 : SQL command without select word
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
# Test presence of database
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
# Determine current role of database: PRIMARY or PHYSICAL STANDBY
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
# Update RMAN configuration
#----------------------------------------------------------------------------------------------------
rman_config()
{
blk_change=`${ORACLE_HOME}/bin/sqlplus -s "/ as sysdba" <<-EOF
			set feedback off heading off
			select count(*) from V\\$BLOCK_CHANGE_TRACKING
			where status='DISABLED';
			exit
			EOF`
if [ $blk_change = 1 ]
then
	target=/
	${ORACLE_HOME}/bin/rman target $target nocatalog <<-EOF|tee -a $log
	CONFIGURE RETENTION POLICY TO REDUNDANCY $ret;
	CONFIGURE DEFAULT DEVICE TYPE TO DISK;
	CONFIGURE DEVICE TYPE DISK PARALLELISM 1 BACKUP TYPE TO COMPRESSED BACKUPSET;
	CONFIGURE BACKUP OPTIMIZATION ON;
	CONFIGURE CONTROLFILE AUTOBACKUP ON;
	CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO '/oradata/${ORACLE_SID}/s01/${ORACLE_SID}_RMAN_CTRLFILE_AUTOBCK_%F';
	CONFIGURE DATAFILE BACKUP COPIES FOR DEVICE TYPE DISK TO 1;
	CONFIGURE ARCHIVELOG BACKUP COPIES FOR DEVICE TYPE DISK TO 1;
	CONFIGURE MAXSETSIZE TO UNLIMITED;
	CONFIGURE SNAPSHOT CONTROLFILE NAME TO '/oradata/${ORACLE_SID}/s01/snapcf${ORACLE_SID}';
	CONFIGURE CHANNEL DEVICE TYPE DISK MAXOPENFILES 4;
	SQL "ALTER DATABASE ENABLE BLOCK CHANGE TRACKING USING FILE ''/oradata/${ORACLE_SID}/u01/system/rman_bct.dbf''";
	EXIT
	EOF
else
	target=/
	${ORACLE_HOME}/bin/rman target $target nocatalog <<-EOF|tee -a $log
	CONFIGURE RETENTION POLICY TO REDUNDANCY $ret;
	CONFIGURE DEFAULT DEVICE TYPE TO DISK;
	CONFIGURE DEVICE TYPE DISK PARALLELISM 1 BACKUP TYPE TO COMPRESSED BACKUPSET;
	CONFIGURE BACKUP OPTIMIZATION ON;
	CONFIGURE CONTROLFILE AUTOBACKUP ON;
	CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO '/oradata/${ORACLE_SID}/s01/${ORACLE_SID}_RMAN_CTRLFILE_AUTOBCK_%F';
	CONFIGURE DATAFILE BACKUP COPIES FOR DEVICE TYPE DISK TO 1;
	CONFIGURE ARCHIVELOG BACKUP COPIES FOR DEVICE TYPE DISK TO 1;
	CONFIGURE MAXSETSIZE TO UNLIMITED;
	CONFIGURE SNAPSHOT CONTROLFILE NAME TO '/oradata/${ORACLE_SID}/s01/snapcf${ORACLE_SID}';
	CONFIGURE CHANNEL DEVICE TYPE DISK MAXOPENFILES 4;
	EXIT
	EOF
fi
}

#----------------------------------------------------------------------------------------------------
# Main  Program
#----------------------------------------------------------------------------------------------------

export ora_paramfile=/etc/oraconf
export ora_kernelparamfile=/etc/orakernelparams
export ora_sidparamsDB=/etc/orasidparams

# check for configuration files. if not found, exit
chkParfile

. ${ora_paramfile} > /dev/null 2>&1

ORACLE_SID=$1
if [ -z "$ORACLE_SID" ]
then
    echo "Usage: $0 {ORACLE_SID}"
    echo "The parameter ORACLE_SID is missing. Exit."
    exit 1
fi

ret=$2
case "$ret" in
   [1-9]*) ;;
        *) echo "Usage: $0 {ORACLE_SID} {RETENTION}"; echo "The parameter RETENTION POLICY is missing. Exit."; exit 1 ;;
esac

export ORACLE_HOME=$Rdbms_OracleHome
export PATH=${ORACLE_HOME}/bin:$PATH

time=`date "+%d%m%Y_%HH%M"`
log=/oradata/${ORACLE_SID}/adm/dbalog/rman_update_config_$time.log
history=/oradata/${ORACLE_SID}/adm/dbalog/${ORACLE_SID}_history.log
text="Rman Update Config                   "

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
if [ $? = 0 ]
then
    echo "The database ${ORACLE_SID} is in ${role} role."|tee -a $log
else
    echo "Cannot determine the database ${ORACLE_SID} role."|tee -a $log
    banner "$text" End
    echo "$time\t\t$text\t\tNE">>$history
    exit 1
fi
database_test
if [ $? -eq 0 ]
then
    rman_config
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
    echo "$time\t\t$text\t\tNOK">>$history
    banner "$text" End
    exit 1
fi
