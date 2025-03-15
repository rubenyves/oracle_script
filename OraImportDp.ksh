#!/bin/ksh
# @(#):Version:1.4.6
#----------------------------------------------------------------------------------------------------
# Copyright(c) 2015 Orange Corporation. All Rights Reserved.
#
# NAME
#    OraImportDp.ksh
#
# DESCRIPTION
#    Oracle Data Pump Import Tool
#            (Full or All User Schemas or Schemas or Tables)
#
# REMARKS
#
#    The script must be executed by the owner of Oracle software (or OraOsUser value)
#
#    The export file name should NOT contain the full path, but only the file name 
#    The path to the file is by default set to <ORAPATH>/<SID>/e01
#    The script accepts compressed (.gz) or uncompressed (.dmp) dumpfile
#
#    Prerequisites :
#        The Linux/AIX/Solaris Tree has to respect the Common Bundle/Platon S4D0 Standards
#        Oracle Database Enterprise Edition 10g or 11g or 12c
#
#    Input parameters: 
#        Mandatory parameters: 
#                  --sid=ORACLE_SID                         --> instance name
#                  --mode=<FULL|SCHEMAS|ALL_SCHEMAS|TABLES> --> import full or schema(s) or all schemas or table(s)
#                  --file=<dumpname>                        --> compressed (.gz) or uncompressed (.dmp) export dump file
#        Optional parameters:
#                  --parfile=<Parfile>                      --> Parameter File to use
#                  --listusers=Y                            --> List of users from a Data Pump Export
#                  --infodump=Y                             --> List infos from a Data Pump Export
#                  --listjobs=Y                             --> List of Data Pump Import Jobs in an instance
#                  --restartdb=Y                            --> Restart the DB in normal mode
#                  --killjobs=Y                             --> Kill Orphaned DataPump Import Jobs
#                  --grantall=Y                             --> Apply all grant on database from the export dump file
#                  --sequence=Y                             --> Create all sequences on schema(s) from the export dump file
#                  --disablerefconst=<Y|N>                  --> Disable referential constraints before import (default : N)
#                  --schemas=<schemalist>                   --> Schema(s) to import
#                  --tables=<tablelist>                     --> Table(s) to import
#                  --nls_lang=<lang>                        --> character set if needed
#                  --parallel=<num>|AUTO                    --> parallel (default : 1)
#                  --content=<ALL|DATA_ONLY|METADATA_ONLY>  --> Type of import
#                  --table_action=<SKIP|TRUNCATE|REPLACE>   --> Type of import on table level
#
#    Output : 
#        Script Log File - OraImportDp_<MODE>_<ddmmyyyy>_<hhHmm>.log
#        Import Log File - <SID>_<MODE>_import_<ddmmyyyy>_<hhHmm>.log
#
# CHANGES LOG:
#    Fabrice CHAILLOU (ORANGE/IMT/OLPS/IVA/IAC/EIV) - 23/03/2015 - 1.0.0
#    Fabrice CHAILLOU (ORANGE/IMT/OLPS/IVA/IAC/EIV) - 06/04/2015 - 1.0.1
#            Add Solaris compatibility
#    Fabrice CHAILLOU (ORANGE/IMT/OLPS/IVA/IAC/EIV) - 13/04/2015 - 1.1.0
#            Add grantall and disablerefconst optional parameters
#            Add informations on generated report
#    Fabrice CHAILLOU (ORANGE/IMT/OLPS/IVA/IAC/EIV) - 15/04/2015 - 1.2.0
#            Add infodump option
#            Add parallel=AUTO choice --> The degree is equal to NumCpu
#    Fabrice CHAILLOU (ORANGE/IMT/OLPS/IVA/IAC/EIV) - 04/05/2015 - 1.3.0
#            Desactivate parallelism option (not operational)
#            Add GSMADMIN_INTERNAL owner in excluding lists
#            Fix bug on import with CONTENT=DATA_ONLY
#            Add restartdb option
#            Add SID filter in control of another job running on the DB
#            Add new query on listjobs option
#            Add killjobs option to cleanup Orphaned DataPumps Import Jobs in DBA_DATAPUMP_JOBS view
#    Fabrice CHAILLOU (ORANGE/IMT/OLPS/IVA/IAC/EIV) - 05/05/2015 - 1.3.1
#            Add Oracle12c new feature : transform=disable_archive_logging:Y
#    Fabrice CHAILLOU (ORANGE/IMT/OLPS/IVA/IAC/EIV) - 11/05/2015 - 1.3.2
#            Replace gzip compress tool by pigz if available
#    Fabrice CHAILLOU (ORANGE/IMT/OLPS/IVA/IAC/EIV) - 16/05/2015 - 1.3.3
#            Improve management of errors on import control (CONTENT=DATA_ONLY)
#    Fabrice CHAILLOU (ORANGE/IMT/OLPS/IVA/IAC/EIV) - 03/08/2015 - 1.3.4
#            Fix bug on parfile mode
#    Fabrice CHAILLOU (ORANGE/IMT/OLPS/IVA/IAC/EIV) - 05/08/2015 - 1.3.5
#            Add explanations on help
#    Fabrice CHAILLOU (ORANGE/IMT/OLPS/IVA/IAC/EIV) - 19/08/2015 - 1.3.6
#            Fix bug on parfile mode in parallel mode
#    Fabrice CHAILLOU (ORANGE/IMT/OLPS/IVA/IAC/EIV) - 20/08/2015 - 1.3.7
#            Reactivate parallelism option in standard mode
#    Fabrice CHAILLOU (ORANGE/IMT/OLPS/IVA/IAC/EIV) - 28/09/2015 - 1.3.8
#            Fix minor bug on check CONTENT=DATA_ONLY and ACTION=REPLACE
#            Add content information in the name of the files (log, trace, temp, report, parfile)
#            Add begin time and end time of import in report file
#            Add parallelism option in standard mode using only one datapump export file
#            Fix bugs on Solaris (add paths to psrinfo and pigz tool)
#            Add SQLTXPLAIN and SQLTXADMIN schemas in exclude schemas list
#            Fix bugs on ALL_SCHEMAS mode (SCHEMAS empty in parfile)
#    Fabrice CHAILLOU (ORANGE/IMT/OLPS/IVA/IAC/EIV) - 28/12/2015 - 1.3.9
#            Fix minor bug on ORACLE_HOME setting (databases with the same string)
#    Fabrice CHAILLOU (ORANGE/IMT/OLS/IVA/IAC/EIV) - 16/05/2017 - 1.4.0
#            Introduce optional yaml configuration file to customize tool environment
#    Fabrice CHAILLOU (ORANGE/IMT/OLS/IVA/IAC/EIV) - 22/05/2017 - v1.4.1 - Modification
#            Add a control of the name of the instance (ora_check_instance function)
#            Introduce DirectoryName and JobNamePrefix variables
#    Fabrice CHAILLOU (ORANGE/IMT/OLS/IVA/IAC/EIV) - 23/05/2017 - v1.4.2 - Modification
#            Add sequence option (import sequences from dump to a specific schema)
#            Fix Bug on killjob option (owner_name of the job)
#            Add messages and more checks on restartdb option
# 	     Fix bug on msgis variable name
#    Fabrice CHAILLOU(ORANGE/IMT/OLS/IVA/IAC/EIV) - 26/05/2017 - v1.4.3 - Modification
#            On Killjobs option, change return code from 1 to 0 if no job to kill
#    Fabrice CHAILLOU(ORANGE/IMT/OLS/IVA/IAC/EIV) - 14/06/2017 - v1.4.4 - Modification
#            Fix minor bug on options restartdb and import with default values (warning message)
#    Fabrice CHAILLOU(ORANGE/IMT/OLS/IVA/IAC/DBEI) - 26/04/2018 - v1.4.5 - Modification
#            Fix minor bug on incorrect return code with parfile option if process successfully
#            Modify Step on Create Data Pump Directory : STEP 1 --> STEP 2
#    Fabrice CHAILLOU(ORANGE/IMT/OLS/IVA/IAC/DBEI) - 30/04/2018 - v1.4.6 - Modification
#            Fix minor bug on incorrect return code with parfile option if process successfully
#            Fix minor bug on report content in PARFILE mode (incorrect Data Pump Export File and Size data)
#----------------------------------------------------------------------------------------------------

#----------------------------------------------------------------------------------------------------
# Debug Mode
#----------------------------------------------------------------------------------------------------
set +x

# Text Color : 30=Black/Dark grey, 31=Red, 32=Green, 33=Yellow, 34=Blue, 
# 35=Magenta, 36=Cyan, 37=White/light grey, 38="Default" foreground color
# Text Attributes : 0=No, 1=Bold, 2=Normal, 4=Underlined 
COLOR_GREY="\\033[1;30m"
COLOR_RED="\\033[1;31m"
COLOR_GREEN="\\033[1;32m" 
COLOR_YELLOW="\\033[1;33m" 
COLOR_BLUE="\\033[1;34m" 
COLOR_MAGENTA="\\033[1;35m"
COLOR_CYAN="\\033[1;36m"
COLOR_WHITE="\\033[1;37m"
COLOR_DEFAULT="\\033[0;38m"

#----------------------------------------------------------------------------------------------------
# Setting oracle variables
#----------------------------------------------------------------------------------------------------
ora_set_oracle_env()
{
os=`uname -a | awk '{print $1}'`
if [ $os = 'SunOS' ]
   then
     export ORATAB=/var/opt/oracle/oratab
   else
     export ORATAB=/etc/oratab
fi
[ ! -r $ORATAB ] && echo "${COLOR_RED}\nERROR : The $ORATAB file doesn't exist or is not readable\n${COLOR_DEFAULT}" && return 1
export ORACLE_SID=${SID}
[ ! -z "${NLSLANG}" ] && export NLS_LANG=${NLSLANG}
export ORACLE_HOME=`egrep -v "^#|^$|^\s*$" $ORATAB | egrep -w ${ORACLE_SID} | awk -F: '{print $2'}`
export LD_LIBRARY_PATH=${ORACLE_HOME}/lib:/lib:/usr/lib
export PATH=${ORACLE_HOME}/bin:${PATH}
return 0
}

#---------------------------------------------------------------------------------------
# Show tool environment variables
#---------------------------------------------------------------------------------------
ora_show_tool_env()
{
echo "OraOsUser=${OraOsUser}"
echo "OraConnect=${OraConnect}"
echo "OraLogDir=${OraLogDir}"
echo "OraExpDir=${OraExpDir}"
echo "OraSqlplusPath=${OraSqlplusPath}"
echo "OraImpdpPath=${OraExpPath}"
}

#---------------------------------------------------------------------------------------
# Set tools environment
#---------------------------------------------------------------------------------------
ora_set_tool_env()
{
OraConfTools=OraToolsConfig.yml
if [ -r ${OraConfTools} ]
   then
     OraConnect=`grep -w "^OraConnect" ${OraConfTools} | awk '{print $2}'`
     OraOsUser=`grep -w "^OraOsUser" ${OraConfTools} | awk '{print $2}'`
     OraLogDir=`grep -w "^OraLogDir" ${OraConfTools} | awk '{print $2}'`
     OraExpDir=`grep -w "^OraExpDir" ${OraConfTools} | awk '{print $2}'`
     OraSqlplusPath=`grep -w "^OraSqlplusPath" ${OraConfTools} | awk '{print $2}'`
     OraImpdpPath=`grep -w "^OraImpdpPath" ${OraConfTools} | awk '{print $2}'`
   else
     echo "${OraConfTools} configuration file is not accessible. Defaults value"
fi

if [ -d /opt/oracle/na ]
   then
     OraPath=/oradata
   else
     if [ -d /exec/products/oracle ]
        then
          OraPath=/data/ora
        else
          OraPath=/tmp
     fi
fi

[ -z ${ORACLE_HOME} ] && ORACLE_HOME=ORAHOME
[ -z ${ORACLE_SID} ] && ORACLE_SID=ORASID
[ -z ${OraConnect} ] && OraConnect="/ as sysdba"
[ -z ${OraOsUser} ] && OraOsUser=oracle
export OraConnect OraOsUser OraLogDir OraExpDir OraSqlplusPath OraImpdpPath

ora_set_oracle_env

[ -z ${OraSqlplusPath} ] && OraSqlplusPath=${ORACLE_HOME}/bin/sqlplus
[ -z ${OraImpdpPath} ] && OraImpdpPath=${ORACLE_HOME}/bin/impdp
[ -z "$OraExpDir" ] && OraExpDir=${OraPath}/${ORACLE_SID}/e01                         
[ -z "$OraLogDir" ] && export OraLogDir=${OraPath}/${ORACLE_SID}/adm/dbalog          

export DirectoryName=DMPDIR  # Directory Name
export JobNamePrefix=IMPDP    # Job Name Prefix

return 0
}

