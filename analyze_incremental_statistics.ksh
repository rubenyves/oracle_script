#!/bin/ksh
# @(#):Version:1.0.8 
#-----------------------------------------------------------------------------------#
#   Script : analyze_incremental_statistics.ksh 
#   Description : This script selects the tables and executes the statistics during 
#                 the open database
#
#
#   V1.0 :  Alexandre Nestor      - Creation  - 13/03/2015
#
#   V1.1 :  Christophe Hossenlopp - Modification for the addition of the new  
#                                   standard build
#
#   V1.2 :  Christophe Hossenlopp - Adding the execution of the file .profile
#   
#   V1.3 :  Christophe Hossenlopp - Changing the name of the shell. 
#                                 - No suppressing of the log file.
#                                 - Adding the date in the log name
#   V1.4 :  Adrian Benga          - adding history log 
#                                 - adding exist status in function exec_incremental_statistics
#                                 - corrected the error exit message of exec_sql_sysdba 
#                                  (log_err "Exec sql command: <$sqlcmd> Error.") 
#   V1.0.5 : Adrian Benga         - changed version to 3 digits format 1.4 -> 1.0.5
#   
#   V1.0.6 :  Christophe Hossenlopp - Modification of the loop. 
#   V1.0.6E:  Patricia DAMIENS - Modification for EME 
#   V1.0.6F:  Brigitte COPT - integration nouveaux pays OCD + OBF + OSL
#
#   V1.0.7:   Akili Zegaoui - 10/03/2020 :  OBA Project 
#             - New Multi-instance environment. 
#             - New parameters for statistics gathering
#                 - estimate_percent : DBMS_STATS.AUTO_SAMPLE_SIZE
#                 - method_opt : 'FOR ALL COLUMNS SIZE AUTO'
#
#   V1.0.8:   Akili Zegaoui - 18/01/2021 :  Fix slowness access to GUI by gathering stats on 2 tables.
#------------------------------------------------------------------------------------#

#  Definition of variables
#  -----------------------

# Sourcing the profile
#. ~/.profile

USAGE="usage : $0 -i <oracle_sid> -s <schema> [-d <day>]"
[[ $# -lt 4 ]] && { echo "$USAGE"; exit 1; } 

unset ORACLE_SID
p_day=7
flag_day=0
while getopts ":i:s:d:" OPTION
do
   case "$OPTION" in
        i)      
               export ORACLE_SID=$OPTARG
               os=`uname -a | awk '{print $1}'`
               if [ ${os} = 'SunOS' ]
                  then
                    ORATAB=/var/opt/oracle/oratab
                  else
                    ORATAB=/etc/oratab
               fi
               export ORACLE_HOME=`grep ${ORACLE_SID} ${ORATAB} | awk -F: '{print $2}'`
               export PATH=${ORACLE_HOME}/bin:${PATH}
                ;;

        s)      
                p_schema=$OPTARG 
                ;;

        d)
                let p_day=$OPTARG
                flag_day=1
                ;;

        \?)     echo "Option -$OPTARG inconnue"
                echo "$USAGE"
                exit 1
                ;;
   esac
done

[[ -z "${ORACLE_SID}" ]] && { echo "$USAGE"; exit 1; } 
[[ -z "${p_schema}" ]] && { echo "$USAGE"; exit 1; } 

DBASE=/oradata/$ORACLE_SID
DATE=`date "+%d%m%Y_%HH%M"`
LOG=$DBASE/adm/dbalog/results_analyze_incremental_statistics_${ORACLE_SID}_$DATE.log
SPOOLLOG=$DBASE/adm/dbalog/spool_results_analyze_incremental_statistics_${ORACLE_SID}.log
text="Calcul of incremental statistics"
history=/oradata/$ORACLE_SID/adm/dbalog/${ORACLE_SID}_history.log
list_tbl="'GWGKUNDE','PRESULT'"

