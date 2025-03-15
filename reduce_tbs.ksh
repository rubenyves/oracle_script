#!/bin/ksh

[ $(whoami) != 'oracle' ] && echo "Please run this script as oracle user" && exit 1
[ $# -lt 3 ] && echo "Usage: $0 [ORACLE_SID] [DATA|INDEX|TMP] [NB EXTENDS]" && exit 0

export ORACLE_SID=$1
if [ $2 == "DATA" ]; then
 TBS_NAME="DATA"
 NB_EXTENSIONS=$3
elif  [ $2 == "INDEX" ]; then
 TBS_NAME="INDEX"
 NB_EXTENSIONS=$3
elif [ $2 == "TMP" ]; then
 TBS_NAME="TMP"
 NB_EXTENSIONS=$3
else
 echo "Usage: $0 [ORACLE_SID] [DATA|INDEX|TMP] [NB EXTENDS]"
 exit 0
fi

LOG_FILE=/oradata/${ORACLE_SID}/adm/create/ReduceDbOra.log
SQL_FILE=/oradata/${ORACLE_SID}/adm/create/ReduceDbOra.sql

grep $ORACLE_SID /etc/oratab > /dev/null
test $? -ne 0 && echo "Oracle SID not found in /etc/oratab." && exit 0

TBS_BASE_DIR=/oradata/${ORACLE_SID}

if [ $TBS_NAME == "DATA" ]; then
 LAST_FILES=$(find /oradata/${ORACLE_SID} -name "${ORACLE_SID}_data_*.dbf" -exec basename {} \; | sort -r | head -${NB_EXTENSIONS})
 echo -n > $SQL_FILE
 for f in $LAST_FILES
 do
   FILE=$(find /oradata/${ORACLE_SID} -name $f -type f)
   echo "ALTER TABLESPACE ${ORACLE_SID}_DATA DROP DATAFILE '${FILE}';" >> $SQL_FILE
 done
 echo "prompt 'end of reduction of DATA tablespace for ${ORACLE_SID}';" >> $SQL_FILE
 echo "exit;" >> $SQL_FILE
 echo "$(date +'%Y-%m-%d %H:%M:%S') ${ORACLE_SID} Reduction of DATA Tablespace - NB extensions = $NB_EXTENSIONS" >> $LOG_FILE
 nohup sqlplus -L -s / as sysdba @$SQL_FILE >> $LOG_FILE 2>&1 &
 echo "Reduction of DATA tablespace for ${ORACLE_SID} instance in progress. Check out the log at $LOG_FILE"

elif [ $TBS_NAME == "INDEX" ]; then
 LAST_FILES=$(find /oradata/${ORACLE_SID} -name "${ORACLE_SID}_index_*.dbf" -exec basename {} \; | sort -r | head -${NB_EXTENSIONS})

 echo -n  > $SQL_FILE
 for f in $LAST_FILES
 do
   FILE=$(find /oradata/${ORACLE_SID} -name $f -type f)
   echo "ALTER TABLESPACE ${ORACLE_SID}_INDEX DROP DATAFILE '${FILE}';" >> $SQL_FILE
 done
 echo "prompt 'end of reduction of INDEX tablespace for ${ORACLE_SID}';" >> $SQL_FILE
 echo "exit;" >> $SQL_FILE
 echo "$(date +'%Y-%m-%d %H:%M:%S') ${ORACLE_SID} Reduction of INDEX Tablespace - NB extensions = $NB_EXTENSIONS" >> $LOG_FILE
 nohup sqlplus -L -s / as sysdba @$SQL_FILE >> $LOG_FILE 2>&1 &
 echo "Reduction of INDEX tablespace for ${ORACLE_SID} instance in progress. Check out the log at $LOG_FILE"

elif [ $TBS_NAME == "TMP" ]; then
 LAST_FILES=$(find /oradata/${ORACLE_SID} -name "tmp_*.dbf" -exec basename {} \; | sort -r | head -${NB_EXTENSIONS})

 echo -n > $SQL_FILE
 for f in $LAST_FILES
 do
   FILE=$(find /oradata/${ORACLE_SID} -name $f -type f)
   echo "ALTER TABLESPACE TMP DROP TEMPFILE '${FILE}';" >> $SQL_FILE;
 done
 echo "prompt 'end of reduction of TMP tablespace for ${ORACLE_SID}';" >> $SQL_FILE
 echo "exit;" >> $SQL_FILE
 echo "$(date +'%Y-%m-%d %H:%M:%S') ${ORACLE_SID} Reduction of TMP Tablespace - NB extensions = $NB_EXTENSIONS" >> $LOG_FILE
 nohup sqlplus -L -s / as sysdba @$SQL_FILE >> $LOG_FILE 2>&1 &
 echo "Reduction of TMP tablespace for ${ORACLE_SID} instance in progress. Check out the log at $LOG_FILE"
fi
