#!/bin/ksh
# @(#):Version:1.4.0
#----------------------------------------------------------------------------------------------------------
# Copyright(c) 2005 France Telecom Corporation. All Rights Reserved.
#
# NOM
#    rman.ksh
#
# DESCRIPTION
#    Gestion des sauvegardes oracle via l'outil Recovery Manager
#
# REMARQUES
#
#    Ce script doit etre execute par le proprietaire du produit Oracle (compte oracle)
#
#    Pre-requis : 
#       L'environnement oracle doit respecter les normes oracle pour serveur unix FT V4
#
#    Parametres en entree : 
#       ORACLE_SID --> nom de l'instance
#
#    Parametres en sortie : 
#       Neant
#
# MODIFICATIONS
#    Fabrice CHAILLOU (FT/ROSI/DPS/ISS) - 07/07/2005 - 1.0.0 - Creation
#    Fabrice CHAILLOU (FT/ROSI/DPS/ISS) - 19/07/2005 - 1.1.0 - Ajout choix 11 et 12 (reporting)
#    Fabrice CHAILLOU (FT/ROSI/DPS/ITE) - 11/09/2006 - 1.2.0 - Evolution de update config
#    Fabrice CHAILLOU (FT/ROSI/DPS/ITE) - 09/01/2007 - 1.3.0 - Evolution de update config
#    Adrian Benga (FT/OLNC/IBNF/ITE/ECV) - 24/01/2012 - Evolution 1.4.0
#                                          Prepared for CB standard
#----------------------------------------------------------------------------------------------------------
set +x

if [ `uname -s` = "Linux" ]
   then                    
     alias echo='echo -e'  
fi                         

#----------------------------------------------------------------------------------------------------
# Setting environment variables
#----------------------------------------------------------------------------------------------------
set_oracle_env()
{
os=`uname -a | awk '{print $1}'`
if [ $os = 'SunOS' ]
   then
     ORATAB=/var/opt/oracle/oratab
   else
     ORATAB=/etc/oratab
fi
export ORACLE_BASE=/opt/oracle
export ORACLE_TERM=vt100
export ORACLE_HOME=`grep ${ORACLE_SID} $ORATAB | awk -F: '{print $2'}`
export PATH=${ORACLE_HOME}/bin:$PATH:/usr/ccs/bin:/etc:/usr/openwin/bin:/usr/local/bin
export LD_LIBRARY_PATH=${ORACLE_HOME}/lib:/lib:/usr/lib
export ORA_NLS33=${ORACLE_HOME}/ocommon/nls/admin/data
export NLS_LANG=AMERICAN_AMERICA.WE8ISO8859P15
return 0
}

#----------------------------------------------------------------------------------------------------
# Check database state
#----------------------------------------------------------------------------------------------------
database_test()
{
CDE=`${ORACLE_HOME}/bin/sqlplus -s /nolog<<-FINIS
connect / as  sysdba
set head off
select open_mode from v\\$database;
exit
FINIS`
istatus=`echo "$CDE"|egrep "^ORA-|READ|MOUNTED"`
case "$istatus" in
     'READ ONLY')  msgis="The database ${ORACLE_SID} is read only opened." ; return 0;;
     'READ WRITE') msgis="The database ${ORACLE_SID} is read write opened."; return 0;;
     'MOUNTED')    msgis="The database ${ORACLE_SID} is mounted (not opened)." ; return 0;;
     *ORA-01507*)  msgis="The database ${ORACLE_SID} is not mounted." ; return 1;;
     *ORA-01034*)  msgis="The database ${ORACLE_SID} is not available." ; return 1;;
     *ORA-01090*)  msgis="Shutdown in progress on database ${ORACLE_SID}." ; return 1;;
     *       )     msgis=$istatus ; return 1;;
esac
return 0
}

