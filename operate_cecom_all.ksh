#!/bin/ksh
# @(#):Version:1.1
#--------------------------------------------------------------------------------------------------------------
#   Script : operate_cecom.ksh
#
#   Description : Launch of extraction or scenarii des(activation) for cecom
#
#   V1.0 :  Barel Eloundou        11/08/2021:  Initiale version for application audit trail log extraction from db
#   V2.0 :  Barel Eloundou        26/08/2021:  Extraction of alertes AML and KYC from DB
#   V2.1 :  Barel ELoundou        26/08/2021:  Des(Activation) of weekly or monthly scenarii
#   V2.2 :  Barel ELoundou        19/01/2022:  Mise en place extraction KYC sur periode
#   V2.3 :  Barel ELoundou        18/02/2022:  Déplacement des fichiers CSV, en plus des fichier compressés .GZ
#--------------------------------------------------------------------------------------------------------------


#  Definition of variables
#  -----------------------

# Sourcing the profile
#. ~/.profile

USAGE="usage : $0 -i <oracle_sid> -s <schema> [-d <operation>]"
[[ $# -lt 4 ]] && { echo "$USAGE"; exit 1; }

unset ORACLE_SID
p_day=7
flag_day=0
X=""
Y=""
Z=""

while getopts ":i:s:d:b:e:a:" OPTION
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
                p_schema=$OPTARG
                ;;

        d)
                let p_day=$OPTARG
                flag_day=1
                ;;

        b)
                export X=$OPTARG
		;;
        e)
                export Y=$OPTARG
                ;;

        a)
                export Z=$OPTARG
                ;;

        \?)     echo "Option -$OPTARG inconnue"
                echo "$USAGE"
                exit 1
                ;;
   esac
done

[[ -z "${ORACLE_SID}" ]] && { echo "$USAGE"; exit 1; }
[[ -z "${p_schema}" ]] && { echo "$USAGE"; exit 1; }

TENANT=""
TENANT=$(echo ${ORACLE_SID:3:4})

PLATFORM=""

if [[ $HOSTNAME == "opoba"* ]]; then
        PLATFORM="Production"
	PRODUCT="OBA VITIB"
	MAIL_SENDER="compliance_oba@gos.orange.com"
	SMTP_HOST="10.227.165.3:10054"
fi

if [[ $HOSTNAME == "uaoba"* ]]; then
        PLATFORM="PreProduction"
        PRODUCT="OBA VITIB"
	MAIL_SENDER="pp_compliance_oba@gos.orange.com"
	SMTP_HOST="10.227.165.3:10054"
fi

if [[ $HOSTNAME == "ua0mc"* ]]; then
        PLATFORM="PreProduction"
        PRODUCT="EME VITIB"
	MAIL_SENDER="pp_compliance_eme@gos.orange.com"
	SMTP_HOST="10.227.165.3:10054"
fi

if [[ $HOSTNAME == "op0mc"* ]]; then
        PLATFORM="Production"
        PRODUCT="EME VITIB"
	MAIL_SENDER="compliance_eme@gos.orange.com"
	SMTP_HOST="10.227.165.3:10054"
fi

MODULE="KYCAML"

if [[ ${ORACLE_SID} == "AMLCONF" ]]
then 
	exit 1
fi

if [[ ${ORACLE_SID} == "EMB"* ]]
then
        MODULE="EMBARGO"
		case "${p_day}" in
			 2) domain="alerte_kyc_generation"; exit 1 ;;
			 3) domain="alerte_kyc_stock";      exit 1 ;;
			 4) domain="alerte_aml" ;           exit 1 ;;
			 5) domain="alerte_aml_stock";      exit 1 ;;
			 8) domain="kycrt_horaire" ;        exit 1 ;;
			 9) domain="kycrt_hebdo" ;          exit 1 ;;
			12) domain="alerte_kyc_periode";    exit 1 ;;			 
                        13) domain="alerte_kyc_statut";     exit 1 ;;
			 *) domain="";;
		esac		
else
        MODULE="KYCAML"
fi

DATE=`date +'%Y%m%d%H%M%S'`

case "${p_day}" in
     1) domain="app_log_syslog";        SPOOLLOG=/extraction_archive/cecom/${TENANT}_${MODULE}_LOGS.csv ; text="Extraction piste audit applicative" ;;
     2) domain="alerte_kyc_generation"; DATE=`date +'%Y-%m-%d'`; SPOOLLOG=/extraction_archive/cecom/${domain}_${TENANT}_${DATE}.csv ; text="Extraction alertes kyc ";;
     3) domain="alerte_kyc_stock";      DATE=`date +'%Y-%m-%d'`; SPOOLLOG=/extraction_archive/cecom/${domain}_${TENANT}_${DATE}.csv ; text="Extraction alertes kyc en stock" ;;
     4) domain="alerte_aml" ;           DATE=`date +'%Y-%m-%d'`; SPOOLLOG=/extraction_archive/cecom/${domain}_${TENANT}_${DATE}.csv ; text="Extraction alertes aml" ;;
     5) domain="alerte_aml_stock";      DATE=`date +'%Y-%m-%d'`; SPOOLLOG=/extraction_archive/cecom/${domain}_${TENANT}_${DATE}.csv ; text="Extraction alteres aml en stock" ;;
     6) domain="scenarii_hebdo" ;       DATE=`date +'%Y%m%d%H%M%S'`; SPOOLLOG=/extraction_archive/cecom/${domain}_${TENANT}_${DATE}.csv ; text="Activation scenarii hebdomadaire"  ;;
     7) domain="scenarii_mensuel" ;     DATE=`date +'%Y%m%d%H%M%S'`; SPOOLLOG=/extraction_archive/cecom/${domain}_${TENANT}_${DATE}.csv ; text="Activation scenarii mensuel" ;;
     8) domain="kycrt_horaire" ;        DATE=`date +'%Y-%m-%d'`; SPOOLLOG=/extraction_archive/cecom/${domain}_${TENANT}_${DATE}.csv ; text="Extraction kyc real time horaire" ;;
     9) domain="kycrt_hebdo" ;          DATE=`date +'%Y-%m-%d'`; SPOOLLOG=/extraction_archive/cecom/${domain}_${TENANT}_${DATE}.csv ; text="Extraction kyc real time hebdomadaire" ;;
    10) domain="tablespace" ;           DATE=`date +'%Y-%m-%d'`; SPOOLLOG=/extraction_archive/cecom/${domain}_${TENANT}_${MODULE}_${DATE}.csv ; text="Extraction taux occupation tablespace" ;;
    11) domain="backup" ;               DATE=`date +'%Y-%m-%d'`; SPOOLLOG=/extraction_archive/cecom/${domain}_${TENANT}_${MODULE}_${DATE}.csv ; text="Extraction sauvegarde RMAN" ;;
    12) domain="alerte_kyc_periode";    DATE=`date +'%Y-%m-%d'`; SPOOLLOG=/extraction_archive/cecom/${domain}_${TENANT}_${DATE}.csv ; text="Extraction alertes kyc periode ";;
    13) domain="alerte_kyc_statut" ;    DATE=`date +'%Y-%m-%d'`; SPOOLLOG=/extraction_archive/cecom/${domain}_${TENANT}_${DATE}.csv ; text="Extraction alertes kyc statut periode ";;
     *) domain="";;
