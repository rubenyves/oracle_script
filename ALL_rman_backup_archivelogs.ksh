#!/bin/ksh
# @(#):Version:1.1
#--------------------------------------------------------------------------------------------------------------
#   Script : ALL_rman_backup_archivelogs.ksh 
#
#   Description : Launch of RMAN backups.
#
#
#   V1.0 :  Akili Zegaoui         04/02/2021:  Initiale version
#   V1.1 :  Akili Zegaoui         21/06/2021:  Rewritting based on Oracle config file.
#--------------------------------------------------------------------------------------------------------------

if [ ! -f /etc/oratab ]; then
   echo "/etc/oratab file not found !"
   exit 1
fi

for i in $(grep -Ev "^#|^ " /etc/oratab); do
   dbn=$(echo $i | awk -F":" '{print $1 }')
   echo Launch : $dbn, check the logfile /oradata/$dbn/adm/dbalog/rman_backup_archivelogs.log
   echo
   /opt/operating/bin/rman_backup_archivelogs.ksh $dbn 1> /oradata/$dbn/adm/dbalog/rman_backup_archivelogs.log 
done
