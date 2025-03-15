#!/bin/ksh
# @(#):Version:1.4.0
#----------------------------------------------------------------------------------------------------
# Copyright(c) 2005 France Telecom Corporation. All Rights Reserved.
#
# NOM
#   rman_backup_archivelogs.ksh
#
# DESCRIPTION
#   Sauvegarde rman des fichiers archives logs sans purge apres sauvegarde
#
# REMARQUES
#
#    Ce script doit etre execute par le proprietaire du produit Oracle (compte oracle)
#
#    Parametres en entree : 
#            ORACLE_SID --> nom de l'instance
#
#    En sortie : 
#            Fichier journal /oradata/<SID>/s01/<SID>_rman_backup_arch_jjmmyyyy_hhHmm.log
#
# MODIFICATIONS
#    Fabrice CHAILLOU (FT/DROSI/DPS/ISS) - 07/02/2005 - 1.0.0 - Creation
#    Fabrice CHAILLOU (FT/DROSI/DPS/ISS) - 04/04/2005 - 1.1.0 - Evolution
#    Fabrice CHAILLOU (FT/DROSI/DPS/ISS) - 19/08/2005 - 1.2.0 - Evolution
#    Fabrice CHAILLOU (FT/ROSI/DPS/ITE)  - 11/09/2006 - 1.3.0 - Evolution fonction database_role
#    Adrian Benga (FT/OLNC/IBNF/ITE/ECV) - 24/01/2013 - Evolution 1.4.0
#                                          Prepared for CB standard
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
# Setting environment variables
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
# Testing the database presence
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
     'READ ONLY')  msgis="The database ${ORACLE_SID} is read only opened.\n" ; return 2;;
     'READ WRITE') msgis="The database ${ORACLE_SID} is read write opened.\n"; return 0;;
     'MOUNTED')    msgis="The database ${ORACLE_SID} is mounted (not opened).\n" ; return 2;;
     *ORA-01507*)  msgis="The database ${ORACLE_SID} is not mounted.\n" ; return 1;;
     *ORA-01034*)  msgis="The database ${ORACLE_SID} is not available.\n" ; return 1;;
     *ORA-01090*)  msgis="Shutdown in progress on database ${ORACLE_SID}.\n" ; return 1;;
     *       )     msgis=$istatus ; return 1;;
esac
}

#----------------------------------------------------------------------------------------------------
# Return the value of the execution of one Select statement
#     $1 : SQL statement without the word Select
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
# Check the database role : PRIMARY ou PHYSICAL STANDBY
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
# RMAN backup of archive log files  
#----------------------------------------------------------------------------------------------------
rman_backup()
{
target=/
${ORACLE_HOME}/bin/rman target $target nocatalog <<EOF|tee -a $log
run {
     backup archivelog all format='${repsvg}/%d_RMAN_ARCH_%D%M%Y_BS%s_BP%p_%t' tag='$ORACLE_SID ARCH $time';
    }
EOF
}

#----------------------------------------------------------------------------------------------------
# Main
#----------------------------------------------------------------------------------------------------

sid=$1
if [ -z "$sid" ]
   then
     echo "Usage: $0 {ORACLE_SID}"
     echo "The parameter ORACLE_SID is missing. Exit."
     exit 1
fi

set_var_ora

time=`date "+%d%m%Y_%HH%M"`
repsvg=/oradata/${ORACLE_SID}/s01
log=/oradata/${ORACLE_SID}/s01/${ORACLE_SID}_rman_backup_arch_$time.log
history=/oradata/${ORACLE_SID}/adm/dbalog/${ORACLE_SID}_history.log
text="Rman Backup Archives Logs            "

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
database_test
if [ $? -eq 0 ]
   then
     rman_backup
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
