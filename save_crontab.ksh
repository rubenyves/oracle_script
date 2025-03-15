#!/bin/ksh
# @(#):Version:1.2.0
#----------------------------------------------------------------------------------------------------
# Copyright(c) 2005 France Telecom Corporation. All Rights Reserved.
#
# NAME
#    save_crontab.ksh
#
# DESCRIPTION
#    Oracle crontab backup to /oradata/<ORACLE_SID>/adm/dba directory
#
# REMARKS
#
#    This shell script must be run by the owner of Oracle product (oracle user)
#
#    Input parameter :
#         ORACLE_SID --> Instance name
#
#    Output :
#         None 
#
# CHANGE LOGS  
#    Fabrice CHAILLOU (FT/ROSI/DPS/ISS)  - 2005/09/05 - v1.0.0 - Creation
#    Fabrice CHAILLOU (FT/ROSI/DPS/ITE)  - 2007/04/03 - v1.1.0 - Modification
#                     Add ORACLE_SID parameter
#    Fabrice CHAILLOU (FT/NCPI/IBNF/ITE) - 2009/12/08 - v1.1.1 - English Translation
#    Olivier LEVESQUE (FT/OLNC/IBNF/ITE) - 2012/10/08 - v1.2.0 - Modification
#                     Adaptation do Common Bundle
#----------------------------------------------------------------------------------------------------

ORACLE_SID=AMLCONF

[ -z "${ORACLE_SID}" ] && echo "Usage : $0 <ORACLE_SID>" && exit 1

dirbackup=/opt/oracle/operating/log

crontab -l >${dirbackup}/crontab_oracle

if [ $? -eq 0 ]
   then
     echo "save_crontab.ksh : OK"
     exit 0
   else
     echo "save_crontab.ksh : NOK"
     exit 1
fi
