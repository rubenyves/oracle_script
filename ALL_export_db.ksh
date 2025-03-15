#!/bin/ksh
# @(#):Version:1.1
#--------------------------------------------------------------------------------------------------------------
#   Script : ALL_export_db.ksh 
#
#   Description : Launch of export db 
#
#
#   V1.0 :  Akili Zegaoui         31/08/2021:  Initiale version
#   V1.1 :  Akili Zegaoui         04/10/2021:  Only DB on production (oratab_live). 
#--------------------------------------------------------------------------------------------------------------

if [ ! -f /etc/oratab_live ]; then
   echo "/etc/oratab_live file not found !"
   exit 1
fi

for i in $(grep -Ev "^#|^ " /etc/oratab_live); do
   dbn=$(echo $i | awk -F":" '{print $1 }')
   echo Launch : $dbn, check the logfile /oradata/$dbn/adm/dbalog/export_db.log
   echo
   /opt/oracle/operating/bin/export_db.ksh -i $dbn -s $dbn -m $(echo $dbn|cut -c4-7) -t -p 4 -e /extraction_archive 1> /oradata/$dbn/adm/dbalog/export_db.log
done