#---------------------------------------------------------------------------------------
# Check Oracle User connection
#---------------------------------------------------------------------------------------
ora_check_connectivity()
{
echo "exit" | ${OraSqlplusPath} -L ${OraConnect} | grep Connected  1>/dev/null
if [ $? -eq 0 ]
then
   return 0
else
   return 1
fi
}

#---------------------------------------------------------------------------------------
# Return the value of the execution of one Select statement
#     $1 : SQL statement without the word Select
#---------------------------------------------------------------------------------------
ora_oracle_var()
{
VAR_SHELL=$1    DISTINCT=
eval $VAR_SHELL=
[ "$2" = distinct ] &&  DISTINCT=distinct && shift
SCRIPT_SQL="select $DISTINCT 'BiDoN='||$2 ;"

OutputSql=`echo "whenever sqlerror exit 1
$SCRIPT_SQL" |\
${OraSqlplusPath} -s "${OraConnect}" | grep "^BiDoN=" `

if [ $? = 0  -a  "$OutputSql" != "BiDoN=" ]
   then
     SaNsBiDoN=`echo "$OutputSql" | sed -e "s/^BiDoN=//g"`
     eval $VAR_SHELL=\$SaNsBiDoN
     return 0
   else
     echo "\n\nSCRIPT_SQL=$SCRIPT_SQL"
     echo "$SCRIPT_SQL" | ${OraSqlplusPath} -s "${OraConnect}"
     return 1
fi
}

#---------------------------------------------------------------------------------------
# Check the name of the instance
#---------------------------------------------------------------------------------------
ora_check_instance()
{
ora_oracle_var instance "instance_name from v\$instance"
if [ "${instance}" = "${SID}" ]
   then
     return 0
   else
     echo "${COLOR_RED}\nERROR - The instance name ${instance} is different than ${SID}. Change the OraConnect=$OraConnect value.\n${COLOR_DEFAULT}"
     return 1
fi
}

#----------------------------------------------------------------------------------------------------
# Setting linux variables
#----------------------------------------------------------------------------------------------------
ora_set_unix_env()
{
umask 022
export LANG=C
Time=`date "+%d%m%Y_%HH%M"`                                                             # Time
Text="Data Pump Import  Mode: $MODE     "
export ScriptName=`basename $0 | cut -d. -f1`                                           # Script File Name
export TmpDir=/tmp                                                                      # Tmp Directory

export Parfile=${OraExpDir}/${ORACLE_SID}_${MODE}_${CONTENT}_importdp_${Time}.par       # Parameter File Name
export LogFile=${OraLogDir}/${ScriptName}_${MODE}_${CONTENT}_${Time}.log                # Script Log File Name
export TraceFile=${OraExpDir}/${ORACLE_SID}_${MODE}_${CONTENT}_importdp_${Time}.log    # Import Log File Name
export ReportFile=${OraExpDir}/${ORACLE_SID}_${MODE}_${CONTENT}_importdp_${Time}.rep   # Report Log File Name
export HistoryFile=${OraLogDir}/${ORACLE_SID}_history.log                               # History File Name
export TmpFile=${TmpDir}/${ORACLE_SID}_${MODE}_${CONTENT}_importdp_${Time}.tmp          # Temporary File Name
export FlagFile=${TmpDir}/${ORACLE_SID}_restrictmode.flag                               # Restrict Mode Flag
export SqlDisFile=${TmpDir}/${ORACLE_SID}_importdp_DisableRefConstraints_${Time}.sql    # SQL File
export SqlDisLogFile=${TmpDir}/${ORACLE_SID}_importdp_DisableRefConstraints_${Time}.log # SQL log File
export SqlEnaFile=${TmpDir}/${ORACLE_SID}_importdp_EnableRefConstrainsts_${Time}.sql    # SQL File
export SqlEnaLogFile=${TmpDir}/${ORACLE_SID}_importdp_EnableRefConstraints_${Time}.log  # SQL log File

}

#----------------------------------------------------------------------------------------------------
# Display function
#----------------------------------------------------------------------------------------------------
ora_banner()
{
Timeb=`date +"%d/%m/%Y %HH%M"`
echo "${COLOR_BLUE}---------------------------------------------------------------------------------------------------------${COLOR_DEFAULT}"|tee -a ${LogFile}
echo "${COLOR_WHITE}  $1\t\tDatabase: ${ORACLE_SID}\t\t$2:\t${Timeb}${COLOR_DEFAULT}"|tee -a ${LogFile}
echo "${COLOR_BLUE}---------------------------------------------------------------------------------------------------------${COLOR_DEFAULT}"|tee -a ${LogFile}
}

#---------------------------------------------------------------------------------------
# Check the status of the instance
#---------------------------------------------------------------------------------------
ora_instance_status()
{
CD=`${OraSqlplusPath} -s /nolog<<-ENDOIS
connect ${OraConnect}
set head off
select open_mode from v\\$database;
exit
ENDOIS`
istatus=`echo "$CD"|egrep "^ORA-|READ|MOUNTED"`
case "$istatus" in
     'READ ONLY') MsgIs="The database ${ORACLE_SID} is read only opened." ; return 1;;
     'READ WRITE')MsgIs="The database ${ORACLE_SID} is read write opened."; return 0;;
     'MOUNTED') MsgIs="The database ${ORACLE_SID} is mounted (not opened).";return 1;;
     *ORA-01507*) MsgIs="The database ${ORACLE_SID} is not mounted." ; return 1;;
     *ORA-01034*) MsgIs="The database ${ORACLE_SID} is not available." ; return 1;;
     *ORA-01090*) MsgIs="Shutdown in progress on database ${ORACLE_SID}." ; return 1;;
     *       )    MsgIs=$istatus ; return 1;;
esac
return 0
}

#----------------------------------------------------------------------------------------------------
# Show usage
#----------------------------------------------------------------------------------------------------
show_usage()
{
  echo ${COLOR_BLUE}
  echo "* List DataPump Import Jobs running in the Oracle Instance <ORACLE_SID>"
  echo ${COLOR_GREEN}
  echo "Usage: $0 --sid=<ORACLE_SID> --listjobs=Y"
  echo ${COLOR_BLUE}
  echo "* Restart the Oracle Instance <ORACLE_SID> in normal mode (read write opened)"
  echo ${COLOR_GREEN}
  echo "Usage: $0 --sid=<ORACLE_SID> --restartdb=Y"
  echo ${COLOR_BLUE}
  echo "* Kill DataPump Import Jobs running in the Oracle Instance <ORACLE_SID>"
  echo ${COLOR_GREEN}
  echo "Usage: $0 --sid=<ORACLE_SID> --killjobs=Y"
  echo ${COLOR_BLUE}
  echo "* List schemas from a DataPump Export File"
  echo ${COLOR_GREEN}
  echo "Usage: $0 --sid=<ORACLE_SID> --listusers=Y --file=<exportdumpfile>"
  echo ${COLOR_BLUE}
  echo "* Obtain details from a DataPump Export File"
  echo ${COLOR_GREEN}
  echo "Usage: $0 --sid=<ORACLE_SID> --infodump=Y --file=<exportdumpfile>"
  echo ${COLOR_BLUE}
  echo "* Apply all grant on the oracle database <ORACLE_SID> from a DataPump Export File"
  echo ${COLOR_GREEN}
  echo "Usage: $0 --sid=<ORACLE_SID> --grantall=Y --file=<exportdumpfile>"
  echo ${COLOR_BLUE}
  echo "* Create all sequences into specified schema(s) of the oracle database <ORACLE_SID> from a DataPump Export File"
  echo ${COLOR_GREEN}
  echo "Usage: $0 --sid=<ORACLE_SID> --sequence=Y --schemas=<schemalist> --file=<exportdumpfile>"
  echo ${COLOR_BLUE}
  echo "* Import in a specific mode (full, list of schemas, list of tables) DataPump Export File into the oracle database <ORACLE_SID>"
  echo ${COLOR_GREEN}
  echo "Usage: $0 --sid=<ORACLE_SID> --mode=<FULL|SCHEMAS|ALL_SCHEMAS|TABLES> --file=<exportdumpfile> [parameter=value, ...]"
  echo ${COLOR_BLUE}
  echo "Parameter             Description                                            Required Default"
  echo "-------------------   ------------------------------------------------------ -------- --------"
  echo "--sid                 Instance Name : ORACLE_SID                             Yes"
  echo "--mode                Import Mode : FULL or SCHEMAS or ALL_SCHEMAS or TABLES Yes"
  echo "--file                Data Pump Export Dump (.gz or .dmp)                    Yes"
  echo "--schemas             Schema(s) List to import (Import Mode = SCHEMAS)       No"
  echo "--tables              Table(s) List to import (Import Mode = TABLES)         No"
  echo "--nls_lang            NLS_LANG : WE8ISO8859P15 or ALE32UTF8                  No       n/a"
  echo "--parallel            Parallel (1 to 8 or AUTO)                              No       1"
  echo "--content             Import Content : DATA_ONLY or METADATA_ONLY or ALL     No       ALL"
  echo "--table_action        Import Table Action : SKIP or REPLACE or TRUNCATE      No       REPLACE"
  echo "--disablerefconst     Disable referential constraints before import          No       N"
  echo ${COLOR_BLUE}
  echo "* DataPump Import using a parfile (custom import)"
  echo ${COLOR_GREEN}
  echo "Usage: $0 --sid=<ORACLE_SID> --parfile=<Parfile>"
  echo ${COLOR_BLUE}
  echo "Parfile Only : Tablespace Mode,  Transportable Tablespace Mode, Network Import, Data Filters, MetaData Filters, RAC Architecture"
  echo "               Encrypted Export Dump File, Data Options, Remap Objects (Data, Datafile, Schema, Table, Tablespace), Transform Rules"
  echo ${COLOR_DEFAULT}
  echo "Examples : $0 --sid=PWSAABU --mode=SCHEMAS --schemas=OPAPY --file=PWSAABU_full_export_20150324_23H40.dmp.gz"
  echo "           $0 --sid=PWSAABU --mode=SCHEMAS --schemas=OPAPY,OPAPYFR --file=PWSAABU_full_export_20150324_23H40.dmp.gz"
  echo
  echo "           $0 --sid=PWSAABU --mode=TABLES --tables=OPAPY.BU --file=PWSAABU_full_export_20150324_23H40.dmp.gz"
  echo "           $0 --sid=PWSAABU --mode=TABLES --tables=OPAPY.BU,OPAPY.OFFERS --file=PWSAABU_full_export_20150324_23H40.dmp.gz"
  echo
  echo "           $0 --sid=PWSAABU --mode=FULL --file=PWSAABU_full_export_%U_20150324_23H40.dmp --parallel=2"
  echo
  echo "           $0 --sid=PWSAABU --parfile=/oradata/PWSAABU/e01/PWSAABU_importdp_31032015_10H31.par"
  echo
  echo "           $0 --sid=PWSAABU --listjobs=Y"
  echo "           $0 --sid=PWSAABU --killjobs=Y"
  echo "           $0 --sid=PWSAABU --restartdb=Y"
  echo "           $0 --sid=PWSAABU --listusers=Y --file=PWSAABU_full_export_20150324_23H40.dmp.gz"
  echo "           $0 --sid=PWSAABU --infodump=Y --file=PWSAABU_full_export_20150324_23H40.dmp.gz"
  echo "           $0 --sid=PWSAABU --grantall=Y --file=PWSAABU_full_export_20150324_23H40.dmp.gz"
  echo "           $0 --sid=PWSAABU --sequence=Y --schemas=OPAPYFR --file=PWSAABU_full_export_20150324_23H40.dmp.gz"
  echo
}

#----------------------------------------------------------------------------------------------------
# Shutdown immediate
#----------------------------------------------------------------------------------------------------
ora_shutdown_db()
{
echo "${COLOR_WHITE}\nSTEP -" `date "+%d.%m.%Y %H:%M:%S"` "- Shutdown immediate via SQL*Plus ${COLOR_DEFAULT}" | tee -a $LogFile
${OraSqlplusPath} -S "${OraConnect}" <<-ENDSI 1>>$LogFile 2>&1
WHENEVER SQLERROR EXIT FAILURE ROLLBACK
SET FEED OFF
SHUTDOWN IMMEDIATE
EXIT 0
ENDSI
return $?
}

#----------------------------------------------------------------------------------------------------
# Startup normal
#----------------------------------------------------------------------------------------------------
ora_startup_db()
{
echo "${COLOR_WHITE}\nSTEP -" `date "+%d.%m.%Y %H:%M:%S"` "- Startup normal via SQL*Plus ${COLOR_DEFAULT}" | tee -a $LogFile
${OraSqlplusPath} -S "${OraConnect}" <<-ENDSN 1>>$LogFile 2>&1
WHENEVER SQLERROR EXIT FAILURE ROLLBACK
SET FEED OFF
STARTUP 
EXIT 0
ENDSN
return $?
}

