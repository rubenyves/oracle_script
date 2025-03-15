#!/bin/ksh
# @(#):Version:1.4.4
#----------------------------------------------------------------------------------------------------
# Copyright(c) 2015 Orange Corporation. All Rights Reserved.
#
# NAME
#    OraExportDp.ksh
#
# DESCRIPTION
#    Oracle Data Pump Export Tool
#           Data Pump Export (Full or Schemas or Tables)
#
# REMARKS
#
#    The script must be executed by the owner of Oracle software (or OraOsUser value)
#
#    Prerequisites :
#        Oracle Database Enterprise Edition 10g or 11g or 12c
#
#    Input parameters: 
#        Mandatory parameters: 
#                  --sid=ORACLE_SID                         --> instance name
#                  --mode=<FULL|SCHEMAS|TABLES>             --> export full or schema(s) or all schemas or table(s)
#        Optional parameters:
#                  --parfile=<Parfile>                      --> Parameter File to use
#                  --listjobs=Y                             --> List of Data Pump Jobs in an instance
#                  --killjobs=Y                             --> Kill Orphaned DataPump Export Jobs
#                  --listschemas=Y                          --> List of Schemas in an instance
#                  --schemas=<schemalist>                   --> Schema(s) to import
#                  --tables=<tablelist>                     --> Table(s) to import
#                  --nls_lang=<lang>                        --> character set if needed
#                  --parallel=<num>|AUTO                    --> parallel (default : 1)
#                  --retention=<numdays>                    --> Exports Dump File Retention in Days on Disk (default : n/a)
#                  --content=<ALL|DATA_ONLY|METADATA_ONLY>  --> Type of export
#                  --dumpdir=<dir>                          --> Export Dump Directory (default: <OraPatch>/<SID>/e01)
#                  --gzip=<Y|N>                             --> Dump compression (default : N)
#                  --version=<xx.x>                         --> Oracle Version of the DataPump Export
#
#    Output : 
#        Script Log File - <OraLogDir>/OraExportDp_<MODE>_<ddmmyyyy>_<hhHmm>.log
#        Export Log File - <OraExpDir>/<SID>_<MODE>_<ddmmyyyy>_<hhHmm>.log
#
# CHANGES LOG:
#    Fabrice CHAILLOU (ORANGE/IMT/OLPS/IVA/IAC/EIV) - 01/04/2015 - 1.0.0
#    Fabrice CHAILLOU (ORANGE/IMT/OLPS/IVA/IAC/EIV) - 06/04/2015 - 1.0.1
#            Add Solaris compatibility
#    Fabrice CHAILLOU (ORANGE/IMT/OLPS/IVA/IAC/EIV) - 10/04/2015 - 1.1.0
#            Add gzip and listschemas optional parameters
#            Add informations on generated report
#    Fabrice CHAILLOU (ORANGE/IMT/OLPS/IVA/IAC/EIV) - 15/04/2015 - 1.2.0
#            Add version optional parameter
#            Add parallel=AUTO choice --> The degree is equal to NumCpu
#    Fabrice CHAILLOU (ORANGE/IMT/OLPS/IVA/IAC/EIV) - 05/05/2015 - 1.3.0
#            Desactivate parallelism option (not operational)
#            Fix Bug on Database Test Return Code on listjobs and listschemas options
#            Add GSMADMIN_INTERNAL owner in excluding lists
#            Add SID filter in control of another job running on the DB
#            Add killjobs option to cleanup Orphaned DataPumps Import Jobs in DBA_DATAPUMP_JOBS view
#            Change default value on gzip option : Y to N
#    Fabrice CHAILLOU (ORANGE/IMT/OLPS/IVA/IAC/EIV) - 06/05/2015 - 1.3.1
#            Replace gzip compress tool by pigz if available
#    Fabrice CHAILLOU (ORANGE/IMT/OLPS/IVA/IAC/EIV) - 11/05/2015 - 1.3.2
#            Activate parallelism option (without compression)
#    Fabrice CHAILLOU (ORANGE/IMT/OLPS/IVA/IAC/EIV) - 14/05/2015 - 1.3.3
#            Replace --gip option by --compress option
#    Fabrice CHAILLOU (ORANGE/IMT/OLPS/IVA/IAC/EIV) - 11/06/2015 - 1.3.4
#            Add consistency export dump : flashback_time=systimestamp
#            Activate parallelism option with compression
#    Fabrice CHAILLOU (ORANGE/IMT/OLPS/IVA/IAC/EIV) - 29/06/2015 - 1.3.5
#            Fix Bug on flashback_time=systimestamp (Oracle10gR2)
#    Fabrice CHAILLOU (ORANGE/IMT/OLPS/IVA/IAC/EIV) - 10/08/2015 - 1.3.6
#            Fix Bugs on parfile mode
#            Add explanations on help
#            Add control of parallelism on parfile mode
#    Fabrice CHAILLOU (ORANGE/IMT/OLPS/IVA/IAC/EIV) - 17/08/2015 - 1.3.7
#            Fix minors bugs on parfile mode
#    Fabrice CHAILLOU (ORANGE/IMT/OLPS/IVA/IAC/EIV) - 22/09/2015 - 1.3.8
#            Fix bugs on Solaris (adding paths to psrinfo and pigz tool)
#            Add SQLTXPLAIN and SQLTXADMIN schemas in exclude schemas list 
#    Fabrice CHAILLOU (ORANGE/IMT/OLPS/IVA/IAC/EIV) - 28/12/2015 - 1.3.9
#            Fix minor bug on ORACLE_HOME setting (databases with the same string)
#    Fabrice CHAILLOU (ORANGE/IMT/OLS/IVA/IAC/EIV) - 11/05/2017 - 1.4.0
#            Introduce optional yaml configuration file to customize tool environment
#    Fabrice CHAILLOU (ORANGE/IMT/OLS/IVA/IAC/EIV) - 22/05/2017 - v1.4.1 - Modification
#            Add a control of the name of the instance (ora_check_instance function)
#            Introduce DirectoryName and JobNamePrefix variables
#    Fabrice CHAILLOU (ORANGE/IMT/OLS/IVA/IAC/EIV) - 23/05/2017 - v1.4.2 - Modification
#            Fix bug on content of report file (null content)
#            Fix bug on datapump export file read privilege before compression process
#            Fix Bug on killjob option (owner_name of the job)
#            Fix bug on msgis variable name
#    Fabrice CHAILLOU (ORANGE/IMT/OLS/IVA/IAC/EIV) - 26/05/2017 - v1.4.3 - Modification
#            On Killjobs option, change return code from 1 to 0 if no job to kill
#
#    Akili Zegaoui 01/04/20 : Specific update for Compliance, output format  includes schema name if specified.
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
export ORA_NLS10=${ORACLE_HOME}/nls/data
export ORA_NLS11=${ORACLE_HOME}/nls/data
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
echo "OraExpdpPath=${OraExpPath}"
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
     OraExpdpPath=`grep -w "^OraExpdpPath" ${OraConfTools} | awk '{print $2}'`
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
export OraConnect OraOsUser OraLogDir OraExpDir OraSqlplusPath OraExpdpPath

