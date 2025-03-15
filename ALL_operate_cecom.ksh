#!/bin/ksh
# @(#):Version:1.1
#--------------------------------------------------------------------------------------------------------------
#   Script : ALL_audit_app_soc.ksh
#
#   Description : Launch of extraction of applicative audit logs for syslog and SOC.
#
#
#   V1.0 :  Barel Eloundou        11/08/2021:  Initiale version
#   V1.1 :  Barel Eloundou        04/10/2021:  Utilisation de /etc/oratab_live pour traiter uniquement les pays en production
#--------------------------------------------------------------------------------------------------------------

if [ ! -f /etc/oratab_live ]; then
   echo "/etc/oratab_live file not found !"
   exit 1
fi

# Main program

[ $# -lt 1 ] && displayHelp

 if [ $1 == audit ]
 then
        for i in $(grep -Ev "^#|^ " /etc/oratab_live); do
           dbn=$(echo $i | awk -F":" '{print $1 }')
           echo Launch : $dbn, check the logfile /oradata/$dbn/adm/dbalog/operate_cecom_audit_${dbn}.log
           echo
           /opt/operating/bin/operate_cecom.ksh -i $dbn -s $dbn -d 1
        done
 fi

 if [ $1 == alert ]
 then
        for i in $(grep -Ev "^#|^ " /etc/oratab_live); do
           dbn=$(echo $i | awk -F":" '{print $1 }')
           echo Launch : $dbn, check the logfile /oradata/$dbn/adm/dbalog/operate_cecom_alert_${dbn}.log
           echo
           /opt/operating/bin/operate_cecom.ksh -i $dbn -s $dbn -d 2
           /opt/operating/bin/operate_cecom.ksh -i $dbn -s $dbn -d 3
           /opt/operating/bin/operate_cecom.ksh -i $dbn -s $dbn -d 4
           /opt/operating/bin/operate_cecom.ksh -i $dbn -s $dbn -d 5
           /opt/operating/bin/operate_cecom.ksh -i $dbn -s $dbn -d 10
           /opt/operating/bin/operate_cecom.ksh -i $dbn -s $dbn -d 11
        done
 fi

 if [ $1 == scen_w ]
 then
        for i in $(grep -Ev "^#|^ " /etc/oratab_live); do
           dbn=$(echo $i | awk -F":" '{print $1 }')
           echo Launch : $dbn, check the logfile /oradata/$dbn/adm/dbalog/operate_cecom_scenarii_${dbn}.log
           echo
           /opt/operating/bin/operate_cecom.ksh -i $dbn -s $dbn -d 6
        done
 fi

 if [ $1 == scen_m ]
 then
        for i in $(grep -Ev "^#|^ " /etc/oratab_live); do
           dbn=$(echo $i | awk -F":" '{print $1 }')
           echo Launch : $dbn, check the logfile /oradata/$dbn/adm/dbalog/operate_cecom_scenarii_${dbn}.log
           echo
           /opt/operating/bin/operate_cecom.ksh -i $dbn -s $dbn -d 7
        done
 fi

 if [ $1 == kycrt_h ]
 then
        for i in $(grep -Ev "^#|^ " /etc/oratab_live); do
           dbn=$(echo $i | awk -F":" '{print $1 }')
           echo Launch : $dbn, check the logfile /oradata/$dbn/adm/dbalog/operate_cecom_kycrt_${dbn}.log
           echo
           /opt/operating/bin/operate_cecom.ksh -i $dbn -s $dbn -d 8
        done
 fi

 if [ $1 == kycrt_w ]
 then
        for i in $(grep -Ev "^#|^ " /etc/oratab_live); do
           dbn=$(echo $i | awk -F":" '{print $1 }')
           echo Launch : $dbn, check the logfile /oradata/$dbn/adm/dbalog/operate_cecom_kycrt_${dbn}.log
           echo
           /opt/operating/bin/operate_cecom.ksh -i $dbn -s $dbn -d 9
        done
 fi

 if [ $1 == tablespace ]
 then
        for i in $(grep -Ev "^#|^ " /etc/oratab_live); do
           dbn=$(echo $i | awk -F":" '{print $1 }')
           echo Launch : $dbn, check the logfile /oradata/$dbn/adm/dbalog/operate_cecom_tablespace_${dbn}.log
           echo
           /opt/operating/bin/operate_cecom.ksh -i $dbn -s $dbn -d 10
	   /opt/operating/bin/operate_cecom.ksh -i $dbn -s $dbn -d 11
        done
 fi

exit 0;