#----------------------------------------------------------------------------------------------------
# Startup in restrict mode
#----------------------------------------------------------------------------------------------------
ora_startup_restrict_db()
{
echo "${COLOR_WHITE}\nSTEP -" `date "+%d.%m.%Y %H:%M:%S"` "- Startup restrict quiet via SQL*Plus ${COLOR_DEFAULT}" | tee -a $LogFile
${OraSqlplusPath} -S "${OraConnect}" <<-ENDSR >>$LogFile 2>&1
WHENEVER SQLERROR EXIT FAILURE ROLLBACK
SET FEED OFF
STARTUP RESTRICT QUIET
EXIT 0
ENDSR
return $?
}
#ALTER SYSTEM SET STREAMS_POOL_SIZE=20M SCOPE=MEMORY;

#----------------------------------------------------------------------------------------------------
# List of Users in Datapump File
#----------------------------------------------------------------------------------------------------
ora_list_users_dp()
{
Suffix=`ls $DmpFile | awk -F. '{print $3}'`
if [ "$Suffix" = "gz" ]
    then
      echo "${COLOR_WHITE}\nSTEP -" `date "+%d.%m.%Y %H:%M:%S"` "- Uncompressing the Data Pump Export File (using $UnCompressTool Tool) ...${COLOR_DEFAULT}"
      $UnCompressCmd $DmpFile 
      UnzippedDmpFile=${DmpFile%.gz}
      ShortNameDmpFile=`basename $UnzippedDmpFile`
      FlagGz=Y
    else
      ShortNameDmpFile=`basename $DmpFile`
      FlagGz=N
fi

ora_instance_status
if [ $? -eq 0 ]
   then
      echo "${COLOR_WHITE}\nSTEP -" `date "+%d.%m.%Y %H:%M:%S"` "- Creating the Data Pump Directory $OraExpDir ...${COLOR_DEFAULT}"
${OraSqlplusPath} -s "${OraConnect}" <<ENDCD 1>/dev/null 2>&1
WHENEVER SQLERROR EXIT 1;
CREATE OR REPLACE DIRECTORY ${DirectoryName} AS '$OraExpDir';
EXIT
ENDCD
     if [ $? != 0 ]
        then
          echo "${COLOR_RED}\nERROR : The Directory ${DirectoryName}=$OraExpDir is not created.${COLOR_DEFAULT}"
          return 1
     fi
   else
     echo "${COLOR_RED}\nERROR : ${MsgIs}${COLOR_DEFAULT}"
     return 1
fi

cat >$Parfile <<ENDLU
DIRECTORY=${DirectoryName}
DUMPFILE=$ShortNameDmpFile
LOGFILE=ListUsers.log
SQLFILE=ListUsers.sql
FULL=Y
INCLUDE=USER
ENDLU

echo "${COLOR_WHITE}\nSTEP -" `date "+%d.%m.%Y %H:%M:%S"` "- Importing the Data Pump Export FULL=Y INCLUDE=USER ...${COLOR_DEFAULT}"
${OraImpdpPath} \"${OraConnect}\" parfile=$Parfile 1>$TmpFile 2>&1

if egrep "ORA-|LRM-" $TmpFile 1>/dev/null 2>&1
   then
     # Import KO - Error in Parameter File
     echo "${COLOR_RED}\nERROR : Data Pump Import terminated with errors.\n${COLOR_DEFAULT}"
     egrep "ORA-|LRM-" $TmpFile | sort -u
     echo 
     RC=1
   else
     echo "${COLOR_GREEN}\nINFO  : List of Users in the Data Pump Export File\n${COLOR_DEFAULT}"
     grep -i 'CREATE USER ' $OraExpDir/ListUsers.sql | awk -F"\"" '{ print $2 }' | sort -u
     echo
     RC=0
fi

rm -f $OraExpDir/ListUsers.sql $OraExpDir/ListUsers.log $TmpFile 1>/dev/null 2>&1

if [ "$FlagGz" = "Y" ] 
   then
     echo "${COLOR_WHITE}\nSTEP -" `date "+%d.%m.%Y %H:%M:%S"` "- Compressing the Data Pump Export File (using $CompressTool Tool) ...\n${COLOR_DEFAULT}"
     $CompressCmd $UnzippedDmpFile 1>/dev/null 2>&1
fi

return $RC
}

#----------------------------------------------------------------------------------------------------
# List dump info from a Data Pump Export
#----------------------------------------------------------------------------------------------------
ora_infodump_dp()
{
Suffix=`ls $DmpFile | awk -F. '{print $3}'`
if [ "$Suffix" = "gz" ]
    then
      echo "${COLOR_WHITE}\nSTEP -" `date "+%d.%m.%Y %H:%M:%S"` "- Uncompressing the Data Pump Export File (using $UnCompressTool Tool) ...${COLOR_DEFAULT}"
      $UnCompressCmd $DmpFile
      UnzippedDmpFile=${DmpFile%.gz}
      ShortNameDmpFile=`basename $UnzippedDmpFile`
      FlagGz=Y
    else
      ShortNameDmpFile=`basename $DmpFile`
      FlagGz=N
fi

ora_instance_status
if [ $? -eq 0 ]
   then
      echo "${COLOR_WHITE}\nSTEP -" `date "+%d.%m.%Y %H:%M:%S"` "- Creating the Data Pump Directory $OraExpDir ...\n${COLOR_DEFAULT}"
${OraSqlplusPath} -s "${OraConnect}" <<ENDCD 1>/dev/null 2>&1
WHENEVER SQLERROR EXIT 1;
CREATE OR REPLACE DIRECTORY ${DirectoryName} AS '$OraExpDir';
EXIT
ENDCD
     if [ $? != 0 ]
        then
          echo "${COLOR_RED}ERROR : The Directory ${DirectoryName}=$OraExpDir is not created.${COLOR_DEFAULT}"
          return 1
     fi
   else
     echo "${COLOR_RED}ERROR : ${MsgIs}${COLOR_DEFAULT}"
     return 1
fi

${OraSqlplusPath} -s "${OraConnect}" <<ENDCP 1>/dev/null 2>&1
CREATE OR REPLACE PROCEDURE show_dumpfile_info(
  p_dir  VARCHAR2 DEFAULT 'DATA_PUMP_DIR',
  p_file VARCHAR2 DEFAULT 'EXPDAT.DMP')
AS
-- p_dir        = directory object where dump file can be found
-- p_file       = simple filename of export dump file (case-sensitive)
  v_separator   VARCHAR2(80) := '--------------------------------------' ||
                                '--------------------------------------';
  v_path        all_directories.directory_path%type := '?';
  v_filetype    NUMBER;                 -- 0=unknown 1=expdp 2=exp 3=ext
  v_fileversion VARCHAR2(15);           -- 0.1=10gR1 1.1=10gR2 (etc.)
  v_info_table  sys.ku\$_dumpfile_info;  -- PL/SQL table with file info
  type valtype  IS VARRAY(23) OF VARCHAR2(2048);
  var_values    valtype := valtype();
  no_file_found EXCEPTION;
  PRAGMA        exception_init(no_file_found, -39211);

BEGIN

-- Dump file details:
-- ==================
-- For Oracle10g Release 2 and higher:
--    dbms_datapump.KU$_DFHDR_FILE_VERSION        CONSTANT NUMBER := 1;
--    dbms_datapump.KU$_DFHDR_MASTER_PRESENT      CONSTANT NUMBER := 2;
--    dbms_datapump.KU$_DFHDR_GUID                CONSTANT NUMBER := 3;
--    dbms_datapump.KU$_DFHDR_FILE_NUMBER         CONSTANT NUMBER := 4;
--    dbms_datapump.KU$_DFHDR_CHARSET_ID          CONSTANT NUMBER := 5;
--    dbms_datapump.KU$_DFHDR_CREATION_DATE       CONSTANT NUMBER := 6;
--    dbms_datapump.KU$_DFHDR_FLAGS               CONSTANT NUMBER := 7;
--    dbms_datapump.KU$_DFHDR_JOB_NAME            CONSTANT NUMBER := 8;
--    dbms_datapump.KU$_DFHDR_PLATFORM            CONSTANT NUMBER := 9;
--    dbms_datapump.KU$_DFHDR_INSTANCE            CONSTANT NUMBER := 10;
--    dbms_datapump.KU$_DFHDR_LANGUAGE            CONSTANT NUMBER := 11;
--    dbms_datapump.KU$_DFHDR_BLOCKSIZE           CONSTANT NUMBER := 12;
--    dbms_datapump.KU$_DFHDR_DIRPATH             CONSTANT NUMBER := 13;
--    dbms_datapump.KU$_DFHDR_METADATA_COMPRESSED CONSTANT NUMBER := 14;
--    dbms_datapump.KU$_DFHDR_DB_VERSION          CONSTANT NUMBER := 15;
-- For Oracle11gR1:
--    dbms_datapump.KU$_DFHDR_MASTER_PIECE_COUNT  CONSTANT NUMBER := 16;
--    dbms_datapump.KU$_DFHDR_MASTER_PIECE_NUMBER CONSTANT NUMBER := 17;
--    dbms_datapump.KU$_DFHDR_DATA_COMPRESSED     CONSTANT NUMBER := 18;
--    dbms_datapump.KU$_DFHDR_METADATA_ENCRYPTED  CONSTANT NUMBER := 19;
--    dbms_datapump.KU$_DFHDR_DATA_ENCRYPTED      CONSTANT NUMBER := 20;
-- For Oracle11gR2:
--    dbms_datapump.KU$_DFHDR_COLUMNS_ENCRYPTED   CONSTANT NUMBER := 21;
--    dbms_datapump.KU$_DFHDR_ENCRIPTION_MODE     CONSTANT NUMBER := 22;
-- For Oracle12cR1:
--    dbms_datapump.KU$_DFHDR_COMPRESSION_ALG     CONSTANT NUMBER := 23;

-- For Oracle10gR2: KU$_DFHDR_MAX_ITEM_CODE       CONSTANT NUMBER := 15;
-- For Oracle11gR1: KU$_DFHDR_MAX_ITEM_CODE       CONSTANT NUMBER := 20;
-- For Oracle11gR2: KU$_DFHDR_MAX_ITEM_CODE       CONSTANT NUMBER := 22;
-- For Oracle12cR1: KU$_DFHDR_MAX_ITEM_CODE       CONSTANT NUMBER := 23;

-- Show header output info:
-- ========================

  dbms_output.put_line(v_separator);
  dbms_output.put_line('Purpose..: Obtain details about Export ' ||
        'Dumpfile        Version: 18-DEC-2013');
  dbms_output.put_line('Required.: RDBMS version: 10.2.0.1.0 or higher');
  dbms_output.put_line('.          ' ||
        'Export dumpfile version: 7.3.4.0.0 or higher');
  dbms_output.put_line('.          ' ||
        'Export Data Pump dumpfile version: 10.1.0.1.0 or higher');
  dbms_output.put_line('Usage....: ' ||
        'execute show_dumpfile_info(''DIRECTORY'', ''DUMPFILE'');');
  dbms_output.put_line('Example..: ' ||
        'exec show_dumpfile_info(''DUMPDIR'', ''exportdp.dmp'');');
  dbms_output.put_line(v_separator);
  dbms_output.put_line('Filename.: ' || p_file);
  dbms_output.put_line('Directory: ' || p_dir);

-- Retrieve Export dumpfile details:
-- =================================

  SELECT directory_path INTO v_path FROM all_directories
   WHERE directory_name = p_dir
      OR directory_name = UPPER(p_dir);

  dbms_datapump.get_dumpfile_info(
           filename   => p_file,       directory => UPPER(p_dir),
           info_table => v_info_table, filetype  => v_filetype);

  var_values.EXTEND(23);
  FOR i in 1 .. 23 LOOP
    BEGIN
      SELECT value INTO var_values(i) FROM TABLE(v_info_table)
       WHERE item_code = i;
    EXCEPTION WHEN OTHERS THEN var_values(i) := '';
    END;
  END LOOP;

  dbms_output.put_line('Disk Path: ' || v_path);

  IF v_filetype >= 1 THEN
    -- Get characterset name:
    BEGIN
      SELECT var_values(5) || ' (' || nls_charset_name(var_values(5)) ||
        ')' INTO var_values(5) FROM dual;
    EXCEPTION WHEN OTHERS THEN null;
    END;
    IF v_filetype = 2 THEN
      dbms_output.put_line(
         'Filetype.: ' || v_filetype || ' (Original Export dumpfile)');
      dbms_output.put_line(v_separator);
      SELECT DECODE(var_values(13), '0', '0 (Conventional Path)',
        '1', '1 (Direct Path)', var_values(13))
        INTO var_values(13) FROM dual;
      dbms_output.put_line('...Characterset ID of source db..: ' || var_values(5));
      dbms_output.put_line('...Direct Path Export Mode.......: ' || var_values(13));
      dbms_output.put_line('...Export Version................: ' || var_values(15));
    ELSIF v_filetype = 1 OR v_filetype = 3 THEN
      SELECT SUBSTR(var_values(1), 1, 15) INTO v_fileversion FROM dual;
      SELECT DECODE(var_values(1),
                    '0.1', '0.1 (Oracle10g Release 1: 10.1.0.x)',
                    '1.1', '1.1 (Oracle10g Release 2: 10.2.0.x)',
                    '2.1', '2.1 (Oracle11g Release 1: 11.1.0.x)',
                    '3.1', '3.1 (Oracle11g Release 2: 11.2.0.x)',
                    '4.1', '4.1 (Oracle12c Release 1: 12.1.0.x)',
                    '4.2', '4.2 (Oracle12c Release 2: 12.2.0.x)',
        var_values(1)) INTO var_values(1) FROM dual;
      SELECT DECODE(var_values(2), '0', '0 (No)', '1', '1 (Yes)',
        var_values(2)) INTO var_values(2) FROM dual;
      SELECT DECODE(var_values(14), '0', '0 (No)', '1', '1 (Yes)',
        var_values(14)) INTO var_values(14) FROM dual;
      SELECT DECODE(var_values(18), '0', '0 (No)', '1', '1 (Yes)',
        var_values(18)) INTO var_values(18) FROM dual;
      SELECT DECODE(var_values(19), '0', '0 (No)', '1', '1 (Yes)',
        var_values(19)) INTO var_values(19) FROM dual;
      SELECT DECODE(var_values(20), '0', '0 (No)', '1', '1 (Yes)',
        var_values(20)) INTO var_values(20) FROM dual;
      SELECT DECODE(var_values(21), '0', '0 (No)', '1', '1 (Yes)',
        var_values(21)) INTO var_values(21) FROM dual;
      SELECT DECODE(var_values(22),
                    '1', '1 (Unknown)',
                    '2', '2 (None)',
                    '3', '3 (Password)',
                    '4', '4 (Password and Wallet)',
                    '5', '5 (Wallet)',
        var_values(22)) INTO var_values(22) FROM dual;
      SELECT DECODE(var_values(23),
                    '2', '2 (None)',
                    '3', '3 (Basic)',
                    '4', '4 (Low)',
                    '5', '5 (Medium)',
                    '6', '6 (High)',
        var_values(23)) INTO var_values(23) FROM dual;
      IF v_filetype = 1 THEN
        dbms_output.put_line(
           'Filetype.: ' || v_filetype || ' (Export Data Pump dumpfile)');
        dbms_output.put_line(v_separator);
        dbms_output.put_line('...Database Job Version..........: ' || var_values(15));
        dbms_output.put_line('...Internal Dump File Version....: ' || var_values(1));
        dbms_output.put_line('...Creation Date.................: ' || var_values(6));
        dbms_output.put_line('...File Number (in dump file set): ' || var_values(4));
        dbms_output.put_line('...Master Present in dump file...: ' || var_values(2));
        IF dbms_datapump.KU\$_DFHDR_MAX_ITEM_CODE > 15 AND v_fileversion >= '2.1' THEN
          dbms_output.put_line('...Master in how many dump files.: ' || var_values(16));
          dbms_output.put_line('...Master Piece Number in file...: ' || var_values(17));
        END IF;
        dbms_output.put_line('...Operating System of source db.: ' || var_values(9));
        IF v_fileversion >= '2.1' THEN
          dbms_output.put_line('...Instance Name of source db....: ' || var_values(10));
        END IF;
        dbms_output.put_line('...Characterset ID of source db..: ' || var_values(5));
        dbms_output.put_line('...Language Name of characterset.: ' || var_values(11));
        dbms_output.put_line('...Job Name......................: ' || var_values(8));
        dbms_output.put_line('...GUID (unique job identifier)..: ' || var_values(3));
        dbms_output.put_line('...Block size dump file (bytes)..: ' || var_values(12));
        dbms_output.put_line('...Metadata Compressed...........: ' || var_values(14));
        IF dbms_datapump.KU\$_DFHDR_MAX_ITEM_CODE > 15 THEN
          dbms_output.put_line('...Data Compressed...............: ' || var_values(18));
          IF dbms_datapump.KU\$_DFHDR_MAX_ITEM_CODE > 22 AND v_fileversion >= '4.1' THEN
            dbms_output.put_line('...Compression Algorithm.........: ' || var_values(23));
          END IF;
          dbms_output.put_line('...Metadata Encrypted............: ' || var_values(19));
          dbms_output.put_line('...Table Data Encrypted..........: ' || var_values(20));
          dbms_output.put_line('...Column Data Encrypted.........: ' || var_values(21));
          dbms_output.put_line('...Encryption Mode...............: ' || var_values(22));
        END IF;
      ELSE
        dbms_output.put_line(
           'Filetype.: ' || v_filetype || ' (External Table dumpfile)');
        dbms_output.put_line(v_separator);
        dbms_output.put_line('...Database Job Version..........: ' || var_values(15));
        dbms_output.put_line('...Internal Dump File Version....: ' || var_values(1));
        dbms_output.put_line('...Creation Date.................: ' || var_values(6));
        dbms_output.put_line('...File Number (in dump file set): ' || var_values(4));
        dbms_output.put_line('...Operating System of source db.: ' || var_values(9));
        IF v_fileversion >= '2.1' THEN
          dbms_output.put_line('...Instance Name of source db....: ' || var_values(10));
        END IF;
        dbms_output.put_line('...Characterset ID of source db..: ' || var_values(5));
        dbms_output.put_line('...Language Name of characterset.: ' || var_values(11));
        dbms_output.put_line('...GUID (unique job identifier)..: ' || var_values(3));
        dbms_output.put_line('...Block size dump file (bytes)..: ' || var_values(12));
        IF dbms_datapump.KU\$_DFHDR_MAX_ITEM_CODE > 15 THEN
          dbms_output.put_line('...Data Compressed...............: ' || var_values(18));
          IF dbms_datapump.KU\$_DFHDR_MAX_ITEM_CODE > 22 AND v_fileversion >= '4.1' THEN
            dbms_output.put_line('...Compression Algorithm.........: ' || var_values(23));
          END IF;
          dbms_output.put_line('...Table Data Encrypted..........: ' || var_values(20));
          dbms_output.put_line('...Encryption Mode...............: ' || var_values(22));
        END IF;
      END IF;
      dbms_output.put_line('...Internal Flag Values..........: ' || var_values(7));
      dbms_output.put_line('...Max Items Code (Info Items)...: ' ||
                  dbms_datapump.KU\$_DFHDR_MAX_ITEM_CODE);
    END IF;
  ELSE
    dbms_output.put_line('Filetype.: ' || v_filetype);
    dbms_output.put_line(v_separator);
    dbms_output.put_line('ERROR....: Not an export dumpfile.');
  END IF;
  dbms_output.put_line(v_separator);

EXCEPTION
  WHEN no_data_found THEN
    dbms_output.put_line('Disk Path: ?');
    dbms_output.put_line('Filetype.: ?');
    dbms_output.put_line(v_separator);
    dbms_output.put_line('ERROR....: Directory Object does not exist.');
    dbms_output.put_line(v_separator);
  WHEN no_file_found THEN
    dbms_output.put_line('Disk Path: ' || v_path);
    dbms_output.put_line('Filetype.: ?');
    dbms_output.put_line(v_separator);
    dbms_output.put_line('ERROR....: File does not exist.');
    dbms_output.put_line(v_separator);
END;
/
ENDCP

${OraSqlplusPath} -s "${OraConnect}" <<ENDEP
WHENEVER SQLERROR EXIT 1
SET SERVEROUTPUT ON SIZE 1000000   
EXEC show_dumpfile_info(p_dir=> '${DirectoryName}', p_file=> '$ShortNameDmpFile')  
EXIT 0
ENDEP
RC=$?

if [ "$FlagGz" = "Y" ]
   then
     echo "${COLOR_WHITE}\nSTEP -" `date "+%d.%m.%Y %H:%M:%S"` "- Compressing the Data Pump Export File (using $CompressTool Tool) ...\n${COLOR_DEFAULT}"
     $CompressCmd $UnzippedDmpFile 1>/dev/null 2>&1
fi

return $RC
}