#----------------------------------------------------------------------------------------------------
# Display RMAN configuration : values of different parameters 
#----------------------------------------------------------------------------------------------------
rman_show_config()
{
target=/
${ORACLE_HOME}/bin/rman target $target nocatalog <<EOF
run {
    show all;
    }
EOF

${ORACLE_HOME}/bin/sqlplus -s /nolog<<-FIN
connect / as  sysdba
set head on feed off pages 66 term on ver off linesize 132 timing off
alter session set nls_date_format = 'DD/MM/YYYY HH24:MI:SS';
Prompt
Prompt V\$BLOCK_CHANGE_TRACKING
col filename format a70
select status, filename, bytes from v\$block_change_tracking;
FIN
return 0
}

#----------------------------------------------------------------------------------------------------
# Update RMAN configuration
#----------------------------------------------------------------------------------------------------
rman_update_config()
{
echo " Retention Policy (days) ? : \c";
read RET;
case "$RET" in
      [1-9]*) ./rman_update_config.ksh $ORACLE_SID $RET ; return $? ;;
        *) echo "\nInvalid Retention !" ; return 1;;
esac
}

#----------------------------------------------------------------------------------------------------
# Display the list of available backups which are finished
#----------------------------------------------------------------------------------------------------
list_backup()
{
target=/
${ORACLE_HOME}/bin/rman target $target nocatalog <<EOF
    list backup;
EOF
return 0
}

#----------------------------------------------------------------------------------------------------
# Display the RMAN backups ongoing and their progress
#----------------------------------------------------------------------------------------------------
backup_status()
{
${ORACLE_HOME}/bin/sqlplus -s /nolog<<-FINBS
connect / as  sysdba
set head on feed off pages 66 term on ver off linesize 132 timing off
alter session set nls_date_format = 'DD/MM/YYYY HH24:MI:SS';

Prompt
Prompt V\$SESSION et V\$PROCESS

col sid heading "SID" format 9999
col serial# heading "SERIAL#" format 99999
col program heading "PROGRAMME" format a30
col username heading "DB USER" format a10
col client_info format a25
col spid heading "PID"
col osuser heading "OS USER" format a10

select s.sid, s.serial#, s.username, s.client_info, s.osuser, p.spid, s.status, s.program
  from v\$session s, v\$process p
 where s.program like 'rman@%'
   and s.paddr = p.addr
order by 1, 2, 3
;

Prompt
Prompt V\$SESSION_LONGOPS

col units format a7

select sid, serial#, start_time, elapsed_seconds, 
       time_remaining, units, context, sofar, totalwork,
       round(sofar/totalwork*100,2) "%COMPLETED",
       100-round(sofar/totalwork*100,2) "%LEFT"
  from v\$session_longops
 where opname like 'RMAN%' 
   and opname not like '%aggregate%'
   and totalwork != 0 
   and sofar <> totalwork ;

Prompt
Prompt V\$BACKUP_SYNC_IO

col sess heading "SID-SERIAL" format a10 
col filename format a50
col device_type format a10
col status format a12
col type format a10
col total heading "SIZE" format a10
col bytes heading "BYTES SAVE" format a10
col buffer heading "BUFFER|(SIZE-NB)" format a10
col elapsed heading "ELAPSED TIME" format a12

select i.use_count, i.sid||'-'||i.serial as sess, i.device_type, i.type, i.status, i.filename, i.maxopenfiles
  from v\$backup_sync_io i, v\$session s
 where s.program like 'rman@%'
   and s.status = 'ACTIVE'
   and s.serial# = i.serial
   and s.sid = i.sid
order by i.use_count, i.type
;

Prompt
Prompt V\$BACKUP_ASYNC_IO

select i.use_count, i.sid||'-'||i.serial as sess, i.device_type, i.type, i.status, i.filename, i.maxopenfiles
  from v\$backup_async_io i, v\$session s
 where s.program like 'rman@%'
   and s.status = 'ACTIVE'
   and s.serial# = i.serial
   and s.sid = i.sid
order by i.use_count, i.type
;

col filename format a25

select i.filename, i.total_bytes/(1024*1024)||' Mo' as total, i.bytes/(1024*1024)||' Mo' as bytes,
       i.buffer_size||'-'||i.buffer_count as buffer, 
       i.open_time, i.close_time, i.elapsed_time/100||' s' as elapsed 
  from v\$backup_async_io i, v\$session s
 where s.program like 'rman@%'
   and s.status = 'ACTIVE'
   and s.serial# = i.serial
   and s.sid = i.sid
order by 1
;

FINBS

return 0
}