#================
# Functions
#================

banner()
{
timeb=`date +"%d/%m/%Y %HH%M"`
echo "--------------------------------------------------------------------------------------------------------------------------------"|tee -a $LOG
echo "  analyze_incremental_statistics\t$1\t\tDatabase: ${ORACLE_SID}\t\t$2\t\t$var\t$timeb"|tee -a $LOG
echo "--------------------------------------------------------------------------------------------------------------------------------"|tee -a $LOG
}

#-------------------------
# Tracing errors function
#-------------------------
log_msg () {
 echo "$1" | tee -a $LOG
}

log_err()
{
    log_msg "[ERROR] $1"
}

#----------------------------------
# Execute an sql command as sysdba
#----------------------------------
exec_sql_sysdba()
{
SQL_ANSW=$(sqlplus -s  '/as sysdba' << EOF
SET LINESIZE 5000 HEAD OFF PAGESIZE 0 feedback off
   whenever oserror exit 2;
   whenever sqlerror exit 3;
$1
exit
EOF
)
}

#--------------------------------
# Function check database status
#--------------------------------
check_database()
{

exec_sql_sysdba "SELECT open_mode  FROM v\$database;"
v_istatus=`echo "$SQL_ANSW"|egrep "^ORA-|READ|MOUNTED"`

case "$v_istatus" in
     'READ ONLY')  v_msgis="The database ${ORACLE_SID} is read only opened. Open the databse in READ_WRITE mode. Exiting.";     echo $v_msgis |tee -a $LOG;;
     'READ WRITE') v_msgis="The database ${ORACLE_SID} is read write opened.";                                                  echo $v_msgis |tee -a $LOG;;
     'MOUNTED')    v_msgis="The database ${ORACLE_SID} is mounted (not opened). Open the databse in READ_WRITE mode. Exiting."; echo $v_msgis |tee -a $LOG;banner;echo "${DATE}\t\t${text}\t\tKO">>${history};exit 1;;
     *ORA-01507*)  v_msgis="The database ${ORACLE_SID} is not mounted. Open the databse in READ_WRITE mode. Exiting.";          echo $v_msgis |tee -a $LOG;banner;echo "${DATE}\t\t${text}\t\tKO">>${history};exit 1;;
     *ORA-01034*)  v_msgis="The database ${ORACLE_SID} is not available. Open the databse in READ_WRITE mode. Exiting.";        echo $v_msgis |tee -a $LOG;banner;echo "${DATE}\t\t${text}\t\tKO">>${history};exit 1;;
     *ORA-01090*)  v_msgis="Shutdown in progress on database ${ORACLE_SID}. Open the databse in READ_WRITE mode. Exiting.";     echo $v_msgis |tee -a $LOG;banner;echo "${DATE}\t\t${text}\t\tKO">>${history};exit 1;;
     *       )     v_msgis=$istatus ;                                                                                           echo $v_msgis |tee -a $LOG;banner;echo "${DATE}\t\t${text}\t\tKO">>${history};exit 1;;
esac

}