#----------------------------------------------------------------------------------------------------
# Apply all Grant from Export Dump File or Create akl sequences into schema(s) from Export Dump File
#----------------------------------------------------------------------------------------------------
ora_oper_all_dp()
{
local Oper=$1
[ "${Oper}" != "grant" -a  "${Oper}" != "sequence" ] && return 1

ShortTraceFileName=`basename $TraceFile`
Suffix=`ls $DmpFile | awk -F. '{print $3}'`
if [ "$Suffix" = "gz" ]
    then
      echo "${COLOR_WHITE}\nSTEP -" `date "+%d.%m.%Y %H:%M:%S"` "- Uncompressing the Data Pump Export File (using $UnCompressTool Tool) ...${COLOR_DEFAULT}"
      $UnCompressCmd $DmpFile 1>/dev/null 2>&1
      UnzippedDmpFile=${DmpFile%.gz}
      ShortNameDmpFile=`basename $UnzippedDmpFile`
      FlagGz=Y
    else
      ShortNameDmpFile=`basename $DmpFile`
      FlagGz=N
fi

ora_instance_status
if [ $? -eq 0 ]
   then
      echo "${COLOR_WHITE}\nSTEP -" `date "+%d.%m.%Y %H:%M:%S"` "- Creating the Data Pump Directory $OraExpDir ...${COLOR_DEFAULT}"
${OraSqlplusPath} -s "${OraConnect}" <<ENDCD 1>/dev/null 2>&1
WHENEVER SQLERROR EXIT 1;
CREATE OR REPLACE DIRECTORY ${DirectoryName} AS '$OraExpDir';
EXIT
ENDCD
     if [ $? != 0 ]
        then
          echo "${COLOR_RED}\nERROR : The Directory ${DirectoryName}=$OraExpDir is not created.${COLOR_DEFAULT}"
          return 1
     fi
   else
     echo "${COLOR_RED}\nERROR : ${MsgIs}${COLOR_DEFAULT}"
     return 1
fi

if [ "$Oper" = "grant" ]
then
cat >$Parfile <<ENDOA
DIRECTORY=${DirectoryName}
DUMPFILE=$ShortNameDmpFile
LOGFILE=$ShortTraceFileName
FULL=Y
INCLUDE=GRANT
ENDOA
fi

if [ "$Oper" = "sequence" ]
then
cat >$Parfile <<ENDOA
DIRECTORY=${DirectoryName}
DUMPFILE=$ShortNameDmpFile
LOGFILE=$ShortTraceFileName
SCHEMAS=$SCHEMALIST
INCLUDE=SEQUENCE
ENDOA
fi

echo "${COLOR_WHITE}\nSTEP -" `date "+%d.%m.%Y %H:%M:%S"` "- Importing the Data Pump Export FULL=Y INCLUDE=${Oper} ...${COLOR_DEFAULT}"
echo "\nDatapump Import Cmd : ${OraImpdpPath} user/password parfile=$Parfile\n"
${OraImpdpPath} \"${OraConnect}\" parfile=$Parfile 1>$TmpFile 2>&1

if egrep "ORA-|LRM-" $TmpFile 1>/dev/null 2>&1
   then
     # Import KO - Error in Parameter File
     echo "${COLOR_RED}\nERROR : Data Pump Import terminated with errors.${COLOR_DEFAULT}"
     echo "${COLOR_RED}\nERROR  : Read $TraceFile file for more details.\n${COLOR_DEFAULT}"
     egrep "ORA-|LRM-" $TmpFile | sort -u
     echo
     RC=1
   else
     echo "${COLOR_GREEN}\nINFO  : Data Pump Import terminated successfully without errors.${COLOR_DEFAULT}"
     echo "${COLOR_GREEN}\nINFO  : Read $TraceFile file for more details.\n${COLOR_DEFAULT}"
     RC=0
fi

rm -f $TmpFile 1>/dev/null 2>&1

if [ "$FlagGz" = "Y" ]
   then
     echo "${COLOR_WHITE}\nSTEP -" `date "+%d.%m.%Y %H:%M:%S"` "- Compressing the Data Pump Export File (using $CompressTool Tool) ...\n${COLOR_DEFAULT}"
     $CompressCmd $UnzippedDmpFile 1>/dev/null 2>&1
fi

return $RC
}

