#!/bin/ksh
# @(#):Version:1.0
#---------------------------------------------------------------------------------------------------#
#   Script : export_db.ksh 
#
#   Description : Export tables, schema, or FULL Oracle database
#
#   V1.0 :  08/04/2020 Akili Zegaoui - Initiale version
#   V1.1 :  20/11/2020 Jerome PEDRO - Modification suite a une evolution du script OraExportDp.ksh (option --output-dir)
#---------------------------------------------------------------------------------------------------#

#Return code
cr_ko=1
cr_ok=0
cr=$cr_ok

# Text Color : 30=Black/Dark grey, 31=Red, 32=Green, 33=Yellow, 34=Blue, 
# 35=Magenta, 36=Cyan, 37=White/light grey, 38="Default" foreground color
# Text Attributes : 0=No, 1=Bold, 2=Normal, 4=Underlined 
COLOR_GREY="\\033[1;30m"
COLOR_RED="\\033[1;31m"
COLOR_GREEN="\\033[1;32m" 
COLOR_YELLOW="\\033[1;33m" 
COLOR_BLUE="\\033[1;34m" 
COLOR_MAGENTA="\\033[1;35m"
COLOR_CYAN="\\033[1;36m"
COLOR_WHITE="\\033[1;37m"
COLOR_DEFAULT="\\033[0;38m"

exptools=OraExportDp.ksh
OraConfTools=OraToolsConfig.yml
DIR_APP=$(dirname $0)

USAGE="Usage : $0 -i <oracle_sid> -s <schema> <-m tenant name> [-e <extract_archive directory>] [-t (pre-defined tables export)] [<-p X (parallel degree)>] [<-c y|n (compression : y default)>]" 
help  () {
echo "\nExport database tools (on /oradata/ORACLE_SID/e01 standard directory OR /oradata/EME/e01/SAML for EME)" 
echo "\t -i <oracle_sid> : Mandatory : ORACLE_SID   ; example : -i SAML"
echo "\t -s <schema>     : Mandatory : Oracle Schema; example : -s AMLCI01"
echo "\t -m <tenant name>: Mandatory : Tenant name  ; example : -m CI01"
echo "\t -e              : Optional  : Extraction archive directory : -e /extraction_archive_pp (pprod env), default value is /extaction_archive" 
echo "\t -t              : Optional  : default=FULL       : Predefined tables to export (GWGKUNDE,GWGKONTO,GWGTRANS,GWGSTAT); example : -t"
echo "\t -p              : Optional  : default=NoParallel : Parallelism degree; example : -p 8" 
echo "\t -c              : Optional  : default=Yes        : Compress the dumpfiles; example : -c y"
echo ""
echo " \nExport a FULL schema compressed (default) in parallel 8" 
echo " \t$0 -i SAML -s AMLCI01 -m CI01 -p 8 -e /extraction_archive_pp"
echo " \nExport the list of predefined tables of a schema compressed (default) in parallel 8"
echo " \t$0 -i SAML -s AMLCI01 -m CI01 -t -p 8 -c y -e /extraction_archive_pp"
}

[[ $# -lt 6 ]] && { echo "$USAGE"; help; exit $cr_ko; } 
   
unset ORACLE_SID
flag_c=y
flag_t=0
DEG_PAR=
while getopts ":i:s:m:p:c:te:" OPTION
do
   case "$OPTION" in
        i)      
               export ORACLE_SID=$OPTARG
               os=`uname -a | awk '{print $1}'`
               if [ ${os} = 'SunOS' ]
                  then
                    ORATAB=/var/opt/oracle/oratab
                  else
                    ORATAB=/etc/oratab
               fi
               export ORACLE_HOME=`grep ${ORACLE_SID} ${ORATAB} | awk -F: '{print $2}'`
               export PATH=${ORACLE_HOME}/bin:${PATH}
                ;;

        s)      
                l_schema=$OPTARG
                ;;

        m)      
                l_tenant=$OPTARG
                ;;

        c)      
                flag_c=$OPTARG
                ;;

        p)      
                let DEG_PAR=$OPTARG
                ;;

        t)
                flag_t=1 
                ;;

        e)
                arc_fs=$OPTARG 
                ;;

        \?)     echo "Option -$OPTARG inconnue"
                echo "$USAGE"
                help
                exit $cr_ko 
                ;;
   esac
done

[[ -z "$ORACLE_SID" ]] && { echo "The parameter ORACLE_SID is missing." ; help; exit $cr_ko; } 
[[ -z "$l_schema"   ]] && { echo "The parameter SCHEMA is missing." ; help; exit $cr_ko; } 
[[ -z "$l_tenant"   ]] && { echo "The parameter TENANT is missing." ; help; exit $cr_ko; } 

if [ -z "${arc_fs}" ]; then
  arc_fs=/extraction_archive
  echo "/extraction_archive is the default directory !"
fi
if [ ! -d ${arc_fs} ]; then
   echo "$COLOR_RED ERROR : $arc_fs directory doesn't exists ! $COLOR_DEFAULT"; help; exit $cr_ko; 
