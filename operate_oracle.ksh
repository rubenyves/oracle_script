#!/bin/ksh

SID_LIST=$(cat /etc/oratab | grep -v "^#" | cut -d ':' -f1)
SID_STR="$(echo $SID_LIST | tr ' ' '|')|ALL"

displayHelp() {
 echo "Usage : ./operate_oracle.sh [action: stop|start|status|clear] [module: inst|lsnr|dbalog|adr|dumps|alert] [SID: $SID_STR]"
}

mountFS() {
  for d in adm a01 e01 s01 u01 u02 u03 u04; do 
    grep "/oradata/$1/$d" /proc/mounts > /dev/null
    if [ $? -ne 0 ]; then 
     echo "Mount /oradata/$1/$d"
     mount /oradata/$1/$d
    fi
  done
  test -d /oradata/$1/u05 && mount /oradata/$1/u05
}

# Main program 

[ $# -lt 3 ] && displayHelp && exit 1

ACTION=${1}
MODULE=${2}
SID=${3}

[ "$ACTION" != "stop" ] && [ "$ACTION" != "start" ] \
&& [ "$ACTION" != "status" ] && [ "$ACTION" != "clear" ] && echo "Invalid action." && displayHelp && exit 1

[ "$MODULE" != "lsnr" ] && [ "$MODULE" != "inst" ] \
&& [ "$MODULE" != "dbalog" ] && [ "$MODULE" != "dumps" ] \
&& [ "$MODULE" != "adr" ] && [ "$MODULE" != "alert" ] \
&& echo "Invalid module." && displayHelp && exit 1

SID_STR="$SID_STR|all"
echo "|$SID_STR|" | grep "|$SID|" > /dev/null
[ $? -ne 0 ] && echo "Invalid SID." &&  displayHelp && exit 1


case $MODULE in 
  inst)
   if [ "$SID" == "all" ] || [ "$SID" == "ALL" ]; then 
    for i in $SID_LIST; do
      test $ACTION == 'start' && mountFS $i
      su - oracle -c "/opt/operating/bin/OperateOracleAll.ksh -${ACTION} instance $i"
    done
   else
    test $ACTION == 'start' && mountFS $SID
    su - oracle -c "/opt/operating/bin/OperateOracleAll.ksh -${ACTION} instance $SID"
   fi
  ;;
  lsnr)
   if [ "$SID" == "all" ] || [ "$SID" == "ALL" ]; then 
    for i in $SID_LIST; do
     su - oracle -c "/opt/operating/bin/OperateOracleAll.ksh -${ACTION} listener LISTENER_$i"
    done
   else
    su - oracle -c "/opt/operating/bin/OperateOracleAll.ksh -${ACTION} listener LISTENER_$SID"
   fi 
  ;;
  *)
   if [ "$SID" == "all" ] || [ "$SID" == "ALL" ]; then
    for i in $SID_LIST; do
     su - oracle -c "/opt/operating/bin/OperateOracleAll.ksh -${ACTION} $MODULE $i"
    done
   else
    su - oracle -c "/opt/operating/bin/OperateOracleAll.ksh -${ACTION} $MODULE $SID"
   fi
   ;;
esac