#----------------------------------------------------------------------------------------------------
# Create Data Pump Directory
#----------------------------------------------------------------------------------------------------
ora_create_dir()
{
echo "${COLOR_WHITE}\nSTEP 2 -" `date "+%d.%m.%Y %H:%M:%S"` "- Create Data Pump Directory ...${COLOR_DEFAULT}" | tee -a $LogFile
${OraSqlplusPath} -s "${OraConnect}" <<ENDCD >>$LogFile 2>&1
WHENEVER SQLERROR EXIT 1;
CREATE OR REPLACE DIRECTORY ${DirectoryName} AS '${OraExpDir}';
EXIT 0
ENDCD
if [ $? != 0 ]
   then
     echo "${COLOR_RED}\nERROR : The Directory ${DirectoryName}=${OraExpDir} is not created.${COLOR_DEFAULT}" | tee -a $LogFile
     return 1
   else
     echo "${COLOR_GREEN}\nINFO  : The Directory ${DirectoryName}=${OraExpDir} is created.${COLOR_DEFAULT}" | tee -a $LogFile
${OraSqlplusPath} -s "${OraConnect}" <<ENDLD | tee -a $LogFile
col owner format a10
col directory_name format a15
col directory_path format a50
select OWNER, DIRECTORY_NAME, DIRECTORY_PATH from dba_directories where directory_name = '$DirectoryName';
EXIT 0
ENDLD
     return 0
fi
}

#----------------------------------------------------------------------------------------------------
# Main Program
#----------------------------------------------------------------------------------------------------

# Help 

if [ "$1" = "help" -o "$1" = "--help" ]
   then
     show_usage
     exit 0
fi

# Debug Mode

if [ "$1" = "debug" ]
   then
     ora_set_tool_env
     ora_show_tool_env
     exit 0
fi

# OS Check

OS=`uname -s`
case "$OS" in
     Linux ) OsRelease=`cat /etc/redhat-release` ; alias echo='echo -e' ; NumCpu=`cat /proc/cpuinfo | grep processor | wc -l` ;;
     AIX   ) OsRelease=`oslevel` ; NumCpu=`lsdev -Ccprocessor | wc -l` ;;
     SunOS) OsRelease=`uname -r` ; NumCpu=`/usr/sbin/psrinfo | wc -l` ;;
     * )     echo "${COLOR_RED}\nERROR - The ${OS} operating system is not supported by this tool.\n${COLOR_DEFAULT}"
             exit 1
             ;;
esac

# Compress Tool Check

if [ "$OS" = "SunOS" ]
   then
     PigzDir=/usr/local/bin
   else
     PigzDir=/usr/bin
fi

if [ -x ${PigzDir}/pigz ]
   then
     CompressCmd=${PigzDir}/pigz
     UnCompressCmd=${PigzDir}/unpigz
     CompressTool=Pigz
     UnCompressTool=Unpigz
   else
     CompressCmd=gzip
     UnCompressCmd=gunzip
     CompressTool=Gzip 
     UnCompressTool=Gunzip
fi

# Get parameters

echo
while [ $# != 0 ]; do
  export Pair=$1
  Pname=`echo $Pair|awk -F= '{ print $1 }'`
  typeset -u Upname=${Pname}
  Pval=`echo $Pair|awk -F= '{ print $2 }'`
  typeset -u Upval=${Pval}
  shift
  case $Upname in
    --SID)      export SID=${Upval};;
    --MODE)     export MODE=${Upval};;
    --SCHEMAS)  export SCHEMALIST=${Upval};;
    --TABLES)   export TABLIST=${Upval};;
    --NLS_LANG) export NLSLANG=${Pval};;
    --FILE)     export FILE=${Pval};;
    --PARALLEL) export PARALLEL=${Pval};;
    --CONTENT)  export CONTENT=${Upval};;
    --TABLE_ACTION) export TABLEACTION=${Upval};;
    --PARFILE)  export PARFILE=${Pval};;
    --LISTJOBS) export LISTJOBS=${Upval};;
    --LISTUSERS) export LISTUSERS=${Upval};;
    --INFODUMP) export INFODUMP=${Upval};;
    --GRANTALL) export GRANTALL=${Upval};;
    --SEQUENCE) export SEQUENCE=${Upval};;
    --DISABLEREFCONST) export DISABLE=${Upval};;
    --RESTARTDB) export RESTARTDB=${Upval};;
    --KILLJOBS) export KILLJOBS=${Upval};;
    *) echo "${COLOR_RED}\nERROR : Unknown parameter : ${Pname}\n${COLOR_DEFAULT}"
       show_usage
       exit 1
       ;;
  esac
done

if [ ! -z "$LISTJOBS" ]
   then
     case "$LISTJOBS" in
       y|Y) MODE=NA
            FILE=" " 
            ;;
       *) echo "${COLOR_RED}ERROR : The --listjobs parameter value is Y or y.\n${COLOR_DEFAULT}"
          exit 1
          ;;
     esac
fi

if [ ! -z "$RESTARTDB" ]
   then
     case "$RESTARTDB" in
       y|Y) MODE=NA
            FILE=" "
            ;;
       *) echo "${COLOR_RED}ERROR : The --restartdb parameter value is Y or y.\n${COLOR_DEFAULT}"
          exit 1
          ;;
     esac
fi

if [ ! -z "$KILLJOBS" ]
   then
     case "$KILLJOBS" in
       y|Y) MODE=NA
            FILE=" "
            ;;
       *) echo "${COLOR_RED}ERROR : The --killjobs parameter value is Y or y.\n${COLOR_DEFAULT}"
          exit 1
          ;;
     esac
fi

if [ ! -z "$PARFILE" ]
   then
     MODE=PARFILE
     FILE=" "
fi

if [ ! -z "$LISTUSERS" ]
   then
     case "$LISTUSERS" in
       y|Y) MODE=NA
            ;;
       *) echo "${COLOR_RED}ERROR : The --listusers parameter value is Y or y.\n${COLOR_DEFAULT}"
          exit 1
          ;;
     esac
fi

if [ ! -z "$INFODUMP" ]
   then
     case "$INFODUMP" in
       y|Y) MODE=NA
            ;;
       *) echo "${COLOR_RED}ERROR : The --infodump parameter value is Y or y.\n${COLOR_DEFAULT}"
          exit 1
          ;;
     esac
fi

if [ ! -z "$GRANTALL" ]
   then
     case "$GRANTALL" in
       y|Y) MODE=NA
            ;;
       *) echo "${COLOR_RED}ERROR : The --grantall parameter value is Y or y.\n${COLOR_DEFAULT}"
          exit 1
          ;;
     esac
fi

if [ ! -z "$SEQUENCE" ]
   then
     case "$SEQUENCE" in
       y|Y) MODE=SCHEMAS
            ;;
       *) echo "${COLOR_RED}ERROR : The --sequence parameter value is Y or y.\n${COLOR_DEFAULT}"
          exit 1
          ;;
     esac
fi

# Check mandatory parameters and set default values

if [ -z "$SID" ]
   then
     echo "${COLOR_RED}ERROR : The mandatory --sid parameter value is not defined.\n${COLOR_DEFAULT}"
     CI=1
   else
     CI=0
fi

if [ -z "$FILE" ]
   then
     echo "${COLOR_RED}ERROR : The mandatory --file parameter value is not defined.\n${COLOR_DEFAULT}"
     CF=1
   else
     CF=0
fi

if [ -z "$MODE" ]
   then
     echo "${COLOR_RED}ERROR : The mandatory --mode parameter value is not defined.\n${COLOR_DEFAULT}"
     CM=1
   else
  case "$MODE" in
    FULL|ALL_SCHEMAS)
       if [ -z "$SCHEMALIST" -a -z "$TABLIST" ]
          then
            CM=0
          else
            echo "${COLOR_RED}ERROR : If the parameter --mode=$MODE, then the parameter --schemas or --tables should not be defined.\n${COLOR_DEFAULT}"
            CM=1
       fi
       ;;
    SCHEMAS)
      if [ -z "$SCHEMALIST" ]
         then
           echo "${COLOR_RED}ERROR : If import mode is set to --mode=SCHEMAS, then the --schemas parameter must be also defined.\n${COLOR_DEFAULT}"
           CM=1
         else
           CM=0
      fi
      ;;
    TABLES)
      if [ -z "$TABLIST" ]
         then
           echo "${COLOR_RED}ERROR : If import mode is set to --mode=TABLES, then the --tables parameter must be also defined.\n${COLOR_DEFAULT}"
           CM=1
         else
           CM=0
      fi
      ;;
    PARFILE|NA)
      CM=0
      ;;
    *) echo "${COLOR_RED}ERROR : The mandatory --mode parameter value is incorrect (FULL or SCHEMAS or ALL_SCHEMAS or TABLES).\n${COLOR_DEFAULT}"
       CM=1 ;;
  esac
fi

if [ -z "$PARALLEL" ]
   then
     PARALLEL=1
     CP=0
   else 
     case "$PARALLEL" in
       AUTO)   PARALLEL=$NumCpu
               #echo "${COLOR_CYAN}WARN  : The parallel mode is not yet implemented in standard mode. Use parfile mode.\n${COLOR_DEFAULT}"	   
               #PARALLEL=1
               CP=0;;
       1|2|3|4|5|6|7|8)
          if [ $NumCpu -lt $PARALLEL ]
             then
               echo "${COLOR_RED}ERROR : The number of (v)CPU=$NumCpu on this server is lower than Parallel Value (PARALLEL=$PARALLEL).\n${COLOR_DEFAULT}"
               CP=1
             else
               #echo "${COLOR_CYAN}WARN  : The parallel mode is not yet implemented in standard mode.\n${COLOR_DEFAULT}"
               #PARALLEL=1
               CP=0
          fi
          ;;
       *) echo "${COLOR_RED}ERROR : The --parallel parameter value must be between 1 and 8.\n${COLOR_DEFAULT}"
          CP=1
           ;;
     esac
fi

if [ -z "$CONTENT" ]
   then
     if [ "$MODE" = "PARFILE" ]
        then
          CONTENT=NA 
        else
          CONTENT=ALL
          if [ "${SEQUENCE}" = "Y" ]
             then
               CONTENT=SEQUENCES
          fi
          if [ "${GRANTALL}" = "Y" ]
             then
               CONTENT=GRANTALL
          fi
          if [ "${RESTARTDB}" = "Y" ]
             then
               CONTENT=RESTARTDB
          fi
     fi
     CC=0
   else
     if [ "$CONTENT" = "ALL" -o "$CONTENT" = "DATA_ONLY" -o "$CONTENT" = "METADATA_ONLY" ]
        then
          CC=0
        else
          echo "${COLOR_RED}ERROR : The --content parameter value must be ALL or DATA_ONLY or METADATA_ONLY.\n${COLOR_DEFAULT}"
          CC=1
     fi
fi

if [ -z "$TABLEACTION" ]
   then
      TABLEACTION=REPLACE
      CT=0
   else
      if [ "$TABLEACTION" = "SKIP" -o "$TABLEACTION" = "REPLACE" -o "$TABLEACTION" = "TRUNCATE" ]
         then
           if [ "$TABLEACTION" = "SKIP" -a "$CONTENT" = "DATA_ONLY" ]
              then
                echo "${COLOR_RED}ERROR : The --table_action parameter value $TABLEACTION is not compatible with the --content parameter value DATA_ONLY.\n${COLOR_DEFAULT}"
                CT=1
           fi 
           if [ "$TABLEACTION" = "REPLACE" -a "$CONTENT" = "DATA_ONLY" ]
              then
                echo "${COLOR_RED}ERROR : The --table_action parameter value $TABLEACTION is not compatible with the --content parameter value DATA_ONLY.\n${COLOR_DEFAULT}"
                CT=1
           fi
         else
           echo "${COLOR_RED}ERROR : The --table_action parameter value must be SKIP or REPLACE or TRUNCATE.\n${COLOR_DEFAULT}"
           CT=1
     fi
fi

if [ ! -z "$NLSLANG" ]
   then
     if [ "$NLSLANG" = "AMERICAN_AMERICA.ALE32UTF8" -o "$NLSLANG" = "AMERICAN_AMERICA.WE8ISO8859P15" ]
        then
          CN=0
        else
          echo "${COLOR_RED}ERROR : The --nls_lang paramater value is incorrect (AMERICAN_AMERICA.<WE8ISO8859P15|ALE32UTF8>).\n${COLOR_DEFAULT}"
          CN=1
     fi
   else
    CN=0
fi

if [ -z "$DISABLE" ]
   then
     DISABLE=N
     CD=0
   else
     if [ "$DISABLE" = "Y" ]
        then
          CD=0
        else
          echo "${COLOR_RED}ERROR : The --disablerefconst parameter value must be Y or y.\n${COLOR_DEFAULT}"
          CD=1
     fi
fi

case "-${CI}-${CF}-${CM}-${CP}-${CC}-${CT}-${CN}-${CD}-" in
     -0-0-0-0-0-0-0-0-) ;;
     *1*) show_usage ; exit 1;;