esac

DBASE=/oradata/$ORACLE_SID

LOG=$DBASE/adm/dbalog/${domain}_${ORACLE_SID}_${DATE}.log

history=/oradata/$ORACLE_SID/adm/dbalog/${ORACLE_SID}_history.log


#================
# Functions
#================

banner()
{
timeb=`date +"%d/%m/%Y %HH%M"`
echo "--------------------------------------------------------------------------------------------------------------------------------"|tee -a $LOG
echo "  ${text}\t$1\t\tDatabase: ${ORACLE_SID}\t\t$2\t\t$var\t$timeb"|tee -a $LOG
echo "--------------------------------------------------------------------------------------------------------------------------------"|tee -a $LOG
}

#-------------------------
# Tracing errors function
#-------------------------
log_msg () {
 echo "$1" | tee -a $LOG
}

log_err()
{
    log_msg "[ERROR] $1"
}

#----------------------------------
# Execute an sql command as sysdba
#----------------------------------
exec_sql_sysdba()
{
SQL_ANSW=$(sqlplus -s  '/as sysdba' << EOF
SET LINESIZE 5000 HEAD OFF PAGESIZE 0 feedback off
   whenever oserror exit 2;
   whenever sqlerror exit 3;
$1
exit
EOF
)
}

#--------------------------------
# Function check database status
#--------------------------------
check_database()
{

exec_sql_sysdba "SELECT open_mode  FROM v\$database;"
v_istatus=`echo "$SQL_ANSW"|egrep "^ORA-|READ|MOUNTED"`

case "$v_istatus" in
     'READ ONLY')  v_msgis="The database ${ORACLE_SID} is read only opened. Open the databse in READ_WRITE mode. Exiting.";     echo $v_msgis |tee -a $LOG;;
     'READ WRITE') v_msgis="The database ${ORACLE_SID} is read write opened.";                                                  echo $v_msgis |tee -a $LOG;;
     'MOUNTED')    v_msgis="The database ${ORACLE_SID} is mounted (not opened). Open the databse in READ_WRITE mode. Exiting."; echo $v_msgis |tee -a $LOG;banner;echo "${DATE}\t\t${text}\t\tKO">>${history};exit 1;;
     *ORA-01507*)  v_msgis="The database ${ORACLE_SID} is not mounted. Open the databse in READ_WRITE mode. Exiting.";          echo $v_msgis |tee -a $LOG;banner;echo "${DATE}\t\t${text}\t\tKO">>${history};exit 1;;
     *ORA-01034*)  v_msgis="The database ${ORACLE_SID} is not available. Open the databse in READ_WRITE mode. Exiting.";        echo $v_msgis |tee -a $LOG;banner;echo "${DATE}\t\t${text}\t\tKO">>${history};exit 1;;
     *ORA-01090*)  v_msgis="Shutdown in progress on database ${ORACLE_SID}. Open the databse in READ_WRITE mode. Exiting.";     echo $v_msgis |tee -a $LOG;banner;echo "${DATE}\t\t${text}\t\tKO">>${history};exit 1;;
     *       )     v_msgis=$istatus ;                                                                                           echo $v_msgis |tee -a $LOG;banner;echo "${DATE}\t\t${text}\t\tKO">>${history};exit 1;;
esac

}

