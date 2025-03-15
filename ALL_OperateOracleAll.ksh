#!/bin/ksh
# @(#):Version:1.0
#--------------------------------------------------------------------------------------------------------------
#   Script : ALL_OperateOracleAll.ksh 
#
#   Description : Launch of purge Oracle log 
#
#
#   V1.0 :  Akili Zegaoui         21/06/2021:  Initiale version
#--------------------------------------------------------------------------------------------------------------


if [ ! -f /etc/oratab ]; then
   echo "/etc/oratab file not found !"
   exit 1
fi

for i in $(grep -Ev "^#|^ " /etc/oratab); do
   dbn=$(echo $i | awk -F":" '{print $1 }')
   echo Launch : OperateOracleAll.ksh $dbn
   echo

   /opt/operating/bin/OperateOracleAll.ksh -S -clear dumps $dbn 1>/oradata/$dbn/adm/dbalog/OperateOracleAll_dumps.log 2>&1
   /opt/operating/bin/OperateOracleAll.ksh -S -clear alert $dbn 1>/oradata/$dbn/adm/dbalog/OperateOracleAll_alert.log 2>&1
   /opt/operating/bin/OperateOracleAll.ksh -S -clear listener LISTENER_$dbn 1> /oradata/$dbn/adm/dbalog/OperateOracleAll_listener.log 2>&1
   /opt/operating/bin/OperateOracleAll.ksh -S -clear dbalog $dbn 1>/oradata/$dbn/adm/dbalog/OperateOracleAll_dbalog.log 2>&1
   /opt/operating/bin/OperateOracleAll.ksh -S -clear adr $dbn 1> /oradata/$dbn/adm/dbalog/OperateOracleAll_adr.log 2>&1
done