#---------------------------------------------------------
# Function PL/SQL for the calcul of incremental statistics
#---------------------------------------------------------
exec_incremental_statistics()
{
sqlplus -s  '/as sysdba' << EOF

SET  LINESIZE      150
SET  SERVEROUTPUT  ON
WHENEVER SQLERROR  EXIT 1
SPOOL $SPOOLLOG

alter system set resource_manager_plan='DEFAULT_PLAN' scope=MEMORY;
DECLARE
         object_list   dbms_stats.objecttab;
         idx           NUMBER    default 1;
         v_day         NUMBER := ${flag_day};


   V_TBL DBA_TABLES.TABLE_NAME%TYPE;
   CURSOR curs_tbl IS
   select TABLE_NAME from dba_tables where OWNER='${p_schema}' 
   and TABLE_NAME in (${list_tbl}) and trunc(LAST_ANALYZED)  <= trunc(sysdate-${p_day});

BEGIN

IF  v_day = 1 THEN 

OPEN curs_tbl;
LOOP
   FETCH curs_tbl INTO V_TBL;
   EXIT WHEN NOT curs_tbl%FOUND;
   DBMS_STATS.DELETE_TABLE_STATS(OWNNAME=>'${p_schema}', TABNAME=>V_TBL);
END LOOP;
CLOSE curs_tbl ;

END IF;


  dbms_stats.gather_schema_stats(
        ownname     => '${p_schema}',
        options     => 'LIST AUTO',
--      options     => 'LIST STALE',
--      options     => 'LIST EMPTY',
        objlist     => object_list
    );
  dbms_output.put_line('Tables to be calculated on ${p_schema}: ');  
  FOR  idx IN 1..object_list.count 
  LOOP    
       dbms_output.put_line(
             rpad(object_list(idx).ownname,30)     ||
             rpad(object_list(idx).objtype, 6)     ||
             rpad(object_list(idx).objname,30)     ||
             rpad(object_list(idx).partname,30) 
        );
   
  END LOOP;

  -- On 12c CONCURRENT=True by default.
  --DBMS_STATS.SET_GLOBAL_PREFS('CONCURRENT','TRUE');
  DBMS_STATS.SET_SCHEMA_PREFS('${p_schema}', 'INCREMENTAL','TRUE');
  
   dbms_stats.gather_schema_stats (
      ownname => '${p_schema}',
      estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE,
      method_opt => 'FOR ALL COLUMNS SIZE AUTO',
      DEGREE => DBMS_STATS.AUTO_DEGREE,
      granularity => 'AUTO',
      CASCADE => DBMS_STATS.AUTO_CASCADE,
      options => 'gather auto',
      no_invalidate => DBMS_STATS.AUTO_INVALIDATE,
      obj_filter_list => object_list
      );
   --DBMS_STATS.SET_GLOBAL_PREFS('CONCURRENT','FALSE');

END;
/
alter system reset resource_manager_plan scope=MEMORY;
SPOOL OFF
exit
EOF
}

#-------------------
# Body of the script
#-------------------

var="Begin:"
banner
var="End:"

check_database

sqlcmd="select DATABASE_ROLE from v\$database;"
exec_sql_sysdba "$sqlcmd"

SQL_ERR=$?
if [ $SQL_ERR -ne 0 ] ; then
 log_err "Exec sql command: <$sqlcmd> Error."
 echo "${DATE}\t\t${text}\t\tKO">>${history}
 banner
 exit 1
fi

ROLE_DATABASE=$SQL_ANSW 

exec_incremental_statistics
SQL_ERR=$?

cat $SPOOLLOG >> $LOG ; rm -f $SPOOLLOG

if [ $SQL_ERR -eq 0 ]
then
  if [ "$ROLE_DATABASE" = "PRIMARY" ]; then
    MESS_OK="${text} : ${ORACLE_SID} => OK"
    echo $MESS_OK |tee -a $LOG;
    echo "${DATE}\t\t${text}\t\tOK">>${history}
    banner
    exit 0
  else
    MESS_OK="${text} : DBREF => OK"
    echo $MESS_OK |tee -a $LOG;
    echo "${DATE}\t\t${text}\t\tOK">>${history}
    banner
    exit 0
  fi
else
  if [ "$ROLE_DATABASE" = "PRIMARY" ]; then
    MESS_KO="${text} : ${ORACLE_SID} => KO"
    echo $MESS_KO |tee -a $LOG;
    echo "${DATE}\t\t${text}\t\tKO">>${history}
    banner
    exit 1
  else
    MESS_KO="${text} : DBREF => KO"
    echo $MESS_KO |tee -a $LOG;
    echo "${DATE}\t\t${text}\t\tKO">>${history}
    banner
    exit 1
  fi
fi