esac

# Set Environment

ora_set_tool_env

# OS User Check

if [ "$OS" = "SunOS" ]
   then
     User=`/usr/xpg4/bin/id -un`
   else
     User=`id -un`
fi
if [ "$User" != "${OraOsUser}" ]
   then
     echo "${COLOR_RED}\nERROR : This shell must be executed by the user ${OraOsUser}.\n${COLOR_DEFAULT}"
     exit 1
fi

# Set oracle variables

ora_set_oracle_env
[ $? -ne 0 ] && exit 1

# Oracle Instance Check

egrep -v "^#|^$|^\s*$" $ORATAB | egrep "${SID}:" 1>/dev/null 2>&1
if [ $? -ne 0 ]
   then
     echo "${COLOR_RED}\nERROR : The $SID instance doesn't exist in the $ORATAB file.\n${COLOR_DEFAULT}"
     exit 1
fi

# Check Oracle Instance Status

ora_instance_status
if [ $? -ne 0 -a $? -ne 2 ]
   then
     echo "${COLOR_RED}\nERROR : ${MsgIs}\n${COLOR_DEFAULT}"
     exit 1
fi

# Check Oracle Connexion

ora_check_connectivity
if [ $? -gt 0 ]
   then
     echo "${COLOR_RED}\nERROR - It's not possible to connect to the SID ${ORACLE_SID} with USER '${OraConnect}'.\n${COLOR_DEFAULT}"
     exit 1
fi

# Check Oracle Correct Instance Name

ora_check_instance
if [ $? -eq 1 ]
   then
     exit 1
fi

# Oracle impdp Check

if [ ! -x ${OraImpdpPath} ]
   then
     echo "${COLOR_RED}\nERROR : The binary Import Datapump ${OraImpdpPath} doesn't exist.\n${COLOR_DEFAULT}"
     exit 1
fi

# Set linux variables

ora_set_unix_env
[ $? -ne 0 ] && exit 1

# IF MODE=PARFILE - Parfile Checks

if [ ! -z "$PARFILE" ]
   then
     if [ ! -r "$PARFILE" ]
        then
          echo "${COLOR_RED}\nERROR : The Parameter File ${PARFILE} is not readable.\n${COLOR_DEFAULT}"
          exit 1
     fi
     grep -i "DIRECTORY=" $PARFILE 1>/dev/null 2>&1
     if [ $? -eq 0 ]
        then
          DIR=`grep DIRECTORY= $PARFILE | cut -d= -f2`
          if [ "$DIR" != "${DirectoryName}" ]
             then
               echo "${COLOR_RED}\nERROR : The line DIRECTORY=${DirectoryName} is mandatory in the Parameter File ${PARFILE}.\n${COLOR_DEFAULT}"
               exit 1
          fi
        else
          echo "${COLOR_RED}\nERROR : The line DIRECTORY=${DirectoryName} is mandatory in the Parameter File ${PARFILE}.\n${COLOR_DEFAULT}"
          exit 1
      fi
     grep -i "LOGFILE=" $PARFILE 1>/dev/null 2>&1
     if [ $? -ne 0 ]
        then
          echo "${COLOR_RED}\nERROR : The line LOGFILE=<importlogfile> is mandatory in the Parameter File ${PARFILE}.\n${COLOR_DEFAULT}"
          exit 1
     fi
     grep -i "DUMPFILE=" $PARFILE 1>/dev/null 2>&1
     if [ $? -ne 0 ]
        then
          echo "${COLOR_RED}\nERROR : The line DUMPFILE=<exportdumpfile> is mandatory in the Parameter File ${PARFILE}.\n${COLOR_DEFAULT}"
          exit 1
     fi
     grep -i "PARALLEL=" $PARFILE 1>/dev/null 2>&1
     if [ $? -ne 0 ]
        then
          Parallel=No
        else
          NumPara=`grep -i "PARALLEL=" $PARFILE | cut -d= -f2`
          if [ $NumPara -eq 1 ]
             then
               Parallel=No
             else
               Parallel=Yes
          fi
     fi
     if [ "$Parallel" = "No" ]
        then
          ExpDumpFile="${OraExpDir}/`grep DUMPFILE= $PARFILE | cut -d= -f2`"
          if [ ! -r ${ExpDumpFile} ]
             then
               echo "${COLOR_RED}\nERROR : The Export Dump File ${ExpDumpFile} in Parameter File doesn't exist or is not readable.\n${COLOR_DEFAULT}"
               exit 1
          fi
     fi
fi

# List Jobs

if [ "$LISTJOBS" = "Y" ]
   then
     ora_instance_status
     if [ $? -ne 0 -a $? -ne 2 ]
        then
          echo "${COLOR_RED}\nERROR : ${MsgIs}\n${COLOR_DEFAULT}"
          exit 1
     fi
echo "${COLOR_GREEN}\nJobs List in $ORACLE_SID database :\n${COLOR_DEFAULT}"
${OraSqlplusPath} -s "${OraConnect}" <<ENDLJ
SET LINESIZE 100
WHENEVER SQLERROR EXIT 1;
COL owner_name format a10
COL job_name format a20
COL operation format a10
COL job_mode format a10
COL state format a15
SELECT owner_name, job_name, operation, job_mode, state, degree, attached_sessions
  FROM dba_datapump_jobs;
COL message format a50
SELECT sid, serial#, round(sofar/totalwork*100,2) pct_completed, message
  FROM v\$session_longops
 WHERE sofar <> totalwork
   AND opname like 'EXPORTDP_%'
ORDER BY target, sid;
EXIT 0
ENDLJ
   exit $?
fi

# Restart DB 

if [ "$RESTARTDB" = "Y" ]
   then
     NumJobs=`ps -fu $OraOsUser | grep $ScriptName | grep -i sid=$SID | grep -v grep | wc -l`
     [ "$NumJobs" -gt 1 ] && echo "${COLOR_RED}\nERROR : An another $ScriptName job is running.\n${COLOR_DEFAULT}" && exit 1
     echo "${COLOR_WHITE}\n Restarting DB in Normal Mode ...${COLOR_DEFAULT}" 
     ora_shutdown_db
     if [ $? -ne 0 ]
        then
          echo "${COLOR_RED}\nERROR : The DB restart has failed.\n${COLOR_DEFAULT}"
          echo "${COLOR_RED}\nERROR : View $LogFile file for more details.${COLOR_DEFAULT}"
          exit 1
     fi
     ora_startup_db
     if [ $? -ne 0 ]
        then
          echo "${COLOR_RED}\nERROR : The DB restart has failed.\n${COLOR_DEFAULT}"
          echo "${COLOR_RED}\nERROR : View $LogFile file for more details.${COLOR_DEFAULT}"
          exit 1
        else
          rm -f $FlagFile 1>/dev/null 2>&1
          ora_instance_status
          if [ $? -eq 0 ]
             then
               echo "${COLOR_GREEN}\nINFO  : The DB Restart in Normal Mode is terminated successfully - ${MsgIs}\n${COLOR_DEFAULT}"
               exit 0
             else
               echo "${COLOR_RED}\nERROR : The DB Restart in Normal Mode has failed - ${MsgIs}\n${COLOR_DEFAULT}"
               exit 1
          fi
     fi
fi

# Kill Orphaned DataPump Import Jobs
if [ "$KILLJOBS" = "Y" ]
   then
     ora_instance_status
     if [ $? -ne 0 ]
        then
          echo "${COLOR_RED}\nERROR : ${MsgIs}\n${COLOR_DEFAULT}"
          exit 1
     fi
     ora_oracle_var ListJobs "job_name from dba_datapump_jobs where job_name like '${JobNamePrefix}_%' and state not in ('RUNNING', 'EXECUTING')'" 1>/dev/null 2>&1
     [ -z $ListJobs ] && echo "${COLOR_MAGENTA}\nWARNING : There is no Orphaned DataPump Import Jobs to cleanup in the $SID.\n${COLOR_DEFAULT}" && exit 0
     echo "${COLOR_GREEN}Kill Orphaned DataPump Import Jobs in $ORACLE_SID database :\n${COLOR_DEFAULT}"
     for JobName in $ListJobs
         do
ora_oracle_var OwnerName "onwer_name from dba_datapump_jobs where job_name = '${JobName}'" 1>/dev/null 2>&1
${OraSqlplusPath} -s "${OraConnect}" <<ENDKJ
whenever sqlerror exit 1;
drop table ${OwnerName}.${JobName};
exit 0
ENDKJ
         done
     exit 0
fi

# Data Pump Export File Check
# Only on no Parallel Import

echo $FILE | grep -i "%U" 1>/dev/null 2>&1
if [ $? -gt 0 ]
   then
     local WilCard=N
   else
     local WilCard=Y
fi

if [ "$MODE" != "PARFILE" -a "${WilCard}" = "N" ]
   then
     if [ `dirname $FILE` != "." ]
        then
          DmpFile=$FILE
          ls $DmpFile 1>/dev/null 2>&1
          if [ $? -ne 0 ]
             then
               echo "${COLOR_RED}\nERROR : The Data Pump Export File ${FILE} doesn't exist.\n${COLOR_DEFAULT}"
               exit 1
          fi
          OraExpDir=`dirname $FILE`
          TraceFile=${OraExpDir}/${ORACLE_SID}_${MODE}_${CONTENT}_importdp_${Time}.log
          Parfile=${OraExpDir}/${ORACLE_SID}_${MODE}_${CONTENT}_importdp_${Time}.par
        else
          DmpFile=$OraExpDir/$FILE
          ls $DmpFile 1>/dev/null 2>&1
          if [ $? -ne 0 ]
             then
               echo "${COLOR_RED}\nERROR : The Data Pump Export File ${FILE} doesn't exist.\n${COLOR_DEFAULT}"
               exit 1
          fi
     fi
     if [ ! -r $DmpFile ]
        then
          echo "${COLOR_RED}\nERROR : The Data Pump Export File ${DmpFile} is not readable.\n${COLOR_DEFAULT}"
          exit 1
     fi
fi

if [ "$MODE" != "PARFILE" -a $PARALLEL -gt 1 -a "${WilCard}" = "Y" ]
   then
     echo $FILE | grep "," 1>/dev/null 2>&1
     if [ $? -eq 0 ]
        then
          echo "${COLOR_RED}\nERROR : It's not possible to define a set/list of Data Pump Export Files.\n${COLOR_DEFAULT}"
          exit 1
     fi
     echo $FILE | grep -i ".gz" 1>/dev/null 2>&1
     [ $? -eq 0 ] && echo "${COLOR_RED}\nERROR : It's not possible to define a compressed Data Pump Export File.\n${COLOR_DEFAULT}" && exit 1
     if [ `dirname $FILE` != "." ]
        then
          DmpFile=$FILE
          OraExpDir=`dirname $FILE`
          TraceFile=${OraExpDir}/${ORACLE_SID}_${MODE}_${CONTENT}_importdp_${Time}.log
          Parfile=${OraExpDir}/${ORACLE_SID}_${MODE}_${CONTENT}_importdp_${Time}.par
        else
          DmpFile=${OraExpDir}/$FILE  
     fi
fi

#  List Users From Data Pump Export

if [ "$LISTUSERS" = "Y" ]
   then
     ora_instance_status
     if [ $? -ne 0 -a $? -ne 2 ]
        then
          echo "${COLOR_RED}\nERROR : ${MsgIs}\n${COLOR_DEFAULT}"
          exit 1
     fi
     ora_list_users_dp
     exit $?
fi

# Info Dump

if [ "$INFODUMP" = "Y" ]
   then
     ora_instance_status
     if [ $? -ne 0 -a $? -ne 2 ]
        then
          echo "${COLOR_RED}\nERROR : ${MsgIs}\n${COLOR_DEFAULT}"
          exit 1
     fi
     ora_infodump_dp
     exit $?
fi

# Grant All From Data Pump Export

if [ "$GRANTALL" = "Y" ]
   then
     ora_instance_status
     if [ $? -ne 0 -a $? -ne 2 ]
        then
          echo "${COLOR_RED}\nERROR : ${MsgIs}\n${COLOR_DEFAULT}"
          exit 1
     fi
     ora_oper_all_dp grant
     exit $?
fi

# Create all sequences to schema(s) from Data Pump Export

if [ "$SEQUENCE" = "Y" ]
   then
     ora_instance_status
     if [ $? -ne 0 -a $? -ne 2 ]
        then
          echo "${COLOR_RED}\nERROR : ${MsgIs}\n${COLOR_DEFAULT}"
          exit 1
     fi
     ora_oper_all_dp sequence
     exit $?
fi

# Check LogDir directory

