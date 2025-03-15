#!/bin/bash

[ $# -lt 1 ] && echo "Usage: $0 [CLIENT_ID]" && exit 0

NOW=$(date +'%Y%m%d-%H%M')

echo "Start DB restroration for AML$1. Please check out the result in /oradata/AML$1/adm/dbalog/restore_db_${1}_${NOW}.log file."

su - oracle -c "nohup /opt/oracle/operating/bin/restore_db_test.ksh $1 > /oradata/AML$1/adm/dbalog/restore_db_${1}_${NOW}.log &"