ora_set_oracle_env

[ -z ${OraSqlplusPath} ] && OraSqlplusPath=${ORACLE_HOME}/bin/sqlplus
[ -z ${OraExpdpPath} ] && OraExpdpPath=${ORACLE_HOME}/bin/expdp
[ -z "$OraExpDir" ] && OraExpDir=${OraPath}/${ORACLE_SID}/e01                         
[ -z "$OraLogDir" ] && export OraLogDir=${OraPath}/${ORACLE_SID}/adm/dbalog          

export DirectoryName=DMPDIR   # Directory Name
export JobNamePrefix=EXPDP    # Job Name Prefix             

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
Time=`date "+%d%m%Y_%HH%M"`                                                           # Time
Text="Data Pump Export  Mode: $MODE     "
export ScriptName=`basename $0 | cut -d. -f1`                                         # Script File Name
export TmpDir=/tmp                                                                    # Tmp Directory

if [ $MODE = "SCHEMAS" ]; then
 MODE1=$(echo $SCHEMALIST | tr "," "-")
else
 MODE1=$MODE
fi

export Parfile=${OraExpDir}/${ORACLE_SID}_${MODE1}_${CONTENT}_exportdp_${Time}.par     # Parameter File Name
export LogFile=${OraLogDir}/${ScriptName}_${MODE1}_${CONTENT}_${Time}.log              # Script Log File Name
if [ $PARALLEL -eq 1 ]
   then
export DmpFile=${OraExpDir}/${ORACLE_SID}_${MODE1}_${CONTENT}_exportdp_${Time}.dmp     # Export File Name
   else
