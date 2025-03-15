#!/bin/ksh
# @(#):Version:1.3.0
#----------------------------------------------------------------------------------------------------
# Copyright(c) 2005 France Telecom Corporation. All Rights Reserved.
#
# NOM
#    rm_rman_backup.ksh
#
# DESCRIPTION
#    Purge des fichiers sauvegardes RMAN de plus de n jours
#
# REMARQUES
#
#    Ce script doit etre execute par le proprietaire du produit Oracle (compte oracle)
#    La base doit respectee les normes oracle pour serveur unix V4
#
#    Parametres en entree : 
#          ORACLE_SID --> nom de l'instance
#          RETENTION  --> retention en nb de jours 
#
#    En sortie : 
#          Fichier journal /oradata/SID/adm/dbalog/rm_rman_backup_jjmmyyyy_hhHmm.log
#
# MODIFICATIONS
#    Fabrice CHAILLOU (FT/DROSI/DPS/ISS) - 25/01/2005 - Creation
#    Fabrice CHAILLOU (FT/DROSI/DPS/ISS) - 23/04/2006 - Evolution 1.2.0
#                                                       Correction anomalies code retour
#    Adrian Benga (FT/OLNC/IBNF/ITE/ECV) - 24/01/2013 - Evolution 1.3.0
#                                          Prepared for CB standard
#----------------------------------------------------------------------------------------------------
#------------------------------------------------
# Debug mode activation
#------------------------------------------------
set +x

#---------------------------------------------------
# Display function
#---------------------------------------------------
banner()
{
timeb=`date +"%d/%m/%Y %HH%M"`
echo "--------------------------------------------------------------------------------------------------------"|tee -a $log
echo "  $1\t\tDatabase: ${ORACLE_SID}\t\t$2:\t$timeb"|tee -a $log
echo "--------------------------------------------------------------------------------------------------------"|tee -a $log
}

#---------------------------------------------------
# Setting environment variables
#---------------------------------------------------
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
export ORACLE_HOME=`grep ${ORACLE_SID} $ORATAB | awk -F: '{print $2}'`
export PATH=${ORACLE_HOME}/bin:$PATH
}

#---------------------------------------------------
# Main
#---------------------------------------------------

sid=$1
if [ -z "$sid" ]
   then
     echo "The parameter ORACLE_SID is missing. Exit."
     exit 1
fi

ret=$2
if [ -z "$ret" ]
   then
     echo "The parameter RETENTION is missing. Exit."
     exit 1
fi

set_var_ora

time=`date "+%d%m%Y_%HH%M"`
repsvg=/oradata/${ORACLE_SID}/s01
log=/oradata/${ORACLE_SID}/adm/dbalog/rm_rman_backup_$time.log
history=/oradata/${ORACLE_SID}/adm/dbalog/${ORACLE_SID}_history.log
text="Rman Backups Delete ($ret days old)"

if [ `uname -s` = "Linux" ]
   then
     alias echo='echo -e'
fi

if [ -w $log ]
   then
     rm $log
fi

banner "$text" Begin

find ${repsvg} -name "${ORACLE_SID}_rman_*" -mtime +${ret} -print -exec rm -f {} \; | tee -a $log
find ${repsvg} -name "${ORACLE_SID}_RMAN_*" -mtime +${ret} -print -exec rm -f {} \; | tee -a $log

nb_svg=`find ${repsvg} -name "${ORACLE_SID}_RMAN_*" -mtime +${ret} -print | wc -l`
if [ $nb_svg -ge 1 ]
   then
     banner "$text" End
     echo "$time\t\t$text\t\tNOK">>$history
     exit 1
   else
     banner "$text" End
     echo "$time\t\t$text\t\tOK">>$history
     exit 0
fi