#---------------------------------------------------------
# Function PL/SQL for the calcul of incremental statistics
#---------------------------------------------------------
exec_amlkyc_applog()
{

rm -f $SPOOLLOG

if [ "$(date --date=today +\%H)" == "07" ]
then
        mv /extraction_archive/cecom/*_${TENANT}_*.csv.gz /extraction_archive/cecom/backup ;
        mv /extraction_archive/cecom/*_${TENANT}_*.csv /extraction_archive/cecom/backup ;
fi

echo ${PLATFORM}

sqlplus -s  '/as sysdba' << EOF

SET PAGESIZE 0
SET HEADING OFF
SET FEEDBACK OFF
SET TRIMSPOOL ON
SET LINESIZE 32767
SET NUMWIDTH 17
SET TERMOUT OFF
SET VERIFY OFF
SET ECHO OFF
SET FEED OFF
SET TRIMOUT OFF

WHENEVER SQLERROR  EXIT 1
SPOOL $SPOOLLOG

SELECT  '${PLATFORM}'  ||';'||
        '${TENANT}'    ||';'||
        'KYCAML'  ||';'||
        'GWGBENUT'  ||';'||
        trim(GWGBENUT.ERFASSER) ||';'||
        'USER MANAGEMENT' ||';'||
        trim(GWGBENUT.HIST_KZ) ||';'||
        'success' ||';'||
        'Concerned user : ' || trim(GWGBENUT.LOGINNAME) || '. Profil : '  || trim(GWGBENUT.BENUTZERTYP) ||';'||
        trim(GWGBENUT.HISTVON) ||';'||
        (case when GWGBENUT.HISTBIS='9999' then  GWGBENUT.HISTVON else GWGBENUT.HISTBIS end) ||';'||
        trim(GWGBENUT.HISTBIS) ||';'||
        trim(GWGBENUT.GEPRUEFT_JN) ||';'||
        trim(GWGBENUT.GESPERRT_JN) ||';'||
        trim(GWGBENUT.VIERAP_KZ)
FROM ${ORACLE_SID}.GWGBENUT
WHERE substr(trim(GWGBENUT.HISTVON),1,10)=to_char(sysdate-1/24,'yyyymmddhh24')
UNION ALL
SELECT  '${PLATFORM}'  ||';'||
        '${TENANT}'    ||';'||
        trim(TBLOGINH.PROD) ||';'||
        'TBLOGINH'  ||';'||
        trim(TBLOGINH.LOGIN) ||';'||
        'AUTHENTIFICATION' ||';'||
        trim(TBLOGINH.ACTION) ||';'||
        trim(TBLOGINH.RESULT) ||';'||
        trim(TBLOGINH.KONTEXT) ||';'||
        trim(TBLOGINH.CTIMESTAMP) ||';'||
        trim(TBLOGINH.CTIMESTAMP) ||';'||
        trim(TBLOGINH.CTIMESTAMP) ||';'||
        trim(TBLOGINH.KW_FEHLVERSUCHE) ||';'||
        trim(TBLOGINH.CLIENT_IP) ||';'||
        trim(TBLOGINH.CLIENT_HOST)
FROM ${ORACLE_SID}.TBLOGINH
WHERE substr(trim(TBLOGINH.CTIMESTAMP),1,10)=to_char(sysdate-1/24,'yyyymmddhh24');

SPOOL OFF
exit
EOF
}

exec_aml_alert_stock()
{

sqlplus -s  '/as sysdba' << EOF

set pagesize 0
set heading off
set feedback off
set trimspool on
set linesize 32767
set numwidth 17
set termout off
set verify off
set echo off
set feed off
set trimout off
set long 8000

WHENEVER SQLERROR  EXIT 1
SPOOL $SPOOLLOG

SELECT
               '"SCORING"'
        ||'|'||'"NUMERO_CLIENT"'
        ||'|'||'"PRENOM"'
        ||'|'||'"NOM"'
        ||'|'||'"SEGMENTATION"'
        ||'|'||'"SCORE_TOTAL"'
        ||'|'||'"MONITORING"'
        ||'|'||'"ID_SCENARIO"'
        ||'|'||'"NOM_SCENARIO"'
        ||'|'||'"STATUT"'
as  optional_header_row from  dual ;

SELECT
               '"'||trim(BZ.SCORING)||'"'
        ||'|'||'"'||trim(BZ.NUMERO_CLIENT)||'"'
        ||'|'||'"'||trim(BZ.PRENOM)||'"'
        ||'|'||'"'||trim(BZ.NOM)||'"'
        ||'|'||'"'||trim(BZ.SEGMENTATION)||'"'
        ||'|'||'"'||trim(BZ.SCORE_TOTAL)||'"'
        ||'|'||'"'||trim(BZ.MONITORING)||'"'
        ||'|'||'"'||trim(BZ.ID_SCENARIO)||'"'
        ||'|'||'"'||trim(BZ.NOM_SCENARIO)||'"'
        ||'|'||'"'||trim(BZ.STATUT)||'"' as  csv_data_row
FROM
(
SELECT
                AK.ZEITID AS SCORING,
                GK.KUNDNR AS NUMERO_CLIENT,
                GK.NACHNAME AS PRENOM,
                GK.VORNAME AS NOM,
                GK.KUSY AS SEGMENTATION,
                KB.MONITORENDEJN AS MONITORING,
                GSC.INDIZID AS ID_SCENARIO,
                IND.BEZ AS NOM_SCENARIO,
                CV.VSTTYP AS STATUT,
                MAX(AK.GESAMTSCORE) AS SCORE_TOTAL
  FROM
        ${ORACLE_SID}.GWAKUNDE AK
        LEFT OUTER JOIN   ${ORACLE_SID}.GWGKUNDE GK ON (
                AK.INSTITUTSNR= GK.INSTITUTSNR
                AND AK.KUNDNR= GK.KUNDNR
        )
         LEFT OUTER JOIN  ${ORACLE_SID}.GWGKBEA KB ON (
                KB.KD_KUNDNR = AK.KUNDNR
                AND KB.KD_INSTITUTSNR = AK.INSTITUTSNR
                AND KB.ORGEINHEIT = AK.ORGEINHEIT
                AND KB.HISTBIS = '9999'
        )
        LEFT OUTER JOIN ${ORACLE_SID}.GWGBETR BETR ON (
                BETR.BETRNR = GK.FK_BETRNR
                AND BETR.INSTITUTSNR = GK.INSTITUTSNR
                AND BETR.HISTBIS = '9999'
        )
        LEFT OUTER JOIN ${ORACLE_SID}.CVFAAUFF CA ON (
                CA.KUNDNR = AK.KUNDNR
                AND CA.INSTITUTSNR = AK.INSTITUTSNR
                AND CA.ZEITID = AK.ZEITID
                AND CA.AFA_ORGEINHEIT = AK.ORGEINHEIT
                AND CA.HISTBIS = '9999'
        )
        LEFT OUTER JOIN ${ORACLE_SID}.CVORFALL CV ON (
                CV.INSTITUTSNR = CA.INSTITUTSNR
                AND CV.LFD_NR = CA.VFA_LFD_NR
                AND CV.HISTBIS = '9999'
        )
        JOIN ${ORACLE_SID}.GWAZEIT Z ON(
                GK.HISTVON <= Z.ZEITDAT AND  Z.ZEITDAT < GK.HISTBIS
                AND Z.ZEITID = AK.ZEITID
                AND Z.INSTITUTSNR = AK.INSTITUTSNR
        )
        LEFT OUTER JOIN ${ORACLE_SID}.GWGKURSK GSK ON (
                AK.INSTITUTSNR = GSK.INSTITUTSNR
                AND GSK.KUNDNR = AK.KUNDNR
                AND GSK.ORGEINHEIT = AK.ORGEINHEIT
                AND (GSK.HISTVON <= Z.ZEITDAT AND Z.ZEITDAT < GSK.HISTBIS)
                AND GSK.RIK_GEPRUEFT_JN = 'J'
        )
        LEFT OUTER JOIN ${ORACLE_SID}.GWASCORE GSC ON (
                        GSC.KD_INSTITUTSNR = AK.INSTITUTSNR AND
                        GSC.KD_KUNDNR = AK.KUNDNR AND
                        GSC.ZEITID = AK.ZEITID
    )
        LEFT OUTER JOIN ${ORACLE_SID}.GWGIND IND ON (
                        GSC.KD_INSTITUTSNR = IND.INSTITUTSNR AND
                        GSC.INDIZID = IND.INDIZID AND
                        IND.HISTBIS='9999' AND
                        IND.ANWEND_KZ='A'
    )
WHERE Z.INSTITUTSNR = AK.INSTITUTSNR
    AND Z.ZEITID = AK.ZEITID
    AND GK.INSTITUTSNR = AK.INSTITUTSNR
    AND GK.KUNDNR = AK.KUNDNR
    AND GK.HISTVON <= Z.ZEITDAT AND  Z.ZEITDAT < GK.HISTBIS
    AND (CV.VSTTYP IS NULL OR CV.VSTTYP = ' ' OR CV.VSTTYP = 'IA')
GROUP BY
                AK.ZEITID,
                GK.KUNDNR,
                GK.NACHNAME,
                GK.VORNAME,
                GK.KUSY,
                KB.MONITORENDEJN,
                GSC.INDIZID,
                IND.BEZ,
                CV.VSTTYP
) BZ
 ORDER BY
                BZ.NUMERO_CLIENT;

SPOOL OFF
exit

EOF
}

#------------------
aml_alert()
{

sqlplus -s  '/as sysdba' << EOF

set pagesize 0
set heading off
set feedback off
set trimspool on
set linesize 32767
set numwidth 17
set termout off
set verify off
set echo off
set feed off
set trimout off
set long 8000

WHENEVER SQLERROR  EXIT 1
SPOOL $SPOOLLOG

select
                        '"DATE_DERNIER_SCORING"'
                 ||'|'||'"NUMERO_CLIENT"'
                 ||'|'||'"SCORE_TOTAL"'
                 ||'|'||'"PRENOM"'
                 ||'|'||'"NOM"'
                 ||'|'||'"TYPE_CLIENT"'
                 ||'|'||'"SEGMENTATION"'
                 ||'|'||'"CLASSE_RISQUE"'
                 ||'|'||'"HISTVON"'
                 ||'|'||'"SCORING"'
                 ||'|'||'"SCORE"'
                 ||'|'||'"MATCHSCORE"'
                 ||'|'||'"ID_SCENARIO"'
                 ||'|'||'"NOM_SCENARIO"'
                 ||'|'||'"NUMERO_REFERENCE"'
                 ||'|'||'"DESCRIPTION_DETAILLEE_CAS"'
                 ||'|'||'"HISTBIS"'
                 ||'|'||'"HISTVON"'
                 ||'|'||'"STATUT_PROCEDURE"'
                 ||'|'||'"RESPONSABLE_CAS"'
                 ||'|'||'"COMMENTAIRE_CAS"'
                 ||'|'||'"EDITEUR_CAS"'
                 ||'|'||'"DATE_HEURE_CREATION_CAS"'
                 ||'|'||'"HISTBIS_CAS"'
                 ||'|'||'"HISTVON_CAS"'
as  optional_header_row from  dual ;

SELECT            '"'||trim(AK.LSCOREDAT)||'"'
                ||'|'||'"'||trim(AK.KUNDNR)||'"'
                ||'|'||'"'||trim(AK.GESAMTSCORE)||'"'
                ||'|'||'"'||trim(GK.NACHNAME)||'"'
                ||'|'||'"'||trim(GK.VORNAME)||'"'
                ||'|'||'"'||trim(GK.KU_ART)||'"'
                ||'|'||'"'||trim(GK.KUSY)||'"'
                ||'|'||'"'||trim(GK.RISIKOKLASSE)||'"'
                ||'|'||'"'||trim(GK.HISTVON)||'"'
                ||'|'||'"'||trim(AK.ZEITID)||'"'
                ||'|'||'"'||trim(GSC.SCORE)||'"'
                ||'|'||'"'||trim(GSC.MATCHSCORE)||'"'
                ||'|'||'"'||trim(GSC.INDIZID)||'"'
                ||'|'||'"'||trim(IND.BEZ)||'"'
                ||'|'||'"'||trim(CVO.REFNR)||'"'
                ||'|'||'"'||trim(replace(replace(DBMS_LOB.substr(CVO.FALLBESCHR,4000,1),  CHR(13), ''), CHR(10), ''))||'"'
                ||'|'||'"'||trim(CVO.HISTBIS)||'"'
                ||'|'||'"'||trim(CVO.HISTVON)||'"'
                ||'|'||'"'||trim(CVST.TYP)||'"'
                ||'|'||'"'||trim(CVST.ZUSTAENDIG)||'"'
                ||'|'||'"'||trim(replace(replace(DBMS_LOB.substr(CVST.KOMMENTAR,4000,1),  CHR(13), ''), CHR(10), ''))||'"'
                ||'|'||'"'||trim(replace(replace(CVST.ERFASSER,  CHR(13), ''), CHR(10), ''))||'"'
                ||'|'||'"'||trim(CVST.ERFDATTIME)||'"'
                ||'|'||'"'||trim(CVST.HISTBIS)||'"'
                ||'|'||'"'||trim(CVST.HISTVON)||'"' as  csv_data_row
FROM
                ${ORACLE_SID}.GWAKUNDE AK
                LEFT OUTER JOIN ${ORACLE_SID}.CKUNDE CK ON (
                        CK.INSTITUTSNR = AK.INSTITUTSNR AND
                        CK.KUNDNR = AK.KUNDNR AND
                        CK.HISTBIS='9999'
          )
                LEFT OUTER JOIN ${ORACLE_SID}.GWGKUNDE GK ON (
                        GK.INSTITUTSNR = AK.INSTITUTSNR AND
                        GK.KUNDNR = AK.KUNDNR AND
                        GK.HISTBIS='9999'
          )
                 LEFT OUTER JOIN ${ORACLE_SID}.GWASCORE GSC ON (
                        GSC.KD_INSTITUTSNR = AK.INSTITUTSNR AND
                        GSC.KD_KUNDNR = AK.KUNDNR AND
                        GSC.ZEITID = AK.ZEITID
          )
                  INNER JOIN ${ORACLE_SID}.GWGIND IND ON (
                        GSC.KD_INSTITUTSNR = IND.INSTITUTSNR AND
                        GSC.INDIZID = IND.INDIZID AND
                        IND.HISTBIS='9999' AND
                        IND.ANWEND_KZ='A'
          )
                LEFT OUTER JOIN ${ORACLE_SID}.CVFAAUFF CVV ON (
                        CVV.KUNDNR = CK.KUNDNR AND
                        CVV.INSTITUTSNR = CK.INSTITUTSNR AND
                        CVV.VFA_LFD_NR = CK.VFA_LFD_NR AND
                        CVV.AFA_ORGEINHEIT = AK.ORGEINHEIT AND
                        CVV.ZEITID = AK.ZEITID AND
                        CVV.HISTBIS = '9999'
          )
                LEFT OUTER JOIN ${ORACLE_SID}.CVORFALL CVO ON (
                        CVO.INSTITUTSNR = CVV.INSTITUTSNR AND
                        CVO.LFD_NR = CVV.VFA_LFD_NR AND
                        CVO.HISTBIS = '9999'
          )
                LEFT OUTER JOIN ${ORACLE_SID}.CVST CVST ON (
                        CVST.INSTITUTSNR = AK.INSTITUTSNR AND
                        CVST.INSTITUTSNR = CVV.INSTITUTSNR AND
                        CVST.VFA_LFD_NR = CVV.VFA_LFD_NR AND
                        CVST.HISTBIS='9999'
          )
WHERE   (AK.LSCOREDAT = to_char(sysdate-1, 'yyyymmdd') or substr(CVO.HISTVON,1,8) = to_char(sysdate-1, 'yyyymmdd'))
ORDER BY AK.LSCOREDAT,AK.ZEITID,AK.KUNDNR,CVST.ERFDATTIME;

SPOOL OFF
exit
EOF
}

kyc_alert()
{

sqlplus -s  '/as sysdba' << EOF

set pagesize 0
set heading off
set feedback off
set trimspool on
set linesize 32767
set numwidth 17
set termout off
set verify off
set echo off
set feed off
set trimout off
set long 8000

WHENEVER SQLERROR  EXIT 1
SPOOL $SPOOLLOG

select   '"Valeur_PEP"'
 ||'|'||  '"Valeur_SL"'
 ||'|'||  '"Type_Liste"'
 ||'|'||  '"Nom_Liste"'
 ||'|'||  '"Date_Heure_Controle"'
 ||'|'||  '"HISTBIS"'
 ||'|'||  '"Niveau_Risque"'
 ||'|'||  '"Statut_Pre_Check"'
 ||'|'||  '"Statut_liste"'
 ||'|'||  '"Statut_Post_Check"'
 ||'|'||  '"MSISDN"'
 ||'|'||  '"Nom_Famille"'
 ||'|'||  '"Prenom"'
 ||'|'||  '"Nationalite"'
 ||'|'||  '"Lieu"'
 ||'|'||  '"Statut_Alerte"'
 ||'|'||  '"Utilisateur"'
 ||'|'||  '"Commentaires"'
 ||'|'||  '"Raison"'
-------
as optional_header_row from dual ;


select '"'|| trim(PRESULT.HITVAL_PEP)     ||'"'
||'|'||'"'|| trim(PRESULT.HITVAL_EMB)     ||'"'
||'|'||'"'|| trim(SL_LISTINFO.SL_LISTTYPE)||'"'
||'|'||'"'|| trim(PRESULT.SL_LISTNAME)    ||'"'
||'|'||'"'|| trim(PRESULT.HISTVON)        ||'"'
||'|'||'"'|| trim(PRESULT.HISTBIS)        ||'"'
||'|'||'"'|| trim(PRESULT.RISIKO)         ||'"'
||'|'||'"'|| trim(PRESULT.STATUSBRPRE)    ||'"'
||'|'||'"'|| trim(PRESULT.STATUSSCORING)  ||'"'
||'|'||'"'|| trim(PRESULT.STATUSBRPOST)   ||'"'
||'|'||'"'|| trim(PRESULT.KUNDNR)         ||'"'
||'|'||'"'|| trim(GWGKUNDE.NACHNAME)      ||'"'
||'|'||'"'|| trim(GWGKUNDE.VORNAME)       ||'"'
||'|'||'"'|| trim(GWGKUNDE.NAT_LAND)      ||'"'
||'|'||'"'|| trim(GWGKUNDE.WOHNORT)       ||'"'
||'|'||'"'|| trim(PRESULT.STATUS)         ||'"'
||'|'||'"'|| trim(PRESULT.ERFASSER)       ||'"'
||'|'||'"'|| '"'
||'|'||'"'|| (case when (trim(PRESULT.STATUS)!='check') then ('ID Liste = ' || trim(PRESULT.SL_ID) ||' - Valeur de hit = ' || trim(PRESULT.TREFFERPROZ) || '%') end) ||'"'
------------
as  csv_data_row from ${ORACLE_SID}.PRESULT LEFT OUTER JOIN ${ORACLE_SID}.SL_LISTINFO ON trim(PRESULT.SL_LISTNAME) = trim(SL_LISTINFO.SL_LISTNAME)
LEFT OUTER JOIN ${ORACLE_SID}.GWGKUNDE ON trim(GWGKUNDE.KUNDNR) = trim(PRESULT.KUNDNR) AND trim(GWGKUNDE.HISTBIS) = '9999'
WHERE trim(PRESULT.STATUS) not in ('inconspic') and substr(PRESULT.HISTVON,1,8)=to_char(sysdate-1,'yyyymmdd')
ORDER BY PRESULT.KUNDNR,PRESULT.HISTVON DESC;
SPOOL OFF
exit
EOF
}

kyc_alert_periode()
{

sqlplus -s  '/as sysdba' << EOF

set pagesize 0
set heading off
set feedback off
set trimspool on
set linesize 32767
set numwidth 17
set termout off
set verify off
set echo off
set feed off
set trimout off
set long 8000

WHENEVER SQLERROR  EXIT 1
SPOOL $SPOOLLOG

select   '"Valeur_PEP"'
 ||'|'||  '"Valeur_SL"'
 ||'|'||  '"Type_Liste"'
 ||'|'||  '"Nom_Liste"'
 ||'|'||  '"Date_Heure_Controle"'
 ||'|'||  '"HISTBIS"'
 ||'|'||  '"Niveau_Risque"'
 ||'|'||  '"Statut_Pre_Check"'
 ||'|'||  '"Statut_liste"'
 ||'|'||  '"Statut_Post_Check"'
 ||'|'||  '"MSISDN"'
 ||'|'||  '"Nom_Famille"'
 ||'|'||  '"Prenom"'
 ||'|'||  '"Nationalite"'
 ||'|'||  '"Lieu"'
 ||'|'||  '"Statut_Alerte"'
 ||'|'||  '"Utilisateur"'
 ||'|'||  '"Commentaires"'
 ||'|'||  '"Raison"'
-------
as optional_header_row from dual ;


select '"'|| trim(PRESULT.HITVAL_PEP)     ||'"'
||'|'||'"'|| trim(PRESULT.HITVAL_EMB)     ||'"'
||'|'||'"'|| trim(SL_LISTINFO.SL_LISTTYPE)||'"'
||'|'||'"'|| trim(PRESULT.SL_LISTNAME)    ||'"'
||'|'||'"'|| trim(PRESULT.HISTVON)        ||'"'
||'|'||'"'|| trim(PRESULT.HISTBIS)        ||'"'
||'|'||'"'|| trim(PRESULT.RISIKO)         ||'"'
||'|'||'"'|| trim(PRESULT.STATUSBRPRE)    ||'"'
||'|'||'"'|| trim(PRESULT.STATUSSCORING)  ||'"'
||'|'||'"'|| trim(PRESULT.STATUSBRPOST)   ||'"'
||'|'||'"'|| trim(PRESULT.KUNDNR)         ||'"'
||'|'||'"'|| trim(GWGKUNDE.NACHNAME)      ||'"'
||'|'||'"'|| trim(GWGKUNDE.VORNAME)       ||'"'
||'|'||'"'|| trim(GWGKUNDE.NAT_LAND)      ||'"'
||'|'||'"'|| trim(GWGKUNDE.WOHNORT)       ||'"'
||'|'||'"'|| trim(PRESULT.STATUS)         ||'"'
||'|'||'"'|| trim(PRESULT.ERFASSER)       ||'"'
||'|'||'"'|| '"'
||'|'||'"'|| (case when (trim(PRESULT.STATUS)!='check') then ('ID Liste = ' || trim(PRESULT.SL_ID) ||' - Valeur de hit = ' || trim(PRESULT.TREFFERPROZ) || '%') end) ||'"'
------------
as  csv_data_row from ${ORACLE_SID}.PRESULT LEFT OUTER JOIN ${ORACLE_SID}.SL_LISTINFO ON trim(PRESULT.SL_LISTNAME) = trim(SL_LISTINFO.SL_LISTNAME)
LEFT OUTER JOIN ${ORACLE_SID}.GWGKUNDE ON trim(GWGKUNDE.KUNDNR) = trim(PRESULT.KUNDNR) AND trim(GWGKUNDE.HISTBIS) = '9999'
WHERE trim(PRESULT.STATUS) not in ('inconspic') and (to_date(substr(PRESULT.HISTVON,1,8),'yyyymmdd') between to_date(${X},'yyyymmdd') and to_date(${Y},'yyyymmdd') )
ORDER BY PRESULT.KUNDNR,PRESULT.HISTVON DESC;
SPOOL OFF
exit
EOF
}


kyc_alert_statut()
{

sqlplus -s  '/as sysdba' << EOF

set pagesize 0
set heading off
set feedback off
set trimspool on
set linesize 32767
set numwidth 17
set termout off
set verify off
set echo off
set feed off
set trimout off
set long 8000

WHENEVER SQLERROR  EXIT 1
SPOOL $SPOOLLOG

select   '"Valeur_PEP"'
 ||'|'||  '"Valeur_SL"'
 ||'|'||  '"Type_Liste"'
 ||'|'||  '"Nom_Liste"'
 ||'|'||  '"Date_Heure_Controle"'
 ||'|'||  '"HISTBIS"'
 ||'|'||  '"Niveau_Risque"'
 ||'|'||  '"Statut_Pre_Check"'
 ||'|'||  '"Statut_liste"'
 ||'|'||  '"Statut_Post_Check"'
 ||'|'||  '"MSISDN"'
 ||'|'||  '"Nom_Famille"'
 ||'|'||  '"Prenom"'
 ||'|'||  '"Nationalite"'
 ||'|'||  '"Lieu"'
 ||'|'||  '"Statut_Alerte"'
 ||'|'||  '"Utilisateur"'
 ||'|'||  '"Commentaires"'
 ||'|'||  '"Raison"'
-------
as optional_header_row from dual ;


select '"'|| trim(PRESULT.HITVAL_PEP)     ||'"'
||'|'||'"'|| trim(PRESULT.HITVAL_EMB)     ||'"'
||'|'||'"'|| trim(SL_LISTINFO.SL_LISTTYPE)||'"'
||'|'||'"'|| trim(PRESULT.SL_LISTNAME)    ||'"'
||'|'||'"'|| trim(PRESULT.HISTVON)        ||'"'
||'|'||'"'|| trim(PRESULT.HISTBIS)        ||'"'
||'|'||'"'|| trim(PRESULT.RISIKO)         ||'"'
||'|'||'"'|| trim(PRESULT.STATUSBRPRE)    ||'"'
||'|'||'"'|| trim(PRESULT.STATUSSCORING)  ||'"'
||'|'||'"'|| trim(PRESULT.STATUSBRPOST)   ||'"'
||'|'||'"'|| trim(PRESULT.KUNDNR)         ||'"'
||'|'||'"'|| trim(GWGKUNDE.NACHNAME)      ||'"'
||'|'||'"'|| trim(GWGKUNDE.VORNAME)       ||'"'
||'|'||'"'|| trim(GWGKUNDE.NAT_LAND)      ||'"'
||'|'||'"'|| trim(GWGKUNDE.WOHNORT)       ||'"'
||'|'||'"'|| trim(PRESULT.STATUS)         ||'"'
||'|'||'"'|| trim(PRESULT.ERFASSER)       ||'"'
||'|'||'"'|| '"'
||'|'||'"'|| (case when (trim(PRESULT.STATUS)!='check') then ('ID Liste = ' || trim(PRESULT.SL_ID) ||' - Valeur de hit = ' || trim(PRESULT.TREFFERPROZ) || '%') end) ||'"'
------------
as  csv_data_row from ${ORACLE_SID}.PRESULT LEFT OUTER JOIN ${ORACLE_SID}.SL_LISTINFO ON trim(PRESULT.SL_LISTNAME) = trim(SL_LISTINFO.SL_LISTNAME)
LEFT OUTER JOIN ${ORACLE_SID}.GWGKUNDE ON trim(GWGKUNDE.KUNDNR) = trim(PRESULT.KUNDNR) AND trim(GWGKUNDE.HISTBIS) = '9999'
WHERE trim(PRESULT.STATUS) in (${Z}) and (to_date(substr(PRESULT.HISTVON,1,8),'yyyymmdd') between to_date(${X},'yyyymmdd') and to_date(${Y},'yyyymmdd') )
ORDER BY PRESULT.KUNDNR,PRESULT.HISTVON DESC;
SPOOL OFF
exit
EOF
}

kyc_alert_stock()
{

sqlplus -s  '/as sysdba' << EOF

set pagesize 0
set heading off
set feedback off
set trimspool on
set linesize 32767
set numwidth 17
set termout off
set verify off
set echo off
set feed off
set trimout off
set long 8000

WHENEVER SQLERROR  EXIT 1
SPOOL $SPOOLLOG

select   '"Valeur_PEP"'
 ||'|'||  '"Valeur_SL"'
 ||'|'||  '"Type_Liste"'
 ||'|'||  '"Nom_Liste"'
 ||'|'||  '"Date_Heure_Controle"'
 ||'|'||  '"HISTBIS"'
 ||'|'||  '"Niveau_Risque"'
 ||'|'||  '"Statut_Pre_Check"'
 ||'|'||  '"Statut_liste"'
 ||'|'||  '"Statut_Post_Check"'
 ||'|'||  '"MSISDN"'
 ||'|'||  '"Nom_Famille"'
 ||'|'||  '"Prenom"'
 ||'|'||  '"Nationalite"'
 ||'|'||  '"Lieu"'
 ||'|'||  '"Statut_Alerte"'
 ||'|'||  '"Utilisateur"'
 ||'|'||  '"Commentaires"'
 ||'|'||  '"Raison"'
-------
as optional_header_row from dual ;


select '"'|| trim(PRESULT.HITVAL_PEP)     ||'"'
||'|'||'"'|| trim(PRESULT.HITVAL_EMB)     ||'"'
||'|'||'"'|| trim(SL_LISTINFO.SL_LISTTYPE)||'"'
||'|'||'"'|| trim(PRESULT.SL_LISTNAME)    ||'"'
||'|'||'"'|| trim(PRESULT.HISTVON)        ||'"'
||'|'||'"'|| trim(PRESULT.HISTBIS)        ||'"'
||'|'||'"'|| trim(PRESULT.RISIKO)         ||'"'
||'|'||'"'|| trim(PRESULT.STATUSBRPRE)    ||'"'
||'|'||'"'|| trim(PRESULT.STATUSSCORING)  ||'"'
||'|'||'"'|| trim(PRESULT.STATUSBRPOST)   ||'"'
||'|'||'"'|| trim(PRESULT.KUNDNR)         ||'"'
||'|'||'"'|| trim(GWGKUNDE.NACHNAME)      ||'"'
||'|'||'"'|| trim(GWGKUNDE.VORNAME)       ||'"'
||'|'||'"'|| trim(GWGKUNDE.NAT_LAND)      ||'"'
||'|'||'"'|| trim(GWGKUNDE.WOHNORT)       ||'"'
||'|'||'"'|| trim(PRESULT.STATUS)         ||'"'
||'|'||'"'|| trim(PRESULT.ERFASSER)       ||'"'
||'|'||'"'|| trim(replace(replace(PRESULT.KOMMENTAR, CHR(13), ''), CHR(10), ''))      ||'"'
||'|'||'"'|| (case when (trim(PRESULT.STATUS)!='check') then ('ID Liste = ' || trim(PRESULT.SL_ID) ||' - Valeur de hit = ' || trim(PRESULT.TREFFERPROZ) || '%') end) ||'"'
------------
as  csv_data_row from ${ORACLE_SID}.PRESULT LEFT OUTER JOIN ${ORACLE_SID}.SL_LISTINFO ON trim(PRESULT.SL_LISTNAME) = trim(SL_LISTINFO.SL_LISTNAME)
LEFT OUTER JOIN ${ORACLE_SID}.GWGKUNDE ON trim(GWGKUNDE.KUNDNR) = trim(PRESULT.KUNDNR) AND trim(GWGKUNDE.HISTBIS) = '9999'
WHERE trim(PRESULT.STATUS) not in ('inconspic','release') and trim(PRESULT.HISTBIS)='9999'
ORDER BY PRESULT.KUNDNR,PRESULT.HISTVON DESC;

SPOOL OFF
exit
EOF
}

scenarii_weekly()
{

sqlplus -s  '/as sysdba' << EOF
 SPOOL $SPOOLLOG
 update ${ORACLE_SID}.GWGIND set GUELTAB=to_char(sysdate,'yyyymmdd'), GUELTBIS=to_char(sysdate,'yyyymmdd') where (upper(BEZ) like '%HEBDO%' or upper(BEZ) like '%WEEKLY%') and HISTBIS='9999' and score=10;
 commit;
 spool off
exit
EOF
}

scenarii_monthly()
{

sqlplus -s  '/as sysdba' << EOF
 SPOOL $SPOOLLOG
 update ${ORACLE_SID}.GWGIND set GUELTAB=to_char(sysdate,'yyyymmdd'), GUELTBIS=to_char(sysdate,'yyyymmdd') where (upper(BEZ) like '%MOIS%' or upper(BEZ) like '%MONTHLY%') and HISTBIS='9999' and score=10;
 commit;
 spool off
exit
EOF
}

kycrt_weekly_stock()
{

sqlplus -s  '/as sysdba' << EOF

set linesize 3000  ;
set trimspool on   ;
SET pagesize 0 embedded ON;
set echo off       ;
Set feed off     ;
Set trimout off    ;
SET heading on    ;
set feedback off   ;
set termout off    ;
set verify off     ;
SET TRIMS ON ;
set colsep , ;
col WS_METHOD_NAME format A30;
col REQUEST_TIME_START format A17;
col REQUEST_TIME_END format A17;
col SCORING_TIME_START format A17;
col SCORING_TIME_END format A17;
col RELATING_CUSTOMERS format A25;
col SCORING_TIME_END format A17;
col REQ_START format A10;
col REQ_END format A10;
col SCORING_START format A10;
col SCORING_END format A10;
col JOUR format A10;
col MOIS format A10;
col ANNEE format A4;

WHENEVER SQLERROR  EXIT 1
SPOOL $SPOOLLOG

SELECT WS_METHOD_NAME, REQUEST_TIME_START, REQUEST_TIME_END, RETURNCODE, SCORING_TIME_START, SCORING_TIME_END, RELATING_CUSTOMERS,
        to_char(to_date(substr(REQUEST_TIME_START,1,14),'yyyymmddhh24miss'),'hh24:mi:ss') as REQ_START,
           to_char(to_date(substr(REQUEST_TIME_END,1,14),'yyyymmddhh24miss'),'hh24:mi:ss') as REQ_END,
           24*60*60*(to_date(substr(REQUEST_TIME_END,1,14),'yyyymmddhh24miss') - to_date(substr(REQUEST_TIME_START,1,14),'yyyymmddhh24miss')) as DUREE_REQ,
           to_char(to_date(substr(SCORING_TIME_START,1,14),'yyyymmddhh24miss'),'hh24:mi:ss') as SCORING_START,
           to_char(to_date(substr(SCORING_TIME_END,1,14),'yyyymmddhh24miss'),'hh24:mi:ss') as SCORING_END,
           24*60*60*(to_date(substr(SCORING_TIME_END,1,14),'yyyymmddhh24miss') - to_date(substr(SCORING_TIME_START,1,14),'yyyymmddhh24miss')) as DUREE_SCORING,
           to_char(to_date(substr(REQUEST_TIME_START,1,14),'yyyymmddhh24miss'),'dd/mm/yyyy') as JOUR,
           to_char(to_date(substr(REQUEST_TIME_START,1,14),'yyyymmddhh24miss'),'MONTH') as MOIS,
           to_char(to_date(substr(REQUEST_TIME_START,1,14),'yyyymmddhh24miss'),'yyyy') as ANNEE,
           24*60*60*(to_date(substr(REQUEST_TIME_END,1,14),'yyyymmddhh24miss') - to_date(substr(REQUEST_TIME_START,1,14),'yyyymmddhh24miss')) as DUREE,
SCORING_DIR
FROM ${ORACLE_SID}.WSSTATUS where WS_METHOD_NAME='KycScoreTask' and to_date(substr(REQUEST_TIME_START,1,8),'yyyymmdd') > sysdate-8 order by REQUEST_TIME_START DESC;
SPOOL OFF
exit
EOF
}

kycrt_hourly_stock()
{

sqlplus -s  '/as sysdba' << EOF

set linesize 3000  ;
set trimspool on   ;
SET pagesize 0 embedded ON;
set echo off       ;
Set feed off     ;
Set trimout off    ;
SET heading on    ;
set feedback off   ;
set termout off    ;
set verify off     ;
SET TRIMS ON ;
set colsep , ;
col WS_METHOD_NAME format A30;
col REQUEST_TIME_START format A17;
col REQUEST_TIME_END format A17;
col SCORING_TIME_START format A17;
col SCORING_TIME_END format A17;
col RELATING_CUSTOMERS format A25;
col SCORING_TIME_END format A17;
col REQ_START format A10;
col REQ_END format A10;
col DUREE_REQ format A10;
col SCORING_START format A10;
col SCORING_END format A10;
col DUREE_SCORING format A10;
col JOUR format A13;
col MOIS format A10;
col ANNEE format A4;
col DUREE format A10;


WHENEVER SQLERROR  EXIT 1
SPOOL $SPOOLLOG


SELECT
                WS_METHOD_NAME,
                to_char(to_date(substr(REQUEST_TIME_START,1,14),'yyyymmddhh24miss'),'dd/mm/yyyy hh24') as JOUR,
                RETURNCODE,
                count(*)
FROM
                ${ORACLE_SID}.WSSTATUS
WHERE
                WS_METHOD_NAME='KycScoreTask' and to_date(substr(REQUEST_TIME_START,1,8),'yyyymmdd') >= sysdate-1
GROUP BY
                WS_METHOD_NAME,
                to_char(to_date(substr(REQUEST_TIME_START,1,14),'yyyymmddhh24miss'),'dd/mm/yyyy hh24'),
                RETURNCODE
ORDER BY
                WS_METHOD_NAME,
                to_char(to_date(substr(REQUEST_TIME_START,1,14),'yyyymmddhh24miss'),'dd/mm/yyyy hh24') desc,
                RETURNCODE desc;

SPOOL OFF
exit
EOF
}

tablespace()
{

sqlplus -s  '/as sysdba' << EOF

set pagesize 0
set heading off
set feedback off
set trimspool on
set linesize 32767
set numwidth 17
set termout off
set verify off
set echo off
set feed off
set trimout off
set long 8000
set colsep ,

WHENEVER SQLERROR  EXIT 1
SPOOL $SPOOLLOG

select  '${ORACLE_SID}', to_char(sysdate,'dd/mm/yyyy') as "Date", X.* from 
(
select b.tablespace_name, tbs_size SizeGb, tbs_size-a.free_space UsedGb, trunc(((tbs_size-a.free_space)/tbs_size)*100, 1) UsedGbper
from  (select tablespace_name, round(sum(bytes)/1024/1024/1024 ,2) as free_space
       from dba_free_space
       group by tablespace_name) a,
      (select tablespace_name, sum(bytes)/1024/1024/1024 as tbs_size
       from dba_data_files
       group by tablespace_name) b
where a.tablespace_name(+)= b.tablespace_name
union
SELECT A.tablespace_name , D.gb_total,  (SUM(A.used_blocks * D.block_size) / 1024 / 1024/1024) UsedGb, trunc(((SUM(A.used_blocks * D.block_size) / 1024 / 1024/1024)/D.gb_total)*100,1) UsedGbper
FROM v\$sort_segment A,
(
SELECT to_char(sysdate,'dd/mm/yyyy') as "Date", B.name, C.block_size, SUM (C.bytes) / 1024 / 1024/1024 gb_total
FROM v\$tablespace B, v\$tempfile C
 WHERE B.ts#= C.ts#
  GROUP BY B.name, C.block_size) D
WHERE A.tablespace_name = D.name
GROUP by A.tablespace_name, D.gb_total
 ) X
 order by 3 ;

SPOOL OFF
exit
EOF
}
 
backup()
{

sqlplus -s  '/as sysdba' << EOF

set pagesize 0
set heading off
set feedback off
set trimspool on
set linesize 32767
set numwidth 17
set termout off
set verify off
set echo off
set feed off
set trimout off
set long 8000
set colsep ,

WHENEVER SQLERROR  EXIT 1
SPOOL $SPOOLLOG

select  'INSTANCE','OPERATION','STATUS', 'START_TIME', 'END_TIME', 'OBJECT_TYPE', 'OUTPUT_DEVICE_TYPE' from dual;
select  '${ORACLE_SID}', OPERATION, STATUS, to_char(START_TIME,'DD-MM-YYYY HH24:MI:SS'), to_char(END_TIME,'DD-MM-YYYY HH24:MI:SS'), OBJECT_TYPE, OUTPUT_DEVICE_TYPE
from V\$RMAN_STATUS 
where START_TIME > sysdate - 2 order by START_TIME;

SPOOL OFF
exit
EOF
}


# Compression and backup 30 days 
function getAlert {

  FILESIZE=$(stat -c%s "${2}")

  Loren=${2%????}

  if [[ $FILESIZE -gt 52428800 ]] ;then
     `split -a 1 -d -C 41943040 ${2} ${Loren}`
      cnt=$(ls -lth ${Loren}*|wc -l)
      var=1

      for par in ${Loren}*
         do
	    [[ $par == *.* ]] && continue
            titi=$par
            mv $par $titi'.csv'
	    /usr/bin/gzip $titi'.csv'
 
            var=$((var + 1))
         done
  else
	    /usr/bin/gzip ${2}

  fi

  find /extraction_archive/cecom/backup/ -type f -mtime +30 -name "*.gz" | xargs rm -f
  find /extraction_archive/cecom/backup/ -type f -mtime +30 -name "*.csv" | xargs rm -f
}
                     
#-------------------


var="Begin:"
banner
var="End:"

check_database

sqlcmd="select DATABASE_ROLE from v\$database;"
exec_sql_sysdba "$sqlcmd"

SQL_ERR=$?
if [ $SQL_ERR -ne 0 ] ; then
 log_err "Exec sql command: <$sqlcmd> Error."
 echo "${DATE}\t\t${text}\t\tKO">>${history}
 banner
 exit 1
fi

ROLE_DATABASE=$SQL_ANSW

mv /extraction_archive/cecom/${domain}_${TENANT}_*.csv.gz /extraction_archive/cecom/backup ;
mv /extraction_archive/cecom/${domain}_${TENANT}_*.csv /extraction_archive/cecom/backup ;

case "${p_day}" in
     1) exec_amlkyc_applog ;;
     2) kyc_alert; getAlert ${TENANT} $SPOOLLOG " " ;;
     3) kyc_alert_stock; getAlert ${TENANT} $SPOOLLOG " " ;;
     4) aml_alert; getAlert ${TENANT} $SPOOLLOG " " ;;
     5) exec_aml_alert_stock; getAlert ${TENANT} $SPOOLLOG " " ;;
     6) scenarii_weekly ;;
     7) scenarii_monthly ;;
     8) kycrt_hourly_stock ;;
     9) kycrt_weekly_stock; getAlert ${TENANT} $SPOOLLOG " " ;;
    10) tablespace; getAlert ${TENANT} $SPOOLLOG " " ;;
    11) backup; getAlert ${TENANT} $SPOOLLOG " " ;;
    12) kyc_alert_periode; getAlert ${TENANT} $SPOOLLOG " " ;;
    13) kyc_alert_statut;  getAlert ${TENANT} $SPOOLLOG " " ;;
     *) domain="";;
esac

find /extraction_archive/cecom/backup/ -type f -mtime +30 -name "*.gz"  | xargs rm -f
find /extraction_archive/cecom/backup/ -type f -mtime +30 -name "*.csv" | xargs rm -f

SQL_ERR=$?

if [ ! -s $SPOOLLOG ] ; then
  rm -f $SPOOLLOG
fi

if [ $SQL_ERR -eq 0 ]
then
  if [ "$ROLE_DATABASE" = "PRIMARY" ]; then
    MESS_OK="${text} : ${ORACLE_SID} => OK"
    echo $MESS_OK |tee -a $LOG;
    echo "${DATE}\t\t${text}\t\tOK">>${history}
    banner
    exit 0
  else
    MESS_OK="${text} : DBREF => OK"
    echo $MESS_OK |tee -a $LOG;
    echo "${DATE}\t\t${text}\t\tOK">>${history}
    banner
    exit 0
  fi
else
  if [ "$ROLE_DATABASE" = "PRIMARY" ]; then
    MESS_KO="${text} : ${ORACLE_SID} => KO"
    echo $MESS_KO |tee -a $LOG;
    echo "${DATE}\t\t${text}\t\tKO">>${history}
    banner
    exit 1
  else
    MESS_KO="${text} : DBREF => KO"
    echo $MESS_KO |tee -a $LOG;
    echo "${DATE}\t\t${text}\t\tKO">>${history}
    banner
    exit 1
  fi
fi