export DmpFile=${OraExpDir}/${ORACLE_SID}_${MODE1}_${CONTENT}_exportdp_%U_${Time}.dmp  # Export File Name
export DmpSFile=${OraExpDir}/${ORACLE_SID}_${MODE1}_${CONTENT}_exportdp_*_${Time}.dmp   
fi
export TraceFile=${OraExpDir}/${ORACLE_SID}_${MODE1}_${CONTENT}_exportdp_${Time}.log   # Export Log File Name
export ReportFile=${OraExpDir}/${ORACLE_SID}_${MODE1}_${CONTENT}_exportdp_${Time}.rep  # Export Log File Name
export HistoryFile=${OraLogDir}/${ORACLE_SID}_history.log                             # History File Name
export TmpFile=${TmpDir}/${ORACLE_SID}_${MODE1}_${CONTENT}_exportdp_${Time}.tmp        # Temporary File Name

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
ora_show_usage()
{
  echo ${COLOR_BLUE}
  echo "* List DataPump Export Jobs running in the Oracle Instance <ORACLE_SID>"
  echo ${COLOR_GREEN}
  echo "Usage: $0 --sid=<ORACLE_SID> --listjobs=Y"
  echo ${COLOR_BLUE}
  echo "* Kill DataPump Export Jobs running in the Oracle Instance <ORACLE_SID>"
  echo ${COLOR_GREEN}
  echo "Usage: $0 --sid=<ORACLE_SID> --killjobs=Y"
  echo ${COLOR_BLUE}
  echo "* List Application Schemas in the Oracle Instance <ORACLE_SID>"
  echo ${COLOR_GREEN}
  echo "Usage: $0 --sid=<ORACLE_SID> --listschemas=Y"
  echo ${COLOR_BLUE}
  echo "* Export in a specific mode (full, list of schemas, list of tables) to a DataPump Export File from the oracle database <ORACLE_SID>"
  echo ${COLOR_GREEN}
  echo "Usage: $0 --sid=<ORACLE_SID> --mode=<FULL|SCHEMAS|TABLES> [parameter=value, ...]"
  echo ${COLOR_BLUE}
  echo "Parameter             Description                                            Required Default"
  echo "-------------------   ------------------------------------------------------ -------- --------"
  echo "--sid                 Instance Name : ORACLE_SID                             Yes"
  echo "--mode                Export Mode : FULL or SCHEMAS or TABLES                Yes"
  echo "--schemas             Schema(s) List to import (Export Mode = SCHEMAS)       No"
  echo "--tables              Table(s) List to import (Export Mode = TABLES)         No"
  echo "--parallel            Parallel (1 to 8 or AUTO)                              No       1"
  echo "--retention           Exports Dump File Retention in Days on Disk (1 to 20)  No       n/a"
  echo "--content             Export Content : DATA_ONLY or METADATA_ONLY or ALL     No       ALL"
  echo "--dumpdir             Export Dump Directory                                  No       <ORAPATH>/<SID>/e01"
  echo "--compress            Dump Compression (gzip or pigz) : Y or N               No       N"  
  echo "--version             Oracle Version of Data Pump Export (10.2,11.2,12.x)    No       COMPATIBLE"  
  echo "--nls_lang            NLS_LANG : WE8ISO8859P15 or ALE32UTF8                  No       n/a"
  echo ${COLOR_DEFAULT}
  echo "Examples : SCHEMA MODE $0 --sid=PWSAABU --mode=SCHEMAS --schemas=OPAPY"
  echo "                       $0 --sid=PWSAABU --mode=SCHEMAS --schemas=OPAPY,OPAPYFR"
  echo "           TABLE MODE  $0 --sid=PWSAABU --mode=TABLES --tables=OPAPY.BU"
  echo "                       $0 --sid=PWSAABU --mode=TABLES --tables=OPAPY.BU,OPAPY.OFFERS"
  echo "           FULL MODE   $0 --sid=PWSAABU --mode=FULL --parallel=AUTO --compress=Y"
  echo "                       $0 --sid=PWSAABU --mode=FULL --parallel=AUTO --compress=Y --retention=2"
  echo "                       $0 --sid=PWSAABU --mode=FULL --content=DATA_ONLY --parallel=2 --compress=Y --version=10.2"
  echo  ${COLOR_BLUE}
  echo "* DataPump Export using a parfile (custom export)"
  echo ${COLOR_GREEN}
  echo "Usage: $0 --sid=<ORACLE_SID> --parfile=<Parfile>"
  echo  ${COLOR_BLUE}
  echo "Parfile Only : Tablespace Mode,  Transportable Tablespace Mode, Network Export, Data Filters, MetaData Filters, Encrypted Export Dump File"
  echo ${COLOR_DEFAULT}
  echo "Examples : $0 --sid=PWSAABU --parfile=/oradata/PWSAABU/e01/PWSAABU_exportdp_31032015_10H31.par"
  echo "           $0 --sid=PWSAABU --parfile=/tmp/ExportDp.par --dumpdir=/tmp --compress=y"
  echo
}

