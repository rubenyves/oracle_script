#!/bin/ksh
# @(#):Version:1.2
#--------------------------------------------------------------------------------------------------------------
#   Script : gen_crontab.ksh 
#
#   Description : Generate crontab file 
#
#
#   V1.0 :  Akili Zegaoui         21/06/2021:  Initiale version
#   V1.1 :  Akili Zegaoui         24/06/2021:  Removing aide . 
#   V1.2 :  Akili Zegaoui         09/09/2021:  Including ALL_export_db.ksh. 
#--------------------------------------------------------------------------------------------------------------

USAGE="usage : $0 [-r] . -r : Optional option to regenerate the crontab."

flag_r=0
while getopts ":r" OPTION
do
   case "$OPTION" in
        r)
                flag_r=1
                ;;

        \?)     echo "Option -$OPTARG inconnue"
                echo "$USAGE"
                exit 1
                ;;
   esac
done
tmp_crontab=/tmp/crontab_$(hostname)_$(date "+%d%m%y%H%M%S")


echo "
# Crontab backup every hour
0 * * * * (ksh /opt/operating/bin/save_crontab.ksh  1> /opt/oracle/operating/log/save_crontab.log 2>&1)

#Backup audit file while waiting syslog
*/30 * * * * (ksh /opt/oracle/aud.sh)

######################################
# ALL Databases
######################################


# Archiving and deleting oracle files (log, core, audit, track) every day
01 03 * * * (ksh /opt/operating/bin/ALL_OperateOracleAll.ksh 2>&1)

# Collect daily statistics on  schema every day
00 23 * * * (ksh /opt/operating/bin/ALL_analyze_incremental_statistics.ksh 2>&1)
#
# # Hot incremental backup (level 0) + archived logs of the database with RMAN utility every Sunday
00 21 * *  0   (ksh /opt/operating/bin/ALL_rman_backup_database_incr_0.ksh 2>&1)
#
# # RMAN Backup of archived log files every day, except Sunday
00 21 * * 1-6 (ksh /opt/operating/bin/ALL_rman_backup_database_incr_1.ksh 2>&1)
#
# # Delete RMAN backups for repository every day
15 03 * * * (ksh /opt/operating/bin/ALL_rman_delete_backups.ksh 2>&1)
20 00,03,06,9,12,15,18,21 * * * (ksh /opt/operating/bin/ALL_rman_delete_archivelogs.ksh 2>&1)
#
# # RMAN Backup of archives log files every day
20 1,3,5,7,9,11,13,15,17,19 * * * (ksh /opt/operating/bin/ALL_rman_backup_archivelogs.ksh 2>&1)


# Export Data monthly 
00 01 1 * * (ksh /opt/operating/bin/ALL_export_db.ksh 2>&1)

" > $tmp_crontab 

echo "Check the outtput file : $tmp_crontab"

if [ $flag_r -eq 1 ]; then
    crontab -l > $tmp_crontab.save
    echo "Backup the current crontab in $tmp_crontab.save" 
    crontab $tmp_crontab
    if [ $? -eq 0 ]; then
        echo "Updating the crontab ==> OK"
    else
        echo  "Warning : Error durinng updating the crontab." 
    fi 
else
    echo "crontab is NOT updated, choose -r option to update the crontab." 
fi