if [ ! -d $LogDir ]
   then
     echo "${COLOR_CYAN}WARN  : The $LogDir directory doesn't exist. The new log file directory is $TmpDir.\n${COLOR_DEFAULT}"
     LogDir=$TmpDir
     LogFile=${LogDir}/${ScriptName}_${MODE}_${CONTENT}_${Time}.log
fi

# Check Another ImportDP Job on the same SID

NumJobs=`ps -fu $OraOsUser | grep $ScriptName | grep -i sid=$SID | egrep -i "mode=|parfile=|restartdb=" | grep -v grep | wc -l`
if [ "$NumJobs" -gt 1 ]
   then
     echo "${COLOR_RED}\nERROR : An another $ScriptName job is running on $SID.\n${COLOR_DEFAULT}"
     ps -fu $OraOsUser | grep $ScriptName | grep -i sid=$SID | egrep -i "mode=|parfile=|restartdb=" | grep -v grep
     exit 1
fi

[ `uname -s` = "Linux" ] && alias echo='echo -e'

[ -w $LogFile ] && rm -f $LogFile 1>/dev/null 2>&1

echo "LogFile=$LogFile"

ora_banner "$Text" Begin

#----------------------------------------------------------------------------------------------------
# Managing the Export Dump file
#----------------------------------------------------------------------------------------------------
if [ -z "$PARFILE" -a "${WilCard}" = "N" ]
   then
     Suffix=`ls $DmpFile | awk -F. '{print $3}'`
     if [ "$Suffix" = "gz" ]
        then
          echo "${COLOR_WHITE}\nSTEP 0 -" `date "+%d.%m.%Y %H:%M:%S"` "- Uncompressing the Data Pump Export File(using $UnCompressTool Tool) ...${COLOR_DEFAULT}" | tee -a $LogFile
          $UnCompressCmd $DmpFile 1>/dev/null 2>>$LogFile
	  if [ $? -ne 0 ] 
             then
               echo "${COLOR_RED}\nERROR : The $UnCompressTool has failed.${COLOR_DEFAULT}" | tee -a $LogFile
               exit 1
             else
               echo "${COLOR_GREEN}\nINFO  : The $UnCompressTool is terminated successfully.${COLOR_DEFAULT}" | tee -a $LogFile
          fi
          UnzippedDmpFile=${DmpFile%.gz}
          echo "\nINFO  : The Data Pump Export File is ${UnzippedDmpFile}." | tee -a $LogFile
          FlagGz=Y
        else
          FlagGz=N
          echo "\nINFO  : The Data Pump Export File is ${DmpFile}." | tee -a $LogFile
     fi
   else
     FlagGz=N
fi

#----------------------------------------------------------------------------------------------------
# Disable Referential Constraints if necessary
#----------------------------------------------------------------------------------------------------
if [ "${DISABLE}" = "Y" ]
   then
     echo "${COLOR_WHITE}\nSTEP 0Bis -" `date "+%d.%m.%Y %H:%M:%S"` "- Disabling Referential Constraints ...${COLOR_DEFAULT}" | tee -a $LogFile
${OraSqlplusPath} -s "${OraConnect}" <<ENDDC1 1>>$LogFile 2>&1
WHENEVER SQLERROR EXIT 1
set pages 0 feed off head off linesize 132
SPOOL $SqlDisFile
SELECT 'alter table ' || owner || '.' || table_name || ' disable novalidate constraint ' || constraint_name ||';'
  FROM dba_constraints
 WHERE status = 'ENABLED'
   AND constraint_type = 'R'
   AND owner not in ('SYS', 'SYSTEM', 'PERFSTAT', 'DBSNMP', 'OUTLN', 'ORACLE_OCM', 'APPQOSSYS', 'DIP', 'TSMSYS', 'EXFSYS','MDSYS','ORDSYS','SI_INFORMTN_SCHEMA','ORDPLUGINS','CTXSYS','ANONYMOUS','XDB','SYSMAN', 'MGMT_VIEW', 'CSMIG', 'GSMADMIN_INTERNAL', 'SQLTXPLAIN', 'SQLTXADMIN')
;
SPOOL OFF
EXIT 0
ENDDC1
${OraSqlplusPath} -s "${OraConnect}" <<ENDDC2 1>>$LogFile 2>&1
WHENEVER SQLERROR CONTINUE
SPOOL $SqlDisLogFile
@$SqlDisFile
SPOOL OFF
EXIT 0
ENDDC2
     echo "${COLOR_GREEN}\nINFO  : View $SqlDisLogFile file for more details.${COLOR_DEFAULT}" | tee -a $LogFile
   fi

#----------------------------------------------------------------------------------------------------
# Restart database in restricted mode
#----------------------------------------------------------------------------------------------------
echo "${COLOR_WHITE}\nSTEP 1 -" `date "+%d.%m.%Y %H:%M:%S"` "- Restarting DB in Restrict Mode ...${COLOR_DEFAULT}" | tee -a $LogFile
ora_shutdown_db
if [ $? -ne 0 ]
   then
     exit 1
fi
ora_startup_restrict_db
if [ $? -ne 0 ]
   then
     echo "${COLOR_RED}\nERROR : The DB Restart in Restrict Mode has failed.${COLOR_DEFAULT}" | tee -a $LogFile
     ora_startup_db
     exit 1
   else
     touch $FlagFile
     echo "${COLOR_GREEN}\nINFO  : The DB Restart in Restrict Mode is terminated successfully.${COLOR_DEFAULT}" | tee -a $LogFile
fi

#----------------------------------------------------------------------------------------------------
# Create Data Pump Directory
#----------------------------------------------------------------------------------------------------
ora_create_dir 
[ $? != 0 ] && exit 1

#----------------------------------------------------------------------------------------------------
# Import data
#----------------------------------------------------------------------------------------------------
if [ "$FlagGz" = "Y" ]
   then
     ShortNameDmpFile=`basename $UnzippedDmpFile`
   else
     [ -z "$PARFILE" ] && ShortNameDmpFile=`basename $DmpFile`
fi
ShortTraceFileName=`basename $TraceFile`

echo "${COLOR_WHITE}\nSTEP 3 -" `date "+%d.%m.%Y %H:%M:%S"` "- Importing The Data Pump Export Mode=$MODE ...${COLOR_DEFAULT}" | tee -a $LogFile

cat >>$Parfile <<ENDPF
JOB_NAME=${JobNamePrefix}_${MODE}_${CONTENT}
DIRECTORY=$DirectoryName
DUMPFILE=$ShortNameDmpFile
LOGFILE=$ShortTraceFileName
SKIP_UNUSABLE_INDEXES=YES
ACCESS_METHOD=AUTOMATIC
METRICS=YES
KEEP_MASTER=NO  
MASTER_ONLY=NO
PARALLEL=$PARALLEL
TABLE_EXISTS_ACTION=$TABLEACTION
CONTENT=$CONTENT
STATUS=10
ENDPF

ora_oracle_var Version "version from v\$instance" 1>/dev/null 2>&1
if [ -z ${Version} ]
   then
     MainVersion=10
   else
     MainVersion=`echo ${Version} | cut -d. -f1`
fi
if [ "${MainVersion}" = "12" ]
   then
     echo "TRANSFORM=DISABLE_ARCHIVE_LOGGING:Y" >>$Parfile
fi

# Full Mode
if [ $MODE = "FULL" ]
  then
cat >>$Parfile <<ENDFM
EXCLUDE=DATABASE_EXPORT/SYSTEM_PROCOBJACT/POST_SYSTEM_ACTIONS/PROCACT_SYSTEM
REUSE_DATAFILES=YES
FULL=Y
ENDFM
fi

# Schema(s) Mode
if [ "$MODE" = "SCHEMAS" -a "$CONTENT" != "DATA_ONLY" ]
   then
     ListSchemas=`echo $SCHEMALIST | sed s/,/' '/g`
     for Owner in $ListSchemas
         do
          ora_oracle_var NumOwner "count(*) from dba_users where username = upper('$Owner')"
          if [ $NumOwner -ne 0 ]
             then
               echo "${COLOR_GREEN}\nINFO  : Drop user $Owner cascade (this user exists in the DB).${COLOR_DEFAULT}" | tee -a $LogFile
${OraSqlplusPath} -s "${OraConnect}" <<ENDDU 1>>$LogFile 2>&1
WHENEVER SQLERROR EXIT 1;
DROP USER $Owner CASCADE;
EXIT 0
ENDDU
               [ $? -eq 1 ] && echo "${COLOR_RED}\nERROR : Error on DROP USER $Owner CASCADE.${COLOR_DEFAULT}" | tee -a $LogFile
          fi
         done
fi
if [ "$MODE" = "SCHEMAS" ]
   then
cat >>$Parfile <<ENDSM
SCHEMAS=$SCHEMALIST
ENDSM
fi

# Table(s) Mode
if [ "$MODE" = "TABLES" ]
   then
cat >>$Parfile <<ENDTM
TABLES=$TABLIST
ENDTM
fi

# All Schemas Mode
if [ "$MODE" = "ALL_SCHEMAS" -a "$CONTENT" != "DATA_ONLY" ]
   then
     ora_oracle_var ListUsers "username from dba_users where username not in ('SYS', 'SYSTEM', 'PERFSTAT', 'DBSNMP', 'OUTLN', 'ORACLE_OCM', 'APPQOSSYS', 'OPS\$ORACLE', 'DIP', 'TSMSYS', 'EXFSYS','MDSYS','ORDSYS','SI_INFORMTN_SCHEMA','ORDPLUGINS','CTXSYS','ANONYMOUS','XDB','SYSMAN', 'MGMT_VIEW', 'CSMIG', 'GSMADMIN_INTERNAL', 'SQLTXPLAIN', 'SQLTXADMIN')" 1>/dev/null 2>&1
     echo "\nUSER_SCHEMAS_LIST_TO_DROP_BEFORE_IMPORT_ALL_SCHEMAS:" | tee -a $LogFile
     echo "$ListUsers" | tee -a $LogFile
local Count=1
for User in $ListUsers
do
echo "${COLOR_GREEN}\nINFO  : Drop user $User cascade (this user exists in the DB).${COLOR_DEFAULT}" | tee -a $LogFile
${OraSqlplusPath} -s "${OraConnect}" <<ENDDU >>$LogFile 2>&1
whenever sqlerror exit 1;
drop user $User cascade;
exit 0
ENDDU
[ $? -eq 1 ] && echo "${COLOR_RED}\nERROR : Error on DROP USER $User CASCADE.${COLOR_DEFAULT}" | tee -a $LogFile
if [ "${Count}" = "1" ]
   then
     local SCHEMALIST=${User}
   else
     SCHEMALIST=`echo ${SCHEMALIST},${User}`
fi
Count=`expr ${Count} + 1`
done
     ora_oracle_var ListUsers "username from dba_users where username not in ('SYS', 'SYSTEM', 'PERFSTAT', 'DBSNMP', 'OUTLN', 'ORACLE_OCM', 'APPQOSSYS', 'OPS\$ORACLE', 'DIP', 'TSMSYS', 'EXFSYS','
MDSYS','ORDSYS','SI_INFORMTN_SCHEMA','ORDPLUGINS','CTXSYS','ANONYMOUS','XDB','SYSMAN', 'MGMT_VIEW', 'CSMIG', 'GSMADMIN_INTERNAL', 'SQLTXPLAIN', 'SQLTXADMIN')" 1>/dev/null 2>&1
     echo "\nUSER_SCHEMAS_LIST_AFTER_DROP_USER:" | tee -a $LogFile
     echo "$ListUsers" | tee -a $LogFile
fi
if [ "$MODE" = "ALL_SCHEMAS" ]
   then
#cat >>$Parfile <<ENDAS
#EXCLUDE=DATABASE_EXPORT/SYSTEM_PROCOBJACT/POST_SYSTEM_ACTIONS/PROCACT_SYSTEM
#REUSE_DATAFILES=YES
#FULL=Y
#EXCLUDE=SCHEMA:"IN ('SYS','SYSTEM','PERFSTAT','DBSNMP','OUTLN','ORACLE_OCM','APPQOSSYS','DIP','TSMSYS','EXFSYS','MDSYS','ORDSYS','SI_INFORMTN_SCHEMA','ORDPLUGINS','CTXSYS','ANONYMOUS','XDB','SYSMAN','MGMT_VIEW','CSMIG','GSMADMIN_INTERNAL','SQLTXPLAIN','SQLTXADMIN')"
#ENDAS
      [ -z $SCHEMALIST ] && echo "${COLOR_RED}\nERROR : THE SCHEMALIST is EMPTY${COLOR_DEFAULT}" | tee -a $LogFile
cat >>$Parfile <<ENDAS
SCHEMAS=$SCHEMALIST
ENDAS
      fi

if [ ! -z $PARFILE ] 
    then
      Parfile=$PARFILE
      TraceFile="${OraExpDir}/`grep LOGFILE= $PARFILE | cut -d= -f2`"
      DmpFile="${OraExpDir}/`grep DUMPFILE $PARFILE | cut -d= -f2`"
      SizeDmpFile=`du -k $DmpFile | cut -f1`