#----------------------------------------------------------------------------------------------------
# Create Data Pump Directory
#----------------------------------------------------------------------------------------------------
ora_create_dir()
{
echo "${COLOR_WHITE}\nSTEP 1 -" `date "+%d.%m.%Y %H:%M:%S"` "- Create Data Pump Directory ...${COLOR_DEFAULT}" | tee -a $LogFile
${OraSqlplusPath} -s "${OraConnect}" <<ENDCD >>$LogFile 2>&1
WHENEVER SQLERROR EXIT 1;
CREATE OR REPLACE DIRECTORY $DirectoryName AS '$OraExpDir';
EXIT 0
ENDCD
if [ $? != 0 ]
   then
     echo "${COLOR_RED}\nERROR : The Directory $DirectoryName=$OraExpDir is not created.${COLOR_DEFAULT}" | tee -a $LogFile
     return 1
   else
     echo "${COLOR_GREEN}\nINFO  : The Directory $DirectoryName=$OraExpDir is created.${COLOR_DEFAULT}" | tee -a $LogFile
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
# Export data
#----------------------------------------------------------------------------------------------------
ora_export_dp()
{
ShortNameDmpFile=`basename $DmpFile`
ShortTraceFileName=`basename $TraceFile`

echo "${COLOR_WHITE}\nSTEP 2 -" `date "+%d.%m.%Y %H:%M:%S"` "- Data Pump Export Mode=$MODE ...${COLOR_DEFAULT}" | tee -a $LogFile

cat >>$Parfile <<ENDPF
JOB_NAME=${JobNamePrefix}_${MODE}_${CONTENT}
DIRECTORY=${DirectoryName}
DUMPFILE=$ShortNameDmpFile
LOGFILE=$ShortTraceFileName
STATUS=10
PARALLEL=$PARALLEL
CONTENT=$CONTENT
VERSION=$VERSION
FLASHBACK_TIME="TO_TIMESTAMP(TO_CHAR(systimestamp,'DD-MM-YYYY HH24:MI:SS'), 'DD-MM-YYYY HH24:MI:SS')"
ENDPF
#FLASHBACK_TIME=systimestamp

# Full Mode
if [ $MODE = "FULL" ]
  then
cat >>$Parfile <<ENDFM
FULL=Y
ENDFM
fi

if [ "$MODE" = "SCHEMAS" ]
   then
cat >>$Parfile <<ENDSM
SCHEMAS=$SCHEMALIST
ENDSM
fi

# Table(s) Mode
if [ $MODE = "TABLES" ]
   then
cat >>$Parfile <<ENDTM
TABLES=$TABLIST
ENDTM
fi

if [ ! -z $PARFILE ]
    then
      Parfile=$PARFILE
      TraceFile="${OraExpDir}/`grep LOGFILE= $PARFILE | cut -d= -f2`"
      DumpFile="${OraExpDir}/`grep DUMPFILE= $PARFILE | cut -d= -f2`"
      grep -i "PARALLEL=" $PARFILE 1>/dev/null 2>&1
      if [ $? -eq 0 ]
         then
           PARALLEL=`grep PARALLEL= $PARFILE | cut -d= -f2`
         else
           PARALLEL=1
      fi
      if [ "$PARALLEL" = "1" ]
         then
           DmpFile=$DumpFile
         else
           if [ $NumCpu -lt $PARALLEL ]
             then
               echo "${COLOR_RED}ERROR : The number of (v)CPU=$NumCpu on this server is lower than the parallel value (PARALLEL=$PARALLEL).\n${COLOR_DEFAULT}"
               return 1
             else
               DmpSFile=`echo $DumpFile | sed s/%U/*/`
           fi
      fi
fi

echo "\nParameter File Content ($Parfile)" | tee -a $LogFile
cat $Parfile | tee -a $LogFile
TimeDpStart=`date "+%d/%m/%Y %H:%M:%S"`
echo "\nDatapump Export Cmd : ${OraExpdpPath} user/password parfile=$Parfile\n"
${OraExpdpPath} \"${OraConnect}\" parfile=$Parfile 1>$TmpFile 2>&1
TimeDpStop=`date "+%d/%m/%Y %H:%M:%S"`
if [ $PARALLEL -eq 1 ]
   then
     if [ -r $DmpFile ]
        then
          SizeDmpFile=`du -k $DmpFile | cut -f1`
        else
          SizeDmpFile=0
     fi
   else
     if grep "error" $TraceFile 1>/dev/null 2>&1
        then
          SizeDmpFile=0
          ListDmpFile=0
        else
          SizeDmpFile=`du -ck $DmpSFile | grep total | cut -f1`
          ListDmpFile=`du -k $DmpSFile`
     fi
fi
return 0
}

#----------------------------------------------------------------------------------------------------
# Export Data Control
#----------------------------------------------------------------------------------------------------
ora_control_dp()
{
if [ -r $TraceFile ]
   then
     if grep "error" $TraceFile 1>/dev/null 2>&1
        then
          # Export KO
          echo "${COLOR_RED}\nERROR : Data Pump Export terminated with errors.\n${COLOR_DEFAULT}" | tee -a $LogFile
          grep "ORA-" $TraceFile | sort -u | tee -a $LogFile
          echo "${COLOR_RED}\nERROR : Read $TraceFile file for more details.${COLOR_DEFAULT}" | tee -a $LogFile
          return 1
     fi
     if grep "successfully completed at" $TraceFile 1>/dev/null 2>&1
        then
          if grep "ORA-" $TraceFile 1>/dev/null 2>&1
             then
               # Export KO     
               echo "${COLOR_RED}\nERROR : Data Pump Export terminated with errors.\n${COLOR_DEFAULT}" | tee -a $LogFile
               grep "ORA-" $TraceFile | sort -u | tee -a $LogFile
               echo "${COLOR_RED}\nERROR : Read $TraceFile file for more details.${COLOR_DEFAULT}" | tee -a $LogFile
               return 1
             else
               # Export OK
               echo "${COLOR_GREEN}\nINFO  : Data Pump Export terminated successfully without errors.${COLOR_DEFAULT}" | tee -a $LogFile
               echo "${COLOR_GREEN}\nINFO  : Read $TraceFile file for more details.${COLOR_DEFAULT}" | tee -a $LogFile
               if [ ! -z $RETENTION ]
                  then
                    # Delete old Export Dump Files
                    echo "${COLOR_GREEN}\nINFO  : Delete Data Pump Export Files (${RETENTION}) days old) :${COLOR_DEFAULT}" | tee -a $LogFile
                    find ${OraExpDir} -name "${ORACLE_SID}_*_exportdp_*.*" -mtime +${RETENTION} -print -exec rm -f {} \;
               fi 
               return 0
          fi
        else
          if egrep "ORA-|LRM-" $TmpFile 1>/dev/null 2>&1
            then
              # Export KO - Syntax Error in Parameter File
              echo "${COLOR_RED}\nERROR : Data Pump Export terminated with errors.\n${COLOR_DEFAULT}" | tee -a $LogFile
              egrep "ORA-|LRM-" $TmpFile | sort -u | tee -a $LogFile
              return 1
            else
              return 0
          fi
     fi
   else
      if egrep "ORA-|LRM-" $TmpFile 1>/dev/null 2>&1
         then
           # Export KO - Syntax Error in Parameter File
           echo "${COLOR_RED}\nERROR : Data Pump Export terminated with errors.\n${COLOR_DEFAULT}" | tee -a $LogFile
           egrep "ORA-|LRM-" $TmpFile | sort -u | tee -a $LogFile
           return 1
         else
           echo "${COLOR_RED}\nERROR : Data Pump Export Log File $TraceFile is not readable.\n${COLOR_DEFAULT}" | tee -a $LogFile
           return 1
      fi
fi
}

#----------------------------------------------------------------------------------------------------
# Compress the dump file
#----------------------------------------------------------------------------------------------------
ora_compress_dp()
{
echo "${COLOR_WHITE}\nSTEP 3 -" `date "+%d.%m.%Y %H:%M:%S"` "- Compress the Export Dump File (using $CompressTool tool) ...${COLOR_DEFAULT}" | tee -a $LogFile
TimeCompressStart=`date "+%d/%m/%Y %H:%M:%S"`
if [ $PARALLEL -eq 1 ]
   then
     if [ ! -r $DmpFile ]
        then
          echo "${COLOR_RED}\nERROR : The user ${OraOsUser} has no read privilege on ${DmpFile}.\n${COLOR_DEFAULT}" | tee -a $LogFile
          return 1
     fi
     $CompressCmd -f $DmpFile
     if [ $? -ne 0 ]
        then
          TimeCompressStop=`date "+%d/%m/%Y %H:%M:%S"`
          grep $CompressCmd $LogFile 1>/dev/null 2>&1
          if [ $? -eq 0 ]
             then
               grep $CompressCmd $LogFile
          fi
          echo "${COLOR_RED}\nERROR : The $CompressTool has failed.\n${COLOR_DEFAULT}" | tee -a $LogFile
          return 1
        else
          TimeCompressStop=`date "+%d/%m/%Y %H:%M:%S"`
          echo "${COLOR_GREEN}\nINFO  : The $CompressTool is terminated successfully.\n${COLOR_DEFAULT}" | tee -a $LogFile
          ls -al $DmpFile.gz | tee -a $LogFile
          SizeDmpFileGz=`du -k $DmpFile.gz | cut -f1`
          return 0
     fi
   else
     Rc=0
     for File in `ls $DmpSFile`
         do
          if [ ! -r $File ]
             then
               echo "${COLOR_RED}\nERROR : The user ${OraOsUser} has no read privilege on ${File}.\n${COLOR_DEFAULT}" | tee -a $LogFile
               TimeCompressStop=`date "+%d/%m/%Y %H:%M:%S"`
               SizeDmpFileGz=0
               return 1
          fi
          $CompressCmd -f $File
          if [ $? -ne 0 ]
              then
                echo "${COLOR_RED}\nERROR : The $CompressTool has failed on file ${File}.${COLOR_DEFAULT}" | tee -a $LogFile
                Rc=1
              else
                echo "${COLOR_GREEN}\nINFO  : The $CompressTool is terminated successfully on file ${File}.${COLOR_DEFAULT}" | tee -a $LogFile
          fi
         done
     echo " "
     ls -al $DmpSFile.gz | tee -a $LogFile
     SizeDmpFileGz=`du -ck $DmpSFile.gz | grep total | cut -f1`
     TimeCompressStop=`date "+%d/%m/%Y %H:%M:%S"`
     return $Rc
fi
}

#----------------------------------------------------------------------------------------------------
# Produce a report of the Export Dump File
#----------------------------------------------------------------------------------------------------
ora_report_dp()
{
ora_oracle_var OraVer "version from v\$instance"
echo "-------------------------------------------------------------------------------------------------------">$ReportFile
echo "Hostname: `uname -n`" >>$ReportFile
echo "  (v)CPU: $NumCpu" >>$ReportFile
echo "      OS: $OsRelease" >>$ReportFile
echo "  Oracle: $OraVer" >>$ReportFile
echo "-------------------------------------------------------------------------------------------------------">>$ReportFile
echo "              DumpDir: $OraExpDir" >>$ReportFile
echo " Data Pump Export Log: $TraceFile" >>$ReportFile
if [ "$COMPRESS" = "N" ]
   then
     if [ $PARALLEL -eq 1 ]
        then
          echo "Data Pump Export File: $DmpFile - Size=${SizeDmpFile}KB" >>$ReportFile
        else
          echo "Data Pump Export Files: (Size in KB and File Name)" >>$ReportFile
          du -k $DmpSFile >>$ReportFile
     fi
fi
echo "-------------------------------------------------------------------------------------------------------">>$ReportFile
echo "Data Pump Export: Begin --> $TimeDpStart - End --> $TimeDpStop">>$ReportFile
if [ "$COMPRESS" = "Y" ]
   then 
     if [ $RCCompress -eq 0 ]
        then
          echo "   Compress Tool: $CompressTool">>$ReportFile
          echo "   Dump Compress: Begin --> $TimeCompressStart - End --> $TimeCompressStop">>$ReportFile
          echo "\tSizeBeforeCompress=${SizeDmpFile}KB SizeAfterCompress=${SizeDmpFileGz}KB">>$ReportFile
          if [ $PARALLEL -eq 1 ]
             then
               echo "Data Pump Export File: $DmpFile.gz" >>$ReportFile
             else
               echo "Data Pump Export Files: (Size in KB and File Name)" >>$ReportFile
               du -k $DmpSFile.gz >>$ReportFile
          fi
        else
          if [ $PARALLEL -eq 1 ]
             then
               echo "Data Pump Export File: $DmpFile - Size=${SizeDmpFile}KB" >>$ReportFile
             else
               echo "Data Pump Export Files: (Size in KB and File Name)" >>$ReportFile
               du -k $DmpSFile.gz >>$ReportFile
          fi
     fi
fi
echo "-------------------------------------------------------------------------------------------------------">>$ReportFile
echo "Parameter File Content:" >>$ReportFile
cat $Parfile >>$ReportFile 2>/dev/null
[ "$MODE" != "PARFILE" ] && rm -f $Parfile 1>/dev/null 2>&1
rm -f $TmpFile 1>/dev/null 2>&1
echo "-------------------------------------------------------------------------------------------------------">>$ReportFile
}

#----------------------------------------------------------------------------------------------------
# Main Program
#----------------------------------------------------------------------------------------------------

# Help 

if [ "$1" = "help" -o "$1" = "--help" ]
   then
     ora_show_usage
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
     CompressTool=Pigz
   else
     CompressCmd=gzip
     CompressTool=Gzip 
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
    --PARALLEL) export PARALLEL=${Pval};;
    --CONTENT)  export CONTENT=${Upval};;
    --PARFILE)  export PARFILE=${Pval};;
    --LISTJOBS) export LISTJOBS=${Upval};;
    --KILLJOBS) export KILLJOBS=${Upval};;
    --LISTSCHEMAS) export LISTSCHEMAS=${Upval};;
    --DUMPDIR)  export DUMPDIR=${Pval};;
    --RETENTION)export RETENTION=${Pval};;
    --COMPRESS) export COMPRESS=${Upval};;
    --VERSION)  export VERSION=${Pval};;
    *) echo "${COLOR_RED}\nERROR : Unknown parameter : ${Pname}\n${COLOR_DEFAULT}"
       ora_show_usage
       exit 1
       ;;
  esac