fi 

DIR_APP=/opt/oracle/operating/bin
exptools=${DIR_APP}/OraExportDp.ksh
ScriptName=$(basename $0 .ksh)
LOG_APP=/oradata/${ORACLE_SID}/adm/dbalog
list_tbl=${l_schema}.GWGKUNDE,${l_schema}.GWGKONTO,${l_schema}.GWGTRANS,${l_schema}.GWGSTAT
OraExpDir=$(grep -w "^OraExpDir" ${DIR_APP}/${OraConfTools} | awk '{print $2}')
dir_exp=${arc_fs}/bdd
arc_dir=${arc_fs}/bdd
output=${dir_exp}/${ORACLE_SID}_${l_schema}_exportdp.txt

if [ -f $output ]; then
   rm -f $output
   if [ $? -ne 0 ];  then
      echo " Critical:  Can't remove $output file !!"; exit 1;
   fi
fi

typeset -l lsch=${l_schema}
Time=$(date "+%Y%m%d_%H%M%S")
LogFile=${LOG_APP}/${ScriptName}_${lsch}_${Time}.log 
touch $LogFile

LOG_SEP=";"
log_f_msg_i () {
echo "$(date '+%d/%m/%Y %H:%M:%S')${LOG_SEP}$1" | tee -a $LogFile
}

#----------------------------------------------------------------------------------------------------
# Display function
#----------------------------------------------------------------------------------------------------
ora_banner()
{
Timeb=$(date +"%d/%m/%Y %HH%M")
echo "${COLOR_BLUE}-----------------------------------------------------------------------------------------------------${COLOR_DEFAULT}"|tee -a ${LogFile}
echo "${COLOR_WHITE}  \t\tDatabase: ${ORACLE_SID}\t\t$1:\t${Timeb}${COLOR_DEFAULT}"|tee -a ${LogFile}
echo "${COLOR_BLUE}-----------------------------------------------------------------------------------------------------${COLOR_DEFAULT}"|tee -a ${LogFile}
}

ora_banner "Begin"
log_f_msg_i "Arguments : $*"

if [ ! -f $exptools ]; then 
   log_f_msg_i "${COLOR_RED} $exptools not found ! ${COLOR_DEFAULT}"
   cr=$cr_ko 
else
   log_f_msg_i "$exptools Exists"

   list_arg=" --sid=$ORACLE_SID --schemas=$l_schema"
   [[ $flag_c = "y" ]] && { list_arg=${list_arg}" --compress=Y"; }  
   [[ ! -z "$DEG_PAR" ]] && { list_arg=${list_arg}" --parallel=$DEG_PAR"; }  

   if [ $flag_t -eq 0 ];  then

      prex_t="T0-"
      list_arg=${list_arg}" --mode=SCHEMAS"
      log_f_msg_i "Start : $exptools $list_arg" 
      $exptools $list_arg
      expcr=$?

   else

      list_arg=${list_arg}" --mode=TABLES --tables=$list_tbl"
      log_f_msg_i "Start : $exptools $list_arg" 
      $exptools $list_arg
      expcr=$?

   fi 
fi

echo  expcr=$expcr
echo $exptools $list_arg
full_arc_dir=${arc_dir}/${l_tenant}/${l_schema}/$(date "+%Y-%m")
full_arc_file=${full_arc_dir}/${prex_t}${ORACLE_SID}_${l_schema}-$(date "+%Y%m%d_%H%M").tgz
explog=$(ls -1t ${dir_exp}/*.log | head -1)
exprep=$(ls -1t ${dir_exp}/*.rep | head -1)
grep .dmp.gz $exprep | awk -F '/e01/' '{ print $2 }' > $output
echo $(basename $explog) >> $output
echo $(basename $exprep) >> $output
NB_ORA=$(grep ORA- $explog| wc -l)

# Check export return code
if [ $expcr -eq 0 ]; then
   if [ $NB_ORA -eq 0 ]; then
      log_f_msg_i "The Export completed successfully !"

      # Creation of the tar file
         cd ${dir_exp}
         mkdir -p ${full_arc_dir}
         tar -czvf ${full_arc_file} -T $output
         if [ $? -eq 0 ]; then
            log_f_msg_i "${full_arc_file} created successfully !"
            cp -pv $explog $full_arc_dir
            for i in $(cat $output); do
               rm -f ${dir_exp}/$i
            done
            rm -f $output
         
         else
         
            log_f_msg_i "${full_arc_file} created with errors !!!"
            cr=$cr_ko
         
         fi
         
   else
      log_f_msg_i "The Export completed with errors !"
      cr=$cr_ko
   fi
else
      log_f_msg_i "The Export completed with errors !"
      cr=$cr_ko
fi

if [ $cr -eq $cr_ok ]; then
   log_f_msg_i "Script completed successfully !"
else
  log_f_msg_i "${COLOR_RED} The script completed with errors ! ${COLOR_DEFAULT}"
fi
log_f_msg_i "retcode=$cr"

echo "Check the logfile : ${LogFile}"
ora_banner "End"
exit $cr