fi

echo "\nParameter File Content ($Parfile)" | tee -a $LogFile
cat $Parfile | tee -a $LogFile
${OraImpdpPath} \"${OraConnect}\" parfile=$Parfile 1>$TmpFile 2>&1

#----------------------------------------------------------------------------------------------------
# Import Data Control
#----------------------------------------------------------------------------------------------------
# ORA-39034 = Table does not exist.
# ORA-31684 = Object type SEQUENCE already exists
# ORA-39111 = Dependent object type string skipped, base object type string already exists   
# ORA-39151 = Table exists. All dependent metadata and data will be skipped due to table_exists_action of skip
if [ -r $TraceFile ] 
   then
     if [ "$CONTENT" = "DATA_ONLY" ]
        then
          NumErrors=`grep "ORA-" $TraceFile | egrep -v "ORA-39034" | wc -l`
          if [ $NumErrors -eq 0 ]
             then
               # Import OK
               echo "${COLOR_GREEN}\nINFO  : Data Pump Import terminated successfully with normal errors.${COLOR_DEFAULT}" | tee -a $LogFile
               grep "ORA-" $TraceFile | sort -u | tee -a $LogFile
               echo "${COLOR_GREEN}\nINFO  : Read $TraceFile file for more details.${COLOR_DEFAULT}" | tee -a $LogFile
               RCI=0
             else
               # Import KO
               echo "${COLOR_RED}\nERROR : Data Pump Import terminated with errors.\n${COLOR_DEFAULT}" | tee -a $LogFile
               grep "ORA-" $TraceFile | sort -u | tee -a $LogFile
               echo "${COLOR_RED}\nERROR : Read $TraceFile file for more details.${COLOR_DEFAULT}" | tee -a $LogFile
               RCI=1
          fi
     fi
     if [ "$CONTENT" = "METADATA_ONLY" -o "$CONTENT" = "ALL" -o "$CONTENT" = "NA" ]
        then
          if grep "error" $TraceFile 1>/dev/null 2>&1
             then
               NumErrors=`grep "ORA-" $TraceFile | egrep -v "ORA-31684|ORA-39111" | wc -l`
               if [ $NumErrors -eq 0 ]
                  then
                    # Import OK
                    echo "${COLOR_GREEN}\nINFO  : Data Pump Import terminated successfully with normal errors.${COLOR_DEFAULT}" | tee -a $LogFile
                    echo "${COLOR_GREEN}INFO  : ORA-31684 or ORA-39111 Objects already exists.${COLOR_DEFAULT}" | tee -a $LogFile
                    echo "${COLOR_GREEN}\nINFO  : Read $TraceFile file for more details.${COLOR_DEFAULT}" | tee -a $LogFile
                    RCI=0
                  else
                    # Import KO
                    echo "${COLOR_RED}\nERROR : Data Pump Import terminated with errors.\n${COLOR_DEFAULT}" | tee -a $LogFile
                    grep "ORA-" $TraceFile | egrep -v "ORA-31684|ORA-39111" | sort -u | tee -a $LogFile
                    echo "${COLOR_RED}\nERROR : Read $TraceFile file for more details.${COLOR_DEFAULT}" | tee -a $LogFile
                    RCI=1
               fi
             else
               if grep "successfully completed at" $TraceFile 1>/dev/null 2>&1
                  then
                    if grep "ORA-" $TraceFile 1>/dev/null 2>&1
                       then
                         # Import KO   
                         echo "${COLOR_RED}\nERROR : Data Pump Import terminated with errors.\n${COLOR_DEFAULT}" | tee -a $LogFile
                         grep "ORA-" $TraceFile | egrep -v "ORA-31684|ORA-39111" | sort -u | tee -a $LogFile
                         echo "${COLOR_RED}\nERROR : Read $TraceFile file for more details.${COLOR_DEFAULT}" | tee -a $LogFile
                         RCI=1
                       else
                         # Import OK
                         echo "${COLOR_GREEN}\nINFO  : Data Pump Import terminated successfully without errors.${COLOR_DEFAULT}" | tee -a $LogFile
                         echo "${COLOR_GREEN}\nINFO  : Read $TraceFile file for more details.${COLOR_DEFAULT}" | tee -a $LogFile
                         RCI=0
                    fi
                  else
                    if egrep "ORA-|LRM-" $TmpFile 1>/dev/null 2>&1
                       then
                         # Import KO - Syntax Error in Parameter File
                         echo "${COLOR_RED}\nERROR : Data Pump Import terminated with errors.\n${COLOR_DEFAULT}" | tee -a $LogFile
                         egrep "ORA-|LRM-" $TmpFile | sort -u | tee -a $LogFile
                         RC1=1
                       else
                         RCI=0
                    fi
               fi
          fi
     fi
    else
      if [ -r $TmpFile ] 
         then
           if egrep "ORA-|LRM-" $TmpFile 1>/dev/null 2>&1
              then
                # Import KO - Syntax Error in Parameter File
                echo "${COLOR_RED}\nERROR : Data Pump Import terminated with errors.\n${COLOR_DEFAULT}" | tee -a $LogFile
                egrep "ORA-|LRM-" $TmpFile | sort -u | tee -a $LogFile
                RC1=1
              else
                echo "${COLOR_GREEN}\nINFO  : Data Pump Import terminated successfully without errors.${COLOR_DEFAULT}" | tee -a $LogFile
                RCI=0
           fi
         else
           echo "${COLOR_RED}\nERROR : Data Pump Import Log File $TraceFile/$TmpFile is not readable.\n${COLOR_DEFAULT}" | tee -a $LogFile
           RC1=1
      fi
fi

#----------------------------------------------------------------------------------------------------
# Restart after import
#----------------------------------------------------------------------------------------------------
echo "${COLOR_WHITE}\nSTEP 4 -" `date "+%d.%m.%Y %H:%M:%S"` "- Restarting DB in Normal Mode ...${COLOR_DEFAULT}" | tee -a $LogFile
ora_shutdown_db
ora_startup_db
if [ $? -ne 0 ]
   then
     echo "${COLOR_RED}\nERROR : The DB restart has failed.${COLOR_DEFAULT}" | tee -a $LogFile
     RCR=1
   else
     rm -f $FlagFile 1>/dev/null 2>&1
     ora_instance_status
     if [ $? -eq 0 ]
        then
          echo "${COLOR_GREEN}\nINFO  : The DB Restart in Normal Mode is terminated successfully - ${MsgIs}${COLOR_DEFAULT}" | tee -a $LogFile
          RCR=0
        else
          echo "${COLOR_RED}\nERROR : The DB Restart in Normal Mode has failed - ${MsgIs}${COLOR_DEFAULT}" | tee -a $LogFile
          RCR=1
     fi
fi

#----------------------------------------------------------------------------------------------------
# Enable Referential Constraints if necessary
#----------------------------------------------------------------------------------------------------
if [ "${DISABLE}" = "Y" ]
   then
     echo "${COLOR_WHITE}\nSTEP 4Bis -" `date "+%d.%m.%Y %H:%M:%S"` "- Enabling Disabled Referential Constraints ...${COLOR_DEFAULT}" | tee -a $LogFile
${OraSqlplusPath} -s "${OraConnect}" <<ENDEC1 1>>$LogFile 2>&1
WHENEVER SQLERROR EXIT 1
set pages 0 feed off head off linesize 132
SPOOL $SqlEnaFile
SELECT 'alter table ' || owner || '.' || table_name || ' enable novalidate constraint ' || constraint_name ||';'
  FROM dba_constraints
 WHERE status = 'DISABLED'
   AND constraint_type = 'R'
   AND owner not in ('SYS', 'SYSTEM', 'PERFSTAT', 'DBSNMP', 'OUTLN', 'ORACLE_OCM', 'APPQOSSYS', 'DIP', 'TSMSYS', 'EXFSYS','MDSYS','ORDSYS','SI_INFORMTN_SCHEMA','ORDPLUGINS','CTXSYS','ANONYMOUS','XDB','SYSMAN', 'MGMT_VIEW', 'CSMIG', 'GSMADMIN_INTERNAL')
;
SPOOL OFF
EXIT 0
ENDEC1
${OraSqlplusPath} -s "${OraConnect}" <<ENDEC2 1>>$LogFile 2>&1
WHENEVER SQLERROR CONTINUE
SPOOL $SqlEnaLogFile
@$SqlEnaFile
SPOOL OFF
EXIT 0
ENDEC2
     echo "${COLOR_GREEN}\nINFO  : View $SqlEnaLogFile file for more details.${COLOR_DEFAULT}" | tee -a $LogFile
   fi

#----------------------------------------------------------------------------------------------------
# Compress the dump file 
#----------------------------------------------------------------------------------------------------
if [ "$FlagGz" = "Y" ]
   then
     echo "${COLOR_WHITE}\nSTEP 5 -" `date "+%d.%m.%Y %H:%M:%S"` "- Compressing the Data Pump Export File (using $CompressTool Tool) ...${COLOR_DEFAULT}" | tee -a $LogFile
     $CompressCmd $UnzippedDmpFile 1>/dev/null 2>>$LogFile
     if [ $? -ne 0 ] 
        then
          echo "${COLOR_RED}\nERROR : The $CompressTool has failed.${COLOR_DEFAULT}" | tee -a $LogFile
          RCG=1
        else
          echo "${COLOR_GREEN}\nINFO  : The $CompressTool is terminated successfully.${COLOR_DEFAULT}" | tee -a $LogFile
          RCG=0
     fi
   else
     RCG=0
fi
 
#----------------------------------------------------------------------------------------------------
# Generate Report File
#----------------------------------------------------------------------------------------------------
ora_oracle_var OraVer "version from v\$instance"
if [ $PARALLEL -eq 1 ]
   then
     SizeDmpFile=`du -k $DmpFile | cut -f1`
   else
     if [ "${WilCard}" = "Y" ]
        then
          SizeDmpFile=n/a
        else
          SizeDmpFile=`du -k $DmpFile | cut -f1`
     fi
fi
if [ "$FlagGz" = "Y" ]
   then
     echo "${COLOR_WHITE}\nSTEP 6 -" `date "+%d.%m.%Y %H:%M:%S"` "- Producing the Data Pump Import Report File $ReportFile ...${COLOR_DEFAULT}" | tee -a $LogFile
   else
     echo "${COLOR_WHITE}\nSTEP 5 -" `date "+%d.%m.%Y %H:%M:%S"` "- Producing the Data Pump Import Report File $ReportFile ...${COLOR_DEFAULT}" | tee -a $LogFile
fi
echo "----------------------------------------------------------------------------------------">$ReportFile
echo "Hostname: `uname -n`" >>$ReportFile
echo "  (v)CPU: $NumCpu" >>$ReportFile
echo "      OS: $OsRelease" >>$ReportFile
echo "  Oracle: $OraVer" >>$ReportFile
echo "----------------------------------------------------------------------------------------">>$ReportFile
echo "              DumpDir: $OraExpDir" >>$ReportFile
echo " Data Pump Import Log: $TraceFile" >>$ReportFile
echo "Data Pump Export File: $DmpFile - Size=${SizeDmpFile}KB" >>$ReportFile
echo "----------------------------------------------------------------------------------------">>$ReportFile
echo "Parameter File Content:" >>$ReportFile
cat $Parfile >>$ReportFile
echo "----------------------------------------------------------------------------------------">>$ReportFile
if [ -r $TraceFile ]
   then
     echo "Begin: `grep 'Import: ' $TraceFile | cut -d' ' -f10`">>$ReportFile
     echo "  End: `grep 'Job ' $TraceFile | awk -F"at " '{print $2}'`">>$ReportFile
fi
grep seconds $TmpFile 1>/dev/null 2>&1
if [ $? -eq 0 ]
   then
     echo "Duration:" >>$ReportFile
     grep seconds $TmpFile >>$ReportFile
fi
echo "----------------------------------------------------------------------------------------">>$ReportFile
rm -f $Parfile 1>/dev/null 2>&1

case "-${RCI}-${RCR}-${RCG}-" in
     -0-0-0-) echo "${COLOR_GREEN}\nINFO  : The Data Pump Import has finished !${COLOR_DEFAULT}\n" | tee -a $LogFile ; ora_banner "$Text" End ; exit 0;;
     *1*) echo "${COLOR_RED}\nERROR : The Data Pump Import has failed !\n${COLOR_DEFAULT}" | tee -a $LogFile ; ora_banner "$Text" End ; exit 1;;
     *) echo "${COLOR_RED}\nERROR : The Data Pump Import has failed !\n${COLOR_DEFAULT}" | tee -a $LogFile ; ora_banner "$Text" End ; exit 1;;
esac