done

if [ ! -z "$LISTJOBS" ]
   then
     case "$LISTJOBS" in
       y|Y) MODE=NA
            ;;
       *) echo "${COLOR_RED}ERROR : The --listjobs parameter value is Y or y.\n${COLOR_DEFAULT}"
          exit 1
          ;;
     esac
fi

if [ ! -z "$LISTSCHEMAS" ]
   then
     case "$LISTSCHEMAS" in
       y|Y) MODE=NA
            ;;
       *) echo "${COLOR_RED}ERROR : The --listschemas parameter value is Y or y.\n${COLOR_DEFAULT}"
          exit 1
          ;;
     esac
fi

if [ ! -z "$KILLJOBS" ]
   then
     case "$KILLJOBS" in
       y|Y) MODE=NA
            ;;
       *) echo "${COLOR_RED}ERROR : The --killjobs parameter value is Y or y.\n${COLOR_DEFAULT}"
          exit 1
          ;;
     esac
fi

if [ ! -z "$PARFILE" ]
   then
     MODE=PARFILE
fi

# Check mandatory parameters and set default values

if [ -z "$SID" ]
   then
     echo "${COLOR_RED}ERROR : The mandatory --sid parameter value is not defined.\n${COLOR_DEFAULT}"
     CI=1
   else
     CI=0
