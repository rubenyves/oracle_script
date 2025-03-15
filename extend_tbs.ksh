#!/bin/ksh 

[ $(whoami) != 'oracle' ] && echo "Please run this script as oracle user" && exit 1
[ $# -lt 4 ] && echo "Usage: $0 [ORACLE_SID] [DATA|INDEX|TMP] [NB EXTENDS] [FILE_SIZE in GB] [Optional: Tablespace directory]" && exit 0

export ORACLE_SID=$1
if [ $2 == "DATA" ]; then 
 TBS_NAME="DATA"
 NB_EXTENSIONS=$3
 FILE_SIZE=$4
 TBS_DIR=/oradata/${ORACLE_SID}/u04
 [ $# -gt 4 ] && TBS_DIR=/oradata/${ORACLE_SID}/$5
 [ ! -d $TBS_DIR ] && echo "Tablespace directory $TBS_DIR not found. Exit." && exit 1

elif  [ $2 == "INDEX" ]; then
 TBS_NAME="INDEX"
 NB_EXTENSIONS=$3
 FILE_SIZE=$4
 if [ -d /oradata/${ORACLE_SID}/u05 ]; then
   TBS_DIR=/oradata/${ORACLE_SID}/u05
 else
   TBS_DIR=/oradata/${ORACLE_SID}/u04
 fi
 [ $# -gt 4 ] && TBS_DIR=/oradata/${ORACLE_SID}/$5
 [ ! -d $TBS_DIR ] && echo "Tablespace directory $TBS_DIR not found. Exit." && exit 1

elif [ $2 == "TMP" ]; then
 TBS_NAME="TMP"
 NB_EXTENSIONS=$3
 FILE_SIZE=$4
 TBS_DIR=/oradata/${ORACLE_SID}/u03/tmp
 [ $# -gt 4 ] && TBS_DIR=/oradata/${ORACLE_SID}/$5/tmp
 [ ! -d  /oradata/${ORACLE_SID}/$5 ] && echo "Tablespace directory /oradata/${ORACLE_SID}/$5 not found. Exit." && exit 1
 [ ! -d $TBS_DIR ] && mkdir -p $TBS_DIR
else
 echo "Usage: $0 [ORACLE_SID] [DATA|INDEX|TMP] [NB EXTENDS] [FILE_SIZE in GB] [Optional: Tablespace directory]"
 exit 0
fi

LOG_FILE=/oradata/${ORACLE_SID}/adm/create/ExtendDbOra.log
SQL_FILE=/oradata/${ORACLE_SID}/adm/create/ExtendDbOra.sql

grep $ORACLE_SID /etc/oratab > /dev/null
test $? -ne 0 && echo "Oracle SID not found in /etc/oratab." && exit 0

if [ $TBS_NAME == "DATA" ]; then
 LAST_INDEX=$(find /oradata/${ORACLE_SID} -name "${ORACLE_SID}_data_*.dbf" -exec basename {} \; | sort | tail -1 | awk -F '_' '{print $3}' | awk -F '.' '{print $1}') 
 [ -z $LAST_INDEX ] && echo "Last index file could not be found. Exit." && exit 0 

 START_INDEX=$(expr $LAST_INDEX + 1)
 END_INDEX=$(expr $LAST_INDEX + $NB_EXTENSIONS)

 echo -n > $SQL_FILE
 for i in $(seq -f "%02g" $START_INDEX $END_INDEX)
 do 
   echo "ALTER TABLESPACE ${ORACLE_SID}_DATA ADD DATAFILE '${TBS_DIR}/${ORACLE_SID}_data_$i.dbf' SIZE ${FILE_SIZE}G;" >> $SQL_FILE
 done
 echo "prompt 'end of extension of DATA tablespace for ${ORACLE_SID}';" >> $SQL_FILE
 echo "exit;" >> $SQL_FILE
 echo "$(date +'%Y-%m-%d %H:%M:%S') ${ORACLE_SID} Extension of DATA Tablespace - NB extensions = $NB_EXTENSIONS - File Size = $FILE_SIZE" >> $LOG_FILE
 nohup sqlplus -L -s / as sysdba @$SQL_FILE >> $LOG_FILE 2>&1 & 
 echo "Extension of DATA tablespace for ${ORACLE_SID} instance in progress. Check out the log at $LOG_FILE"

elif [ $TBS_NAME == "INDEX" ]; then
 LAST_INDEX=$(find /oradata/${ORACLE_SID} -name "${ORACLE_SID}_index_*.dbf" -exec basename {} \; | sort | tail -1 | awk -F '_' '{print $3}' | awk -F '.' '{print $1}')
 [ -z $LAST_INDEX ] && echo "Last index file could not be found. Exit." && exit 0

 START_INDEX=$(expr $LAST_INDEX + 1)
 END_INDEX=$(expr $LAST_INDEX + $NB_EXTENSIONS)

 echo -n > $SQL_FILE
 for i in $(seq -f "%02g" $START_INDEX $END_INDEX)
 do
   echo "ALTER TABLESPACE ${ORACLE_SID}_INDEX ADD DATAFILE '${TBS_DIR}/${ORACLE_SID}_index_$i.dbf' SIZE ${FILE_SIZE}G;" >> $SQL_FILE
 done
 echo "prompt 'end of extension of INDEX tablespace for ${ORACLE_SID}';" >> $SQL_FILE
 echo "exit;" >> $SQL_FILE
 echo "$(date +'%Y-%m-%d %H:%M:%S') ${ORACLE_SID} Extension of INDEX Tablespace - NB extensions = $NB_EXTENSIONS - File Size = $FILE_SIZE" >> $LOG_FILE
 nohup sqlplus -L -s / as sysdba @$SQL_FILE >> $LOG_FILE 2>&1 &
 echo "Extension of INDEX tablespace for ${ORACLE_SID} instance in progress. Check out the log at $LOG_FILE"

elif [ $TBS_NAME == "TMP" ]; then
 LAST_INDEX=$(find /oradata/${ORACLE_SID} -name "*tmp_*.dbf" -exec basename {} \; | sort | tail -1 | awk -F '_' '{print $2}' | awk -F '.' '{print $1}') 
 [ -z $LAST_INDEX ] && echo "Last index file could not be found. Exit." && exit 0

 START_INDEX=$(expr $LAST_INDEX + 1)
 END_INDEX=$(expr $LAST_INDEX + $NB_EXTENSIONS)
 
 echo -n > $SQL_FILE
 for i in $(seq -f "%02g" $START_INDEX $END_INDEX)
 do
   echo "ALTER TABLESPACE TMP ADD TEMPFILE '${TBS_DIR}/tmp_${i}.dbf' SIZE ${FILE_SIZE}G;" >> $SQL_FILE;
 done
 echo "prompt 'end of extension of TMP tablespace for ${ORACLE_SID}';" >> $SQL_FILE
 echo "exit;" >> $SQL_FILE
 echo "$(date +'%Y-%m-%d %H:%M:%S') ${ORACLE_SID} Extension of TMP Tablespace - NB extensions = $NB_EXTENSIONS - File Size = $FILE_SIZE" >> $LOG_FILE
 nohup sqlplus -L -s / as sysdba @$SQL_FILE >> $LOG_FILE 2>&1 &
 echo "Extension of TMP tablespace for ${ORACLE_SID} instance in progress. Check out the log at $LOG_FILE"
fi

