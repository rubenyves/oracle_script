#!/bin/ksh
# @(#):Version:1.2
#--------------------------------------------------------------------------------------------------------------
#   Script : Launch Oracle stats 
#
#   Description : Launch of RMAN backups.
#
#
#   V1.0 :  Akili Zegaoui         04/02/2021:  Initiale version
#   V1.1 :  Akili Zegaoui         21/06/2021:  Rewritting based on Oracle config file.
#   V1.2 :  Akili Zegaoui         05/07/2021:  fix bug of the logname 
#--------------------------------------------------------------------------------------------------------------


if [ ! -f /etc/oratab ]; then
   echo "/etc/oratab file not found !"
   exit 1
fi

for i in $(grep -Ev "^#|^ " /etc/oratab); do
   dbn=$(echo $i | awk -F":" '{print $1 }')
   echo Launch : $dbn, check the logfile /oradata/$dbn/adm/dbalog/analyze_incremental_statistics_${dbn}.log
   echo
   /opt/operating/bin/analyze_incremental_statistics.ksh -i $dbn -s $dbn -d 1 1>/oradata/$dbn/adm/dbalog/analyze_incremental_statistics_${dbn}.log
done