fi

if [ -z "$MODE" ]
   then
     echo "${COLOR_RED}ERROR : The mandatory --mode parameter value is not defined.\n${COLOR_DEFAULT}"
     CM=1
   else
  case "$MODE" in
    FULL)
       if [ -z "$SCHEMALIST" -a -z "$TABLIST" ]
          then
            CM=0
          else
            echo "${COLOR_RED}ERROR : If the parameter --mode=FULL, then the parameter --schemas or --tables should not be defined.\n${COLOR_DEFAULT}"
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
      if [ ! -z "$SCHEMAS" -o ! -z "$TABLES" -o ! -z "$CONTENT" -o ! -z "$PARALLEL" -o ! -z "$VERSION" ]
         then
           echo "${COLOR_CYAN}WARN  : In Parfile Mode, the options --schemas=, --tables=, --content=, --parallel=, --version=, --nls_lang are ignored.\n${COLOR_DEFAULT}"
           CM=0
         else
           CM=0
      fi
      ;;
    *) echo "${COLOR_RED}ERROR : The mandatory --mode parameter value is incorrect (FULL or SCHEMAS or TABLES).\n${COLOR_DEFAULT}"
       CM=1 ;;
  esac
fi

if [ -z "$PARALLEL" ]
   then
     PARALLEL=1
     CP=0
   else 
     case "$PARALLEL" in
       AUTO) PARALLEL=$NumCpu 
             #COMPRESS=N
             CP=0
             ;;
       1|2|3|4|5|6|7|8) 
          if [ $NumCpu -lt $PARALLEL ]
             then
               echo "${COLOR_RED}ERROR : The number of (v)CPU=$NumCpu on this server is lower than the parallel value (PARALLEL=$PARALLEL).\n${COLOR_DEFAULT}"
               CP=1
             else
               #COMPRESS=N
               CP=0
          fi
          ;;
       *) echo "${COLOR_RED}ERROR : The --parallel optional parameter value must be between 1 and 8 [Default: 1].\n${COLOR_DEFAULT}"
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

