#!/bin/ksh
#----------------------------------------------------------------------------------------------------
# Copyright(c) 2005 France Telecom Corporation. All Rights Reserved.
#
# NOM
#   audit_file_delete.ksh
#
# DESCRIPTION
#   Suppression des fichiers .aud de plus de 6 mois.
#
# MODIFICATIONS
#    Blanchard N'DJA (ORANGE/MEA/WEA/GOS ) - 12/09/2017 - 1.0.0 - Creation
#    Akili Zegaoui   OLS - 07/04/20202 - 1.0.1 - Multi-Intance Oracle 
#---------------------------
TIME=`date +"%d%m%Y_%H_%M_%S"`

USAGE="usage : $0 <oracle_sid>" 
[[ $# -lt 1 ]] && { echo "$USAGE"; exit 1; }

unset ORACLE_SID
ORACLE_SID=$1

find /oradata/${ORACLE_SID}/adm/adump -type f -mtime 7 > /oradata/${ORACLE_SID}/adm/dbalog/audit_file_delete_$TIME.log
find /oradata/${ORACLE_SID}/adm/adump -type f -mtime 7 -exec rm -rf {} \;