#----------------------------------------------------------------------------------------------------
# Removing log files older than n days 
#----------------------------------------------------------------------------------------------------
rman_backup_database_incr()
{
echo "     Level (0 or 1) ? : \c";
read LEVEL;
case "$LEVEL" in
      0) ./rman_backup_database_incr.ksh $ORACLE_SID $LEVEL D; return $? ;;
      1) echo "Cumulative (Y or N) ? : \c";
         read TYPE;
         case "$TYPE" in
             Y) ./rman_backup_database_incr.ksh $ORACLE_SID $LEVEL C ; return $? ;;
             N) ./rman_backup_database_incr.ksh $ORACLE_SID $LEVEL D ; return $? ;;
             *) echo "\nInvalid Type !" ; return 1;;
         esac
         ;;
      *) echo "\nInvalid Level !" ; return 1;;
esac
}

#----------------------------------------------------------------------------------------------------
# Removing archive log files older than n days 
#----------------------------------------------------------------------------------------------------
rman_delete_archivelogs()
{
echo " Retention (days) ? : \c"; 
read RET; 
case "$RET" in
      [1-9]*) ./rman_delete_archivelogs.ksh $ORACLE_SID $RET ; return $? ;;
        *) echo "\nInvalid Retention !" ; return 1;;
esac
}

#----------------------------------------------------------------------------------------------------
# Removing log files older than n days 
#----------------------------------------------------------------------------------------------------
delete_rman_logs()
{
echo " Retention (days) ? : \c";
read RET;
case "$RET" in
      [1-9]*) find /oradata/${ORACLE_SID}/adm/dbalog -name "rman_*.log" -mtime +${RET} -print -exec rm -f {} \; ; return $? ;; 
        *) echo "\nInvalid Retention !" ; return 1;;
esac
}

#----------------------------------------------------------------------------------------------------
# Main
#----------------------------------------------------------------------------------------------------
clear

if [ `id -un` != "oracle" ]
   then
     echo "SHELL MUST BE EXECUTED BY THE ORACLE USER. EXIT."
     exit 1
fi

if [ -z "$ORACLE_SID" ]
   then
     echo "THE PARAMETER ORACLE_SID IS MISSING. EXIT."
     exit 1
fi

set_oracle_env

database_test

if [ $? -eq 1 ]
   then
     echo "${msgis}. EXIT."
     exit 1
fi

while true
do
clear 

cat << FIN_MENU

     RMAN MENU - ORACLE DATABASE ${ORACLE_SID}

     1. Clear  Rman Config
     2. Show   Rman Config
     3. Update Rman Config

     4. Backup Database Full
     5. Backup Database Incremental
     6. Backup Archive Logs

     7. Delete Backups
     8. Delete Archive Logs
     9. Crosscheck Archive Logs 

     10. Delete Rman Logs

     11. List of backups 
     12. Backup Status

     Q. Exit

FIN_MENU

echo "     Choice : \c"
read CHOIX

case $CHOIX in
       1) clear ; ./rman_clear_config.ksh $ORACLE_SID ;;
       2) clear ;   rman_show_config ;;
       3) clear ;   rman_update_config ;;
       4) clear ; ./rman_backup_database_full.ksh $ORACLE_SID ;;
       5) clear ;   rman_backup_database_incr ;;
       6) clear ; ./rman_backup_archivelogs.ksh $ORACLE_SID ;;
       7) clear ; ./rman_delete_backups.ksh $ORACLE_SID ;;
       8) clear ;   rman_delete_archivelogs ;;
       9) clear ; ./rman_crosscheck_archivelogs.ksh $ORACLE_SID ;;
      10) clear ;   delete_rman_logs ;;
      11) clear ;   list_backup ;;
      12) clear ;   backup_status ;;
     q|Q) clear ; exit ;;
     *) echo "\nInvalid Choice !";;
esac

echo "\nPress <RETURN> to continue ..."
read KEY

done