if [ ! -z "$NLSLANG" ]
   then
     if [ "$NLSLANG" = "AMERICAN_AMERICA.ALE32UTF8" -o "$NLSLANG" = "AMERICAN_AMERICA.WE8ISO8859P15" ]
        then
          CN=0
        else
          echo "${COLOR_RED}ERROR : The --nls_lang optional parameter value is incorrect (AMERICAN_AMERICA.<WE8ISO8859P15|ALE32UTF8>).\n${COLOR_DEFAULT}"
          CN=1
     fi
   else
    CN=0
fi

if [ ! -z "$DUMPDIR" ]
   then
     if [ -d "$DUMPDIR" ]
        then
          if [ -w "$DUMPDIR" ]
             then
               OraExpDir=$DUMPDIR
               CD=0
             else
               echo "${COLOR_RED}ERROR : The specified DUMPDIR=$DUMPDIR is not a writable directory.\n${COLOR_DEFAULT}"
               CD=1
          fi
        else
          echo "${COLOR_RED}ERROR : The specified DUMPDIR=$DUMPDIR is not a directory.\n${COLOR_DEFAULT}"
          CD=1 
     fi
   else
    CD=0
fi

if [ -z "$RETENTION" ]
   then
     CR=0
   else
     case "$RETENTION" in
       1|2|3|4|5|6|7|8|9|10|11|12|13|14|15|16|17|18|19|20)
          CR=0
          ;;
       *) echo "${COLOR_RED}ERROR : The --retention optional parameter value must be between 1 and 20.\n${COLOR_DEFAULT}"
          CR=1
          ;;
     esac
fi

if [ -z "$COMPRESS" ]
   then
     COMPRESS=N
     CZ=0
   else
     if [ "$COMPRESS" = "Y" -o "$COMPRESS" = "N" ]
        then
          CZ=0
        else
          echo "${COLOR_RED}ERROR : The --compress optional parameter value must be Y or N [Default: Y].\n${COLOR_DEFAULT}"
          CZ=1
     fi
fi

if [ -z "$VERSION" ]
   then
     VERSION=COMPATIBLE
     CV=0
   else
     case "$VERSION" in
       10.2|11.1|11.2|12.1|12.2)
          CV=0
          ;;
       *) echo "${COLOR_RED}ERROR : The --version optional parameter value must be 10.2 or 11.1 or 11.2 or 12.1 or 12.2.\n${COLOR_DEFAULT}"
          CV=1
          ;;
     esac
fi

case "-${CI}-${CM}-${CP}-${CC}-${CN}-${CD}-${CR}-${CZ}-${CV}-" in
     -0-0-0-0-0-0-0-0-0-) ;;
     *1*) ora_show_usage ; exit 1;;
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

# Oracle expdp Check

if [ ! -x ${OraExpdpPath} ]
   then
     echo "${COLOR_RED}\nERROR : The binary Export Datapump ${OraExpdpPath} is not executable.\n${COLOR_DEFAULT}"
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
     ExpDumpFile="${OraExpDir}/`grep DUMPFILE= $PARFILE | cut -d= -f2`"
     if [ -r ${ExpDumpFile} ]
        then
          echo "${COLOR_RED}\nERROR : The Export Dump File ${ExpDumpFile} in Parameter File already exists.\n${COLOR_DEFAULT}"
          exit 1
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
echo "${COLOR_GREEN}Jobs List in $ORACLE_SID database :\n${COLOR_DEFAULT}"
${OraSqlplusPath} -s "${OraConnect}" <<ENDLJ
SET LINESIZE 110
WHENEVER SQLERROR EXIT 1;
COL owner_name format a10
COL job_name format a25
COL operation format a10
COL job_mode format a10
COL state format a15
SELECT owner_name, job_name, operation, job_mode, state, degree, attached_sessions 
  FROM dba_datapump_jobs;
COL message format a50
SELECT sid, serial#, round(sofar/totalwork*100,2) pct_completed, message
  FROM v\$session_longops 
 WHERE sofar <> totalwork 
   AND opname like '${JobNamePrefix}_%'
ORDER BY target, sid; 
EXIT 0
ENDLJ
   exit $?
fi

# List Schemas

if [ "$LISTSCHEMAS" = "Y" ]
   then
     ora_instance_status
     if [ $? -ne 0 -a $? -ne 2 ]
        then
          echo "${COLOR_RED}\nERROR : ${MsgIs}\n${COLOR_DEFAULT}"
          exit 1
     fi
echo "${COLOR_GREEN}Application Schemas List in $ORACLE_SID database :\n${COLOR_DEFAULT}"
${OraSqlplusPath} -s "${OraConnect}" <<ENDLS
SET LINESIZE 80 
WHENEVER SQLERROR EXIT 1;
SELECT distinct owner "SCHEMAS"
  FROM dba_objects 
 WHERE object_type = 'TABLE' 
   AND owner not in ('SYS', 'SYSTEM', 'PERFSTAT', 'DBSNMP', 'OUTLN', 'ORACLE_OCM', 'APPQOSSYS', 'OPS\$ORACLE', 'DIP', 'TSMSYS', 'WMSYS', 'EXFSYS','MDSYS','ORDSYS','SI_INFORMTN_SCHEMA','ORDPLUGINS','CTXSYS','ANONYMOUS','XDB','SYSMAN', 'MGMT_VIEW', 'CSMIG', 'GSMADMIN_INTERNAL', 'SQLTXPLAIN', 'SQLTXADMIN')
ORDER BY 1;
EXIT 0
ENDLS
   exit $?
fi

# Kill Orphaned DataPump Export Jobs

if [ "$KILLJOBS" = "Y" ]
   then
     ora_instance_status
     if [ $? -ne 0 ]
        then
          echo "${COLOR_RED}\nERROR : ${MsgIs}\n${COLOR_DEFAULT}"
          exit 1
     fi
     ora_oracle_var ListJobs "job_name from dba_datapump_jobs where job_name like '${JobNamePrefix}_%' and state not in ('RUNNING', 'EXECUTING')" 1>/dev/null 2>&1
     [ -z $ListJobs ] && echo "${COLOR_MAGENTA}\nWARNING : There is no Orphaned DataPump Export Jobs to cleanup in the $SID.\n${COLOR_DEFAULT}" && exit 0
     echo "${COLOR_GREEN}Kill Orphaned DataPump Export Jobs in $ORACLE_SID database :\n${COLOR_DEFAULT}"
     for JobName in $ListJobs
         do
ora_oracle_var OwnerName "owner_name from dba_datapump_jobs where job_name = '${JobName}'" 1>/dev/null 2>&1
${OraSqlplusPath} -s "${OraConnect}" <<ENDKJ
whenever sqlerror exit 1;
drop table ${OwnerName}.${JobName};
exit 0
ENDKJ
         done
     exit 0
fi

# Check OraLogDir directory

if [ ! -d $OraLogDir ]
   then
     echo "${COLOR_CYAN}WARN  : The $OraLogDir directory doesn't exist. The new log file directory is $TmpDir.\n${COLOR_DEFAULT}"
     OraLogDir=$TmpDir
     LogFile=${OraLogDir}/${ScriptName}_${MODE}_${CONTENT}_$Time.log
fi

# Check OraExpDir directory

if [ ! -d $OraExpDir ]
   then
     echo "${COLOR_RED}\nERROR : The $OraExpDir directory doesn't exist.\n${COLOR_DEFAULT}"
     exit 1
fi

# Check Another ExportDP Job on the same SID

NumJobs=`ps -fu $OraOsUser | grep $ScriptName | grep -i sid=$SID | egrep -i "mode=|parfile=" | grep -v grep | wc -l`
if [ "$NumJobs" -gt 1 ]
   then
     echo "${COLOR_RED}\nERROR : An another $ScriptName Job is running on $SID.\n${COLOR_DEFAULT}"
     ps -fu $OraOsUser | grep $ScriptName | grep -i sid=$SID | egrep -i "mode=|parfile" | grep -v grep
     exit 1
fi

[ `uname -s` = "Linux" ] && alias echo='echo -e'

[ -w $LogFile ] && rm -f $LogFile 1>/dev/null 2>&1

echo "LogFile=$LogFile"

ora_banner "$Text" Begin

ora_instance_status
if [ $? -eq 0 ]
   then
     ora_create_dir
     ora_export_dp
     [ $? -gt 0 ] && ora_banner "${Text}" End && exit 1
     ora_control_dp
     if [ $? -eq 0 ]
        then
          if [ "$COMPRESS" = "Y" ]
	     then 
		ora_compress_dp
		RCCompress=$?
		ora_report_dp
		ora_banner "${Text}" End
		if [ $RCCompress -eq 0 ]
                   then
		     [ -w ${HistoryFile} ] && echo "${Time}\t\t${Text}\t\tOK">>${HistoryFile}
                   else
                     [ -w ${HistoryFile} ] && echo "${Time}\t\t${Text}\t\tKO">>${HistoryFile}
                fi
                exit $Rc
            else
                echo
                if [ $PARALLEL -eq 1 ]
                   then
                     ls -al $DmpFile | tee -a $LogFile
                   else
                     ls -al $DmpSFile | tee -a $LogFile
                fi
		ora_report_dp
		ora_banner "${Text}" End
		[ -w ${HistoryFile} ] && echo "${Time}\t\t${Text}\t\tOK">>${HistoryFile}
		exit 0
          fi				
        else
          ora_banner "${Text}" End
          [ -w ${HistoryFile} ] && echo "${Time}\t\t${Text}\t\tNOK">>${HistoryFile}
          exit 1
     fi
   else
     echo ${MsgIs}|tee -a ${LogFile}
     [ -w ${HistoryFile} ] && echo "${Time}\t\t${Text}\t\tNOK">>${HistoryFile}
     ora_banner "${Text}" End
     exit 1
fi

