#!/bin/ksh
# @(#):Version:6.4.4
#---------------------------------------------------------------------------------
# Copyright(c) 2012 France Telecom Corporation. All Rights Reserved.
#
# NAME
#    OperateOracleAll.ksh  	(same as ExploiterOracle.ksh for S4D0)
#
# DESCRIPTION
#    Script for start/stop/purge the Oracle Databases
#
# REMARKS
#    This shell script must be executed by oracle
#
#    Prerequisites :
#       The directories of your server must be conformed to the Common Bundle Standard
#       or the S4D0 Standard
#
#    Input Parameters :
#	$0  without arguments access to the menu.
#       $0  with arguments realize the specified action.
#
#    Output :
#       Trace files for each action
#
#---------------------------------------------------------------------------------
#
# CHANGE LOGS
#                    
# 3.0 .....2003 : Reorganization with a menu of PLATON old multiple scripts.
#		  the syntaxes remain the same.
# 3.2 25Mar2004 : Append startup restrict (needed for the export).
# 3.3 23Jul2004 : Append  Jour=   in clear_sqlnet.
# 3.4 02Nov2004 : DBNAME and Xdump$ORACLE_SID
#			In F_prerequis_connect, F_clear_alert, F_clear_sqlnet	
#			compute the DBNAME according  ORACLE_SID and quorum
# 3.5 09Nov2004 : Change numbers in the menu (1r, 1a, 1n, 2 ...)
# 4.0 08Dec2004 : Change syntaxes for the purges.
#			Introduction of the Multi-Instance.
# 4.1 20Dec2004 : Purges : file extention become similar
#			   and retention is 3 and 12 month like the AlertFile.
# 4.2 29Dec2004 : In F_VerifLogMode ; apend *ERR* in the 'case'.
# 4.3 31Jan2005 : Correction : Append 2k when filtering the choices.
#
# 4.5 21nov2005 : Correction : listener_SID become UPPERCASE.
# 4.6 10jan2006 : Append 'sleep 2' after every stop/start.
#		  Suppression of tinaft.
#
# 5.0 24Fev2005 : Change 'base' with 'instance'
#		  Translation of syntaxes to english : start, stop, test, clear ...
#		  In F_test : Append of SUPER_SILENCE : "\t@-" 
#
# 5.1 11Avr2005 : Correction : F_Profile : [ -d $OLDHOME ] when updating the PATH
#		  Remplace 'sqlnet' with 'listener'
#
# 5.2 11Jul2005 : Append des BeginBackup et EndBackup.
#
# 6.0 29sep2005 : Suppression F_prerequis_connect_as_sysdba.
#		  Append the function F_clear_dbalog.
#		  In the menu, Suppressiont of choices 1a, 1n, 1r, t2, t6 
#
# 6.1 24avr2006 : Suppression of BeginBackup of EndBackup (reused in HotCopy)
#
# 6.2 15mai2006 : Compatibility French=>English
#		  this allows et compatibility with the UPROCS dollaru TRF8096.
#
# 6.3 20jul2006 : Translation of every  messages in english.
#		  Presentation of LIST_LIST with LISTENER_ in uppercase
#
# 6.4 20dec2006 : Move the translation just after reading ARGS.
# 6.5 31jan2007 : In F_test_instance : Append the 'restrict' clause.
# 6.6 02mar2007 : Append 'unset ORA_NLS33'
# 6.7 07aou2007 : Append Flag in /exec/FlagBlackOut :
#			Oracle_SID.off and Listener_SID.off
#		  Display ORACLE_HOME in the trace (filtered by "tab@"
#		  Append the l'ORACLE_SID in the name of traces
#			(and suppression of the PID)
#
# 6.8 08nov2007 : The KmBlackout falls in alarme if 2 flags are present
#		  (besause  the icon Listener is in cascade of the icon Instance)
#		  then we introduce an extention in the Flags :
#
#
#        A) STOP Instance => if FlagListener present : then renome to .dual
#			                     absent  : then just create FlagOracle 
#
#        B) START Instance => suppression FlagOracle
#                 According to A , the FlagListener with .dual could exists
#		  so we rename the .dual to .off
#
#        C) STOP Listener => if FlagInstance present : then creation with .dual
#			                     absent  : then creation FlagListener  
#                       
#        D) START Listener => suppress in FlagListener the possible .off and the .dual
# 
# 6.9  22fev2008 : As the KMORA g1g1c2 is the correction of the Blackout problem,
#		   then we suppress all the extention .dual introduced in v6.8.
#		   So the v6.9 become the same as the v6.7.
#
# 6.10 04jun2008 : The FlagBlackout include the name of the listener
#		   in case of a database with several icones ListenerStatus
#
# 6.11 13mar2009 : Maintain the FlagBlackout during the Startup restrict
#		   because it is corresponding to a maintenance session.
#		   and the patrol account can't access the database.
#
# 6.12 30aug2009 : Translation of this CHANGE LOG chapter.
#
# 6.13 25oct2010 : Suppression of the call to ExploiterOracleFct.ksh
#                       (previously, it allowed de beginbck and endbck)
#
#                  Adding "Archive log stop;"  for NOARCH
#                  	(to avoid message ARC1: Media recovery disabled) (EricMANGEAT)
#                  Adding also "Archive log start;"  for ARCH but already launched via spfile.
#                  Adding also "archive log list;" to be diplayed in the trace.
#		   Check if LOGNAME is oracle or not.
#		   Suppression of $SIL when dislaying the syntaxe to be confirmed.
#
#
# 6.14 14jun2011 : Upgrage to same level as v6.14 CommonBundle :
#
#		   F_Fin		=> F_End
#		   SOUPROD		=> SUBPROD
#		   OBJET		=> OBJECT
#		   CodeRetour		=> ReturnCode
#		   Jour			=> Day
#		   Mois			=> Month
#		   SILENCE		=> SILENT
#		   SUPER_SILENCE	=> BLIND
#		   -s			=> -B
#		   Default attitude is set to -S
#		   Suppression of LOAD_ONLY
#		   .trc			=> No change (.log concerns only the CommonBundle)
#
#		   RepTrace		=> TrcDir
#		   FicTrace		=> TrcFile
#		   bidon		=> dumb		(already made)
#		   FIN			=> EOF
#
#	15jun2011 : Correction in find $TrcDir ...
#			"Oracle_${OBJECT}_.log"  become "Oracle_${OBJECT}_*.log"
#		   
# 6.15 01jul2011 : Compatibility with ADR :
#					F_clear_dumps()
#					F_clear_alert()
#					F_clear_listener()
#		   New F_clear_adr()
#
#		   Fusion of both standards in the same script for Compatibility CB + S4D0 : 
#		   It concerns :
#			-------- ------ CB ------------------   ------ S4D0 ---------------
#			Title    OperateOracleAll.ksh		ExploiterOracle.ksh
#			STANDARD /opt/operating/bin		/exec/products/genexpl/sh
#			DBASE	 /oradata			/data/ora
#			TrcDir	 /opt/operating/log		/exec/products/genexpl/logs
#			TrcFile	 ...log				...trc
#			FlagDir  /var/opt/FlagBlackOut		/exec/FlagBlackOut
#
#      21sep2011 : F_clear_alert    : add [ -d "$FIC_ALERT_XML" ] before mv ...
#		   F_clear_listener : add [ -d "$LIST_LOG_XML" ]  before cat ...
#					  [ -f "$LIST_TRC" ]      before cat ...
#
#      01dec2011 : DefectID:96 : TrcDir=/opt/oracle/operating/log      
#                     instead of TrcDir=/opt/operating/log
#
#		   Remark : it exist two links /opt/operating/log/OracleAllOperating
#				           and /var/opt/log/OracleAllOperating
#		   that both point to /opt/oracle/operating/log
#		   For Oracle, if purge fails, it could fill the FS /opt/oracle which is sized to 480MB.
#
# 6.16 24jan2012 : New retention for clear_listener()  3, 2, 1, 0 month
#
#      26jun2012 : Correction : ADR_BASE using DBASE for multi-standard (Pierre LAFOSSE)
#
# 6.17 12jul2012 : Force ADR_BASE (no Sqlplus, no strings)	(Philippe RAVAUD) 
#      16jul2012 : Add "set base $ADR_BASE" in the line "for $i in ..."
#
# 6.18 10sep2012 : clear_dumps : add purge of $ORACLE_HOME/log/diag/clients
#
# 6.19 11oct2012 : clear_dumps : lines are deplaced to obtain return code 0 in any case (with or without ADR).
#
# 6.20 29nov2012 : clear_dbalog : 2 retention : top-directory 90 days and sub-directories 365 days.
#
# 6.21 24apr2013 : Add argument -notrace  # used by VOLTAGE  (Thierry COLARDEAU)
#		   Reduce retention of traces to 10 days (instead of 30 days).
#		   Correction -maxdepth and -mindepth because unavailable on AIX
#
# 6.22  3jun2013 : chmod 644 $TrcFile   (au lieu de 777)
#
# 6.23 02des2013 : Purge find $DBASE/adm/diag/tnslsnr/*/$LIST_MIN -mtime +125  -exec rm -f {} \;
#		   for cluster because the path includes the HOSTNAME
#		   so, after a swith the listener traces were not correctly purged.
#
# 6.24 01mar2014 : find -L $TrcDir  to follow the directory  when it is a Symbolic Link.
#		   (fixed by Laurent NOEL for CASHPOOLER)
#
# 6.3.0 7jan2015 : Multi-Listener :  a new start_listener treats all lirteners 
#		   and previour start_listener is renamed as start_listalone
#
# 6.3.1	28jul2015 F_test_listener() retrait de 2 backslash en trop
#
#       30jul2015 F_test_listener() F_stop_listener() F_start_listener() add A=... and [ -n "$A" ]
#		  to avoid empty loop and strange caracters in filename.
# 
#		  Improve display : Less messages and add $ORACLE_SID and $LISTENER in the remaining messages.
#		  Add Blue Color to display InstanceNames and ListenerNames after each action.
#		  Add Colors in the Menu.

# 6.3.2 20oct2015 Add the AWR SPLIT at the end of F_clear_adr()
#
# 6.3.3 19may2016 Correction for NOTRACE and F_End()
#
# 6.3.4 08aug2016 For AuditVault (Cedric Queyras / Serge F.) forcage des retention pour .aud et .xml
#
# 6.3.5 14sep2016 Add option "abrestim" abortrestrictimmediate as a new STOP_MODE (needed for 10g).
#
#	02nov2016 New F_clear_listener treats all listeners deducted from the specified LISTENER,
#		  and F_clear_listalone only treats the specified LISTENER (New choice 16 in the menu)
#		  In the Menu, the choices 11 12 13 14 15 are reallocate but the syntax remain the same.
#
#	28dec2016 In F_clear_dbalog add a test for a sub-directory.
#
# 6.3.6 06fev2017 Correction bug in the menu choices 13, 15, 16 (appel C.Rabouin)
#
# 6.3.7 07mar2017 Add the Boite de Compatibilite for French Syntaxes.
#		  En vue de deployer le OperateOracle.ksh sur des machines avec Dollaru en Francais.
#		  Il remplacera les ExploiterOracle.ksh tres anciens.
#		  Cette Boite FR->EN etait presente jusqu'en 6.15 et donc les Dollaru sont parfois en Francais.
#		  En resume : De 6.16 a 6.36 : pas de boite donc les dollaru sont forcement en Anglais.
#
# 6.3.8 26mai2017 Correction in F_clear_listalone to archive and remove LIST_LOG_XML_NUM=...../log_[1-9]*.xml
#
#		  F_clear_alert() pour les 2 find le 01 de chaque mois :  Message "no such file or directory" 
#			donc ajout de :  2>&1 1>/dev/null
#
# 6.3.9 29nov2017 En complement de la  'Boite de Compatibilite for French Syntaxes' rajoutee en 6.3.7
#		  ajout de 'base' et 'sqlnet' dans le paragraphe 'Set ORACLE_SID and LISTENER'
#
# 6.4.0 16jul2018 Correction RETFIND : une parenthese manquait.
#		  Correction ls -1rt $LIST_LOG_XML_NUM  | xargs rm -f   : 'rm -f' au lieu de 'rm .f'
#
# 6.4.1	20jul2018 Evolution du DIAG_DIR, pour mieux apprehender ADR et Dataguard.
#		  Ajout de la purge de FIC_DRC  (trace de broker)
#
# 6.4.2 25jul2018 Dans F_start_instance : ajout de la recherche du DB_ROLE.
#
# 6.4.3 05jun2019 Suspension du F_clear_alert lors que la purge ADR est activee.
#		  Le F_clear_adr se substitue aux dumps + alert
#
# 6.4.4 01oct2019 Comme AuditVault est deploye avec centralisation des .aud via AvdfAgent.
#		  On applique la retention donnee en argument pour "*.aud" et "*.xml"
#		  (au lieu de +90 jours qui etait figes auparavant)
#		  Si AuditVault absent, c'est que la base n'est pas sensible au niveaux traces "*.aud".
#

version=6.4.4

[ "$1" = version ] && echo "version=$version" && exit 0

#------------------------------------------------------------------

Syntax="
Arguments for the command line :
	-S as first argument = Silent (No Question & Small display)
	-B as first argument = Blind  (No Question &    No display)
-----------------------------------------------------------------------------
   \$1      \$2       \$3         [ \$4 ]                  # Comments
-----------------------------------------------------------------------------
 -start  instance \$ORACLE_SID                           # Usual Mode.
 -start  instance \$ORACLE_SID { restrict|ARCH|NOARCH }  # Forced Mode.
 -stop   instance \$ORACLE_SID { abrestim }              # shutdown immediate.
 -kill   instance \$ORACLE_SID                           # shutdown abort.
 -status instance \$ORACLE_SID

 -start  listener \$LISTENER
 -stop   listener \$LISTENER
 -status listener \$LISTENER

 -clear  dumps    \$ORACLE_SID {90|dd}                   # default 90 days.
 -clear  alert    \$ORACLE_SID                           # 12 months.
 -clear  listener \$LISTENER                             # 90 days.
 -clear  dbalog   \$ORACLE_SID {90|dd} {356|ddd}         # default 90 days
                                                         #   365 for subdirs.
 -clear  adr      \$ORACLE_SID (30|dd)                   # 30 days.
-----------------------------------------------------------------------------
 -test   instance \$ORACLE_SID { started | stopped | ARCH | NOARCH }
 -test   listener \$LISTENER   { started | stopped }
-----------------------------------------------------------------------------
"

F_MenuOperate()
{
	[ "$LOGNAME" = oracle ] || echo "	@ Warning : You must be oracle."

	case `uname -s` in
	SunOS ) ORATAB=/var/opt/oracle/oratab ;;
	*     ) ORATAB=/etc/oratab ;;
	esac

	LIST_OSID=`egrep '^[A-Z].*:/.*:(Y|y|N|n)($| |	)' $ORATAB \
		  | cut -d: -f1 `
	LIST_OSID_PLAT=`echo $LIST_OSID`

	LIST_LIST=`echo "$LIST_OSID" | sed -e 's/^/LISTENER_/'`
	LIST_LIST_PLAT=`echo $LIST_LIST`

 StART="$Gre -start$Sgr"
  StOP="$Red -stop$Sgr"
  KiLL="$Red -kill$Sgr"
StATUS="$Blu -status$Sgr"
 ClEAR="$Yel -clear$Sgr"

echo "
	-----------------------------------------------------------
	|          O p e r a t e   O r a c l e   (v$version)         |
	|---------------------------------------------------------|
	|  1 $StART  instance		$Ros(startup normal)$Sgr          |
	|  2 $StOP   instance		$Ros(shutdown immediate)$Sgr      |
	|  3 $KiLL   instance		$Ros(shutdown abort)$Sgr          |
	|  4 $StATUS instance					  |
	|---------------------------------------------------------|
	|  6 $StART  listener		61 $StART  listalone	  |
	|  7 $StOP   listener		71 $StOP   listalone	  |
	|  8 $StATUS listener		81 $StATUS listalone	  |
	|---------------------------------------------------------|
	| 11 $ClEAR  dbalog		$Ros(purge in .../adm/dbalog)$Sgr |
	| 12 $ClEAR  dumps		$Ros(purges in adump, bdump)$Sgr  |
	| 13 $ClEAR  adr		$Ros(purge in .../adm/diag)$Sgr   |
	| 14 $ClEAR  alert		$Ros(archive for 12 mois)$Sgr     |
	| 15 $ClEAR  listener		$Ros(all deducted listeners)$Sgr  |
	| 16 $ClEAR  listalone		$Ros(the specified listener)$Sgr  |
	-----------------------------------------------------------
	Choice (s=Syntax , q=Quit) : \c"

	read NUM  ; case "$NUM" in
		    s|S ) echo "$Syntax" ; exit ;;
		    1|2|3|4|6|7|8|61|71|81 ) ;;         #Choices purposed in the menu.
		    1r|1a|1n|2ra|t1a|t1n|t2|t6|t7 ) ;;     #Choices not proposed.
		    11|12|13|14|15|16 ) ;;
		    * ) echo "\tCancel." ; return 0 ;;
		    esac

    case "$NUM" in
    6|7|8 ) echo "
		MULTI-LISTENER : Consider your next answer as a PREFIX :
		    All listeners that beggin with this PREFIX will be treated.
		If you type LISTENER_PAPA ; it will treat :
		    LISTENER_PAPA + LISTENER_PAPA_B + LISTENER_PAPA_ADM ...
		"
	;;
    esac

    case "$NUM" in
    6|7|8|61|71|81|t6|t7|15|16 ) 
	echo
	[ -n "$LIST_LIST_PLAT" ] && echo "\tSuggestions            : $LIST_LIST_PLAT"
	echo "\tLISTENER name (q=Quit) : \c"
	read  LISTENER 
	case "$LISTENER"   in quit|q|Q|"" ) echo "\t@ Cancel."; return 0 ;;
	esac
	;;
    * )	
	echo
	[ -n "$LIST_OSID_PLAT" ] && echo "\tExtract from oratab  : $LIST_OSID_PLAT"
	echo "\tORACLE_SID  (q=Quit) : \c"
	read ORACLE_SID
	case "$ORACLE_SID" in quit|q|Q|"" ) echo "\t@ Cancel."; return 0 ;;
	esac
	;;
    esac

	LISTE_CAS="	0   help
	1    -start  instance  $ORACLE_SID
	1r   -start  instance  $ORACLE_SID  restrict
	1a   -start  instance  $ORACLE_SID  ARCH
	1n   -start  instance  $ORACLE_SID  NOARCH
	2    -stop   instance  $ORACLE_SID
	2ari -stop   instance  $ORACLE_SID  abrestim
	3    -kill   instance  $ORACLE_SID
	4    -status instance  $ORACLE_SID
	6    -start  listener  $LISTENER
	7    -stop   listener  $LISTENER
	8    -status listener  $LISTENER
	61   -start  listalone $LISTENER
	71   -stop   listalone $LISTENER
	81   -status listalone $LISTENER
	t1   -test   instance  $ORACLE_SID  started
	t1a  -test   instance  $ORACLE_SID  ARCH
	t1n  -test   instance  $ORACLE_SID  NOARCH
	t2   -test   instance  $ORACLE_SID  stopped
	t6   -test   listener  $LISTENER    started
	t7   -test   listener  $LISTENER    stopped
	11   -clear  dbalog    $ORACLE_SID
	12   -clear  dumps     $ORACLE_SID
	13   -clear  adr       $ORACLE_SID
	14   -clear  alert     $ORACLE_SID
	15   -clear  listener  $LISTENER
	16   -clear  listalone $LISTENER"

ARGS=`echo "$LISTE_CAS" | grep "^	$NUM " | cut -c6-`
ARGS=`echo $ARGS`

	echo "
	Show Syntax          :  [ $ARGS  ]
	Confirm (yes|no)     ?  \c"
	read CONFIRM
	[ "$CONFIRM" = yes ] || { echo "	@ Cancel." ; return 0 ; }

	$SCRIPT -S $ARGS	# relaunch the same script but in batch mode.
	return $?
}


#
#=======================================================================
#  DOC1  Environment parameters that could be valued from parent shell :
#=======================================================================
# 
# Nom		Acceptee telle quelle		Revalorisee ou ecrasee
# de la		ou evitee soigneusement		systematiquement
# variable					pour eviter toute confusion
# --------------------------------------------------------------------------
# LOGNAME	X (Acceptee : Read only sur AIX et HP)
# PATH		X (Evitee   : Binaires Oracle lances par Chemin absolu)
# TNS_ADMIN	X (Acceptee mais si vide, alors valorisee)
# ORATAB					X (Selon l'OS)
# ORACLE_SID					X (Issu de la ligne de cmde)
# ORACLE_HOME					X (Extrait de l'ORATAB)
# LISTENER					X (Issu de la ligne de cmde)
# PFILE						X (Ecrase par precaution)
# NLS_LANG	X (a priori non utilisee)
# DBNAME					X (Calcul selon ORACLE_SID)
# DBASE 					X (Calcul selon DBNAME)
# --------------------------------------------------------------------------
#
#===================================================================
# DOC2  Other parameters strictly local in this script :
#===================================================================
#
#   Parameters from the commande line :
#   -----------------------------------
#	$0      $*         <-------------- $1 a $5 -------------->
#	SCRIPT  ARGUMENTS  SILENT  BLIND  ACTION  SUBPROD  OBJECT  OPTION  
#
#		( OBJECT valued later with ORACLE_SID or LISTENER )
#
#   Internal parameters in this script :
#   ------------------------------------
#	ReturnCode TrcDir  TrcFile
#	INSTANCE_STATUS   NB_PROC   LOG_MODE
#	PROCESS  SQLPLUS  TEST 	START_MODE  STOP_MODE
#
#==================================================================
# DOC3  List of functions :
#==================================================================
#
#	The end of a function must always be a "return".
#	The 'return codes' used are  0=OK and 1=Fail.
#	-----------------------------------------------------
#	F_MenuOperate()		|	F_VerifSqlplus()
#	F_Profile()  		|	F_VerifProcess()
#	F_End()			|	F_VerifLogMode()
#				|
#	F_test_instance()	|	F_test_listener()
# 	F_stop_instance()	|	F_stop_listener()
#	F_start_instance()	|	F_start_listener()
#				|
#	F_clear_dumps		|
#	F_clear_alert		|
#	F_clear_listener	|
#	F_clear_dbalog		|
#	F_clear_adr		|
#	-----------------------------------------------------
#
#==================================================================

#
#******************************************************************
F_Profile()
{ 
	# Function that replace the .profile and the oraenv of Oracle

	echo "\tF_Profile ..."

	export  ORACLE_SID  LISTENER         # Issued from the command line. 
	export  PFILE  ORATAB  ORACLE_HOME  PATH  TNS_ADMIN  # Updated here.
	unset   ORA_NLS33

# ORATAB
#-------
	case `uname -s` in
	SunOS ) ORATAB=/var/opt/oracle/oratab ;;
	*     ) ORATAB=/etc/oratab ;;
	esac

	if [ ! -r "$ORATAB" ]
	then echo "\t@ ORATAB not found or not readable." ; return 1
	fi


# ORACLE_SID	# if "instance" , then it is provided by the commande line.
#-----------    # if "listener" , then it is issued from the LISTENER name.

	NB_SID=`grep -c "^$ORACLE_SID:" $ORATAB`
	if [ "$NB_SID" != 1 ]
	then echo "\t@ Database $ORACLE_SID found $NB_SID time in $ORATAB"
	     return 1
	fi

# ORACLE_HOME	# Tree possible sources (here, we use the oratab) :
#------------   # 1  From oratab        : if it is up to date.
		# 2  Shell Environment  : if using "su - oracle" (.profile)
		# 3  From /etc/passwd   : if ORACLE_HOME = HOME

	OLDHOME=$ORACLE_HOME    # OLDHOME from the connection account.
	                        # so, possibly already included in the PATH 

	ORACLE_HOME=`grep "^$ORACLE_SID:" $ORATAB | tail -1 | cut -d: -f2`

	if [ ! -d "$ORACLE_HOME" ] 
	then echo "\t@ ORACLE_HOME : $ORACLE_HOME is not a directory." ; return 1
	fi

# PATH
#-----
	if [ -d "$OLDHOME" ]
	then
	    case "$PATH" in
	    *$ORACLE_HOME/bin*  ) ;;
	    *$OLDHOME/bin*	) PATH=`echo $PATH | \
				  sed "s;$OLDHOME/bin;$ORACLE_HOME/bin;g"` ;;
	    esac
	fi

	case "$PATH" in
	*$ORACLE_HOME/bin*	) ;;
	*:			) PATH=${PATH}$ORACLE_HOME/bin: ;;
	""			) PATH=$ORACLE_HOME/bin ;;
	*			) PATH=$PATH:$ORACLE_HOME/bin ;;
	esac


# TNS_ADMIN
#----------
	if [ "$SUBPROD" = listener -o "$SUBPROD" = listalone ]
	then [ -z "$TNS_ADMIN" ] && TNS_ADMIN=$ORACLE_HOME/network/admin
	fi

# LISTENER
#---------
	# People sometime type the ORACLE_SID instead of the LISTENER :

	case "$LISTENER" in
	dumb|list*|LIST* ) ;;
	*  ) echo "\t@ Warning: listener $LISTENER seems not standard."
	esac
}

#
#******************************************************************
F_VerifSqlplus()
{
INSTANCE_STATUS=`$ORACLE_HOME/bin/sqlplus /nolog <<-EOF | egrep "OPENED|ORA-|DBA-|ERR"
connect / as  sysdba
set head off
select 'OPENED' from dual ;
EOF`
        case "$INSTANCE_STATUS" in
        OPENED     ) echo "\tSqlplus : success"                   ; return 0 ;;
        *ORA-01090*) echo "\tSqlplus : shutdown in progress"      ; return 1 ;;
        *ORA-01017*) echo "\tSqlplus : invalid username/password" ; return 1 ;;
        *ORA-01034*) echo "\tSqlplus : ORACLE not available"      ; return 1 ;;
        *          ) echo "\tSqlplus : fail \n$INSTANCE_STATUS"   ; return 1 ;;
        esac
}

#******************************************************************
F_VerifProcess()
{
NB_PROC=`ps -ef | egrep -c "ora_(smon|pmon|lgwr|dbw0)_$ORACLE_SID( |$)"`

	case "$NB_PROC" in              
        4          ) echo "\tProcess : all are present"          ; return 0 ;;
        0          ) echo "\tProcess : all are absent"           ; return 1 ;;
        *          ) echo "\tProcess : $NB_PROC, Expected : 4"    ; return 1 ;;
	esac 
}

#******************************************************************
F_VerifLogMode()
{
LOG_MODE=`$ORACLE_HOME/bin/sqlplus /nolog <<-EOF
connect / as sysdba
select log_mode from v\\$database;
EOF`

  case "$LOG_MODE" in
  *ORA-*|*ERR*  ) echo "\tLogMode : ERREUR \n$LOG_MODE" ; LOG_MODE=unknown
		  return 1 ;;
  *NOARCHIVELOG*) echo "\t@ LogMode : NOARCHIVELOG"     ; LOG_MODE=noarchivelog
		  return 0 ;;
  *ARCHIVELOG*  ) echo "\t@ LogMode : ARCHIVELOG"       ; LOG_MODE=archivelog
		  return 0 ;;
  esac
}
#
#******************************************************************
F_test_instance()
{
	case "$1" in
	started|ARCH|NOARCH|stopped	) TEST=$1	;;
	restrict			) TEST=started  ;; #this test is required by start
	*				) echo "$Syntax" ; return 1 ;;
	esac

	LOG_MODE=unknown   # will be known if instance started and if it is asked.

	F_VerifProcess  &&  PROCESS=yes  ||  PROCESS=no
	F_VerifSqlplus  &&  SQLPLUS=yes  ||  SQLPLUS=no

	case "$PROCESS-$SQLPLUS-$TEST" in
	yes-yes-started ) echo "\t@ The instance [$ORACLE_SID] is started."	     ; return 0;;
	yes-yes-stopped ) echo "\t@ The instance [$ORACLE_SID] is not stopped."        ; return 1;;

	no-no-started   ) echo "\t@ The instance [$ORACLE_SID] is not started."        ; return 1;;
	no-no-stopped   ) echo "\t@ The instance [$ORACLE_SID] is stopped."	     ; return 0;;

	no-no-*ARCH     ) echo "\t@ Arch unknown(Instance [$ORACLE_SID] not started)." ; return 1;;
	yes-yes-*ARCH   ) F_VerifLogMode
	    case "$TEST-$LOG_MODE" in
	    ARCH-archivelog|NOARCH-noarchivelog )		      return 0;;
	    * ) echo "\t@-Instance [$ORACLE_SID] started but not in $TEST mode."   ;return 1;;
	    esac ;;

       	yes-no-*    ) echo "\t@ Unexpected ProcessOK/SqlplusFail."   ;return 1;;
	no-yes-*    ) echo "\t@ Unexpected ProcessFail/SqlplusOK."   ;return 1;;
	*           ) echo "\t@ Unexpected F_test_instance."         ;return 1;;
	esac
}

#
#******************************************************************
F_stop_instance()
{
	case "$1" in
	immediate|abort|abortrestrictimmediate|abrestim ) STOP_MODE=$1              ;;
	""              				) STOP_MODE=immediate       ;;
	*						) echo "$Syntax" ; return 1 ;;
	esac

	echo
	if F_test_instance stopped
	then echo "\t@    Cancel (Instance [$ORACLE_SID] already stopped)." ; return 0
	else echo "\t@ Stopping Instance [$ORACLE_SID] ..." 
	fi

	if [ "$SILENT" = no ]
	then echo "\tStop instance $ORACLE_SID : Confirm (yes|no) : \c"
	     read CONFIRM
	     [ "$CONFIRM" = yes ] || { echo "\tUser Cancel" ; return 0 ; }
	fi	
	#----------- stop_instance pour Patrol-------------#
	if [ -d $FlagDir ]
	then rm -f $FlagDir/Oracle_$ORACLE_SID.off
	     touch $FlagDir/Oracle_$ORACLE_SID.off
	fi
	#--------------------------------------------------#
    
		F_VerifLogMode >/dev/null
		if [ "$LOG_MODE" = archivelog ]
		then ARCH_LOG_CURRENT="alter system archive log current;"
		else ARCH_LOG_CURRENT=""
		fi

		case "$STOP_MODE" in
		
		immediate)
        		$ORACLE_HOME/bin/sqlplus /nolog <<-EOF 
			connect /as sysdba
			$ARCH_LOG_CURRENT
			shutdown immediate
			EOF
			;;
		abort)
        		$ORACLE_HOME/bin/sqlplus /nolog <<-EOF 
			connect / as sysdba
			$ARCH_LOG_CURRENT
			shutdown abort
			EOF
			;;
		abortrestrictimmediate|abrestim)

			# Added for 10g / october 2016 / Appli Omega / Alain B.
			# to avoid : "SHUTDOWN: Active processes prevent shutdown operation"
			# Metalink note 416658.1

        		$ORACLE_HOME/bin/sqlplus /nolog <<-EOF 
			connect / as sysdba
			$ARCH_LOG_CURRENT
			shutdown abort
			startup restrict
			shutdown immediate
			EOF
			;;
		esac

	sleep 2
	echo
	F_test_instance stopped  &&  return 0  ||  return 1
}                
#
#******************************************************************
F_start_instance()
{
	case "$1" in
	ARCH|NOARCH|restrict	) START_MODE=$1		;;
	""			) START_MODE=started	;;
	*			) echo "$Syntax"       ; return 1 ;;
	esac

	echo
	F_test_instance  $START_MODE >/dev/null

	case "$PROCESS-$SQLPLUS-$LOG_MODE-$START_MODE" in

	yes-yes-archivelog-ARCH      | \
	yes-yes-noarchivelog-NOARCH  ) 
		echo "\t@    Cancel (already started in $LOG_MODE mode)"; return 0 ;;

	yes-yes-archivelog-NOARCH    | \
	yes-yes-noarchivelog-ARCH    )				  return 1 ;; 
		# Message in @- because redondant with F_test_instance :
		# echo "\t@-Instance already started but in Mode $LOG_MODE."

	yes-yes-*-started ) echo "\t@    Cancel (Instance [$ORACLE_SID] already started)" ; return 0 ;;
	yes-yes-*-restrict) echo "\t@    Cancel (Instance [$ORACLE_SID] already started)" ; return 1 ;;

	no-no-*-restrict  ) echo "\t@ Starting instance [$ORACLE_SID] restrict ..."      ;;

	no-no-*           ) echo "\t@ Starting instance [$ORACLE_SID] ..."               ;;

	*		  ) echo "\t@    Cancel (Unknown status)"  ; return 1 ;; 
	esac


	if [ "$SILENT" = no ]
	then echo "\tStart instance $ORACLE_SID : Confirm (yes|no) : \c"
	     read CONFIRM
	     [ "$CONFIRM" = yes ] || { echo "	@ User Cancel." ; return 0 ; }
	fi	

	#-------------------------------------------------------------------------------
	# Ajout en v6.4.2   (25 juillet 2018)
	# Empeche le 'open' si role STANDBY ou si le role est INCONNU.

	echo "	@ On realise un 'startup mount' afin de connaitre le DB_ROLE ..."
	$ORACLE_HOME/bin/sqlplus / as sysdba <<-EOF
	startup mount ;
	EOF

		dbrole=`sqlplus -s "/ as sysdba"<<-'FINRO' | grep "^DB_ROLE=" | cut -d= -f2
		set head off
		select 'DB_ROLE='||database_role from v$database;
		FINRO`

		case "$dbrole" in
		"PRIMARY" )
			echo "	@ db_role=PRIMARY : on continue ..."
			;;
		"PHYSICAL STANDBY"|"LOGICAL STANDBY" )
			echo "	@ C est une STANDBY, donc on reste en 'startup mount'"
			echo "	@	Pas de 'open' donc pas d Active Dataguard"
			echo "	@	et aucune gestion de FlagBlackOut."
			return 0
			;;
		*  )	echo "	@ Ce n est pas une PRIMARY ou role INCONNU : [db_role=$dbrole]"
			echo "	@	Pas de poursuite du demarrage. Sortie en erreur."
			echo "	@	On laisse la base telle quelle !"
			return 1
			;;
		esac 

	# Fin de l'ajout en 6.4.2   (25 juillet 2018)
	#-------------------------------------------------------------------------------



	    case "$START_MODE" in

	    started )	$ORACLE_HOME/bin/sqlplus / as sysdba <<-EOF
			alter database open ;
			EOF
			;;

	    restrict )	$ORACLE_HOME/bin/sqlplus / as sysdba <<-EOF
			alter system enable restricted session ;
			alter database open ;
			EOF
			;;

	    ARCH )	$ORACLE_HOME/bin/sqlplus / as sysdba <<-EOF
			alter database archivelog;
			alter database open;
				archive log start;
				archive log list;
			EOF
			;;

	    NOARCH )	$ORACLE_HOME/bin/sqlplus / as sysdba <<-EOF
			alter database noarchivelog;
			alter database open;
				archive log stop;
				archive log list;
			EOF
			;;
	    esac

	sleep 2

	#----------- start_instance pour Patrol------------#
	case "$START_MODE" in
	restrict ) ;; # The Flag remains because it is a maintenance session.
	*        ) if [ -f $FlagDir/Oracle_$ORACLE_SID.off ]
		   then rm -f $FlagDir/Oracle_$ORACLE_SID.off
		   fi ;;
	esac
	#--------------------------------------------------#

	echo
	F_test_instance $START_MODE  &&  return 0  ||  return 1
}
#

#******************************************************************
F_test_listener()
{
	TEST=$1		# Arg can be [started] or [stopped]

	LISTENALL=`egrep -i "^$LISTENER( |_|=)" $TNS_ADMIN/listener.ora | cut -d= -f1`

	if [ -z "$LISTENALL" ]
	then echo "	@ [^$LISTENER] not found in $TNS_ADMIN/listener.ora"
	     return 1
	fi

	RC_LISTENALL=0

	for LISTENER in $LISTENALL
	do
		F_test_listalone $TEST
		RC_LSN=$?
		[ $RC_LSN = 0 -a $RC_LISTENALL = 0 ] || RC_LISTENALL=1
		echo "	@            RC for [$LISTENER] is $RC_LSN"

	done

	return $RC_LISTENALL
}
#******************************************************************
F_test_listalone()
{
    case "$1" in
    started ) $ORACLE_HOME/bin/lsnrctl stat $LISTENER && return 0 || return 1 ;;
    stopped ) $ORACLE_HOME/bin/lsnrctl stat $LISTENER && return 1 || return 0 ;;
    *	    ) echo "$Syntax"                                      ;  return 1 ;;
    esac
}

#******************************************************************
F_stop_listener()
{
	LISTENALL=`egrep -i "^$LISTENER( |_|=)" $TNS_ADMIN/listener.ora | cut -d= -f1`

	if [ -z "$LISTENALL" ]
	then echo "	@ [^$LISTENER] not found in $TNS_ADMIN/listener.ora"
	     return 1
	fi

	RC_LISTENALL=0

	for LISTENER in $LISTENALL
	do
		F_stop_listalone
		[ $? = 0 -a $RC_LISTENALL = 0 ] || RC_LISTENALL=1
	done

	return $RC_LISTENALL
}

#******************************************************************
F_stop_listalone()
{
	if F_test_listalone stopped 2>&1 1>/dev/null
	then echo "\n\t@    Cancel (Listener [$LISTENER] is not running)" ; return 0
	fi

        if [ "$SILENT" = no ]
        then echo "\tStop listener $LISTENER : Confirm (yes|no) : \c"
             read CONFIRM
	     [ "$CONFIRM" = yes ] || { echo "\tUser Cancel" ; return 0 ; }
	fi

	#----------- stop_listener pour Patrol-------------#
	if [ -d $FlagDir ]
	then rm -f $FlagDir/Listener_`echo $LISTENER|cut -d'_' -f2-`.off
	     touch $FlagDir/Listener_`echo $LISTENER|cut -d'_' -f2-`.off
	fi
	#--------------------------------------------------#

	echo "\n\t@ Stopping listener [$LISTENER] ..."
	echo "\t-----------------------------------------------------\n"
	$ORACLE_HOME/bin/lsnrctl stop $LISTENER

	RC_STOP_LISTENER=$?
	echo "	@            RC for [$LISTENER] is $RC_STOP_LISTENER"
	return $RC_STOP_LISTENER
}                
#******************************************************************
F_start_listener()
{
	LISTENALL=`egrep -i "^$LISTENER( |_|=)" $TNS_ADMIN/listener.ora | cut -d= -f1`

	if [ -z "$LISTENALL" ]
	then echo "	@ [^$LISTENER] not found in $TNS_ADMIN/listener.ora"
	     return 1
	fi

	RC_LISTENALL=0

	for LISTENER in $LISTENALL
	do
		F_start_listalone
		[ $? = 0 -a $RC_LISTENALL = 0 ] || RC_LISTENALL=1
	done

	return $RC_LISTENALL
}

#******************************************************************
F_start_listalone()
{
	if F_test_listalone started 2>&1 1>/dev/null
	then echo "\n\t@    Cancel (Listener [$LISTENER] is already running)" ; return 0
	fi

        if [ "$SILENT" = no ]
        then echo "\tStart listener $LISTENER : Confirm (yes|no) : \c"
             read CONFIRM
	     [ "$CONFIRM" = yes ] || { echo "\tUser Cancel" ; return 0 ; }
	fi

	echo "\t@ Starting listener [$LISTENER] ..."
#	echo "\t-----------------------------------------------------\n"
	$ORACLE_HOME/bin/lsnrctl start $LISTENER
	RC_START_LISTENER=$?

	#----------- start_listener pour Patrol------------#
	if [ -f $FlagDir/Listener_`echo $LISTENER|cut -d'_' -f2-`.off ]
	then rm -f $FlagDir/Listener_`echo $LISTENER|cut -d'_' -f2-`.off
	fi
	#--------------------------------------------------#

	echo "	@            RC for [$LISTENER] is $RC_START_LISTENER"
	return $RC_START_LISTENER
}
#
#******************************************************************
F_clear_dbalog()
{
    case "$1" in
    ""                               ) RET_TOP=90 ;;  # default for the top directory.
    [1-9]|[1-9][0-9]|[1-9][0-9][0-9] ) RET_TOP=$1 ;;
    esac

    case "$2" in
    ""                               ) RET_SUB=365 ;; # default for sub directories.
    [1-9]|[1-9][0-9]|[1-9][0-9][0-9] ) RET_SUB=$2  ;;
    esac

    # Only first level (top-directory) :
    # find $DBASE/adm/dbalog -maxdepth 1 -mtime +$RET_TOP -print -exec rm -f {} \; 2>/dev/null  # Bad on AIX

	find $DBASE/adm/dbalog     -type f -mtime +$RET_TOP | grep -v "^$DBASE/adm/dbalog/.*/" | xargs rm -f 2>/dev/null

    # Only next levels (sub-directories) :
    # find $DBASE/adm/dbalog -mindepth 2 -mtime +$RET_SUB -print -exec rm -f {} \; 2>/dev/null  # Bad on AIX

    if [ `ls -l $DBASE/adm/dbalog | grep -c "^d"` -gt 0 ]	# If any sub-directory exists.
    then
	find $DBASE/adm/dbalog/*/  -type f -mtime +$RET_SUB 2>/dev/null | xargs rm -f 2>/dev/null
    fi
}
#******************************************************************
F_clear_dumps()
{
    case "$1" in
    ""                ) RET=90 ;;      			# default retention.
    [1-9]|[1-9][0-9]  ) RET=$1 
			[ "$RET" -lt 7 ] && RET=7 ;;	# minimum 7 days.
    esac

	echo "
	@ Suppression of \*.aud \*.trc cor\* that exceed $RET days ..."

	# adump* indicates adump + adumpSID1 + adumpSID2 + adump... :

   # ici, on "attaque" des vrais repertoires : si lien symboliques, alors penser a -L .

   find $DBASE/adm/adump* -name "*.aud"  -mtime +$RET -print -exec rm -f  {} \;
   find $DBASE/adm/adump* -name "*.xml"  -mtime +$RET -print -exec rm -f  {} \;
   find $DBASE/adm/bdump* -name "*.trc"  -mtime +$RET -print -exec rm -f  {} \;
   find $DBASE/adm/bdump* -name "cdmp_*" -mtime +$RET -print -exec rm -Rf {} \;
   find $DBASE/adm/cdump* -name "cor*"   -mtime +$RET -print -exec rm -Rf {} \;
   find $DBASE/adm/udump* -name "*.trc"  -mtime +$RET -print -exec rm -f  {} \;

# These 3 directories might not exist when ADR is disabled and their return code can be 1. 
   find $DBASE/adm/*diag* -name "*.trc"  -mtime +$RET -print -exec rm -f  {} \;
   find $DBASE/adm/*diag* -name "*.trm"  -mtime +$RET -print -exec rm -f  {} \;
   find $ORACLE_HOME/log/diag/clients -type f  -mtime +$RET -print -exec rm -f  {} \;

# This directory always exists (with or without ADR), so the return code will be 0.
   find $ORACLE_HOME/rdbms/audit -name "*.aud" -mtime +$RET -print -exec rm -f {} \;
}
#
#******************************************************************
F_clear_adr()
{
	if [ ! -f $ORACLE_HOME/log/diag/adrci_dir.mif ]
	then echo "	File $ORACLE_HOME/log/diag/adrci_dir.mif not found."
	     echo "	ADR not enabled. Exit 1."
	     return 1
	fi

	#==================================================================
	#                       Before ADR    After ADR
	# --------------------- ------------- ----------------------------
	# background_dump_dest  adm/bdump     adm/diag/rdbms/ptest/PTEST/trace
	# user_dump_dest        adm/udump     adm/diag/rdbms/ptest/PTEST/trace
	# core_dump_dest        adm/cdump     adm/diag/rdbms/ptest/PTEST/cdump
	# audit_file_dest       adm/adump     Remains the same as before ADR.
	#=================================================================

	#===============================================================================
	# Initialization of ADR (in 11g) :
	# sysdba
	#   alter system reset user_dump_dest       scope=spfile ;
	#   alter system reset background_dump_dest scope=spfile ;
	#   alter system reset core_dump_dest       scope=spfile ;
	#
	#   alter system reset "_diag_adr_enabled" scope=spfile ;
	#   alter system set diagnostic_dest='/oradata/PTEST/adm' scope=both; 
	#   shutdown immediate  ; startup ;
	#
	# mv    /oradata/PTEST/adm/bdump   /oradata/PTEST/adm/bdump_before_adr
	# rm -r /oradata/PTEST/adm/udump/*
	# rm -r /oradata/PTEST/adm/cdump/*
	#
	# ln -s /oradata/PTEST/adm/diag/rdbms/ptest/PTEST/trace /oradata/PTEST/adm/bdump
	# ln -s /oradata/PTEST/adm/diag/rdbms/ptest/PTEST/trace /oradata/PTEST/adm/udump
	# ln -s /oradata/PTEST/adm/diag/rdbms/ptest/PTEST/cdump /oradata/PTEST/adm/cdump
	#===============================================================================

    case "$1" in
    ""                ) RET=30 ;;   # Default retention in days.
    [1-9]|[1-9][0-9]  ) RET=$1 ;;
    esac
    RET_MIN=`expr $RET \* 1440`     # Retention in Minutes


	#------------------------------------------------------------
	# Extract ADR_BASE from SPFILE, then DATABASE, then DEFAULT :
	#------------------------------------------------------------
	export ADR_BASE

# BAD because need to mount the database for this request :
#	if [ -z "$ADR_BASE" ] 
#	then	ADR_BASE=`$ORACLE_HOME/bin/sqlplus -s '/ as sysdba' <<-EOF | grep "^/.*/"
#		select value from v\$parameter where name='diagnostic_dest' ;
#		EOF`
#	fi
#
# BAD because strings returns the parameter splitted on several lines !!!
#	ADR_BASE=`strings $DBASE/u01/pfile/spfile$ORACLE_SID.ora \
#		  | grep -i diagnostic_dest | cut -d= -f2 | sed -e "s/'//" | sed -e "s/'.*//" `
#
#	if  [ -z "$ADR_BASE" ]
#	then	ADR_BASE=$DBASE/adm 
#	fi
#
# So, we force ADR_BASE to match the Standard :

	ADR_BASE=$DBASE/adm 

BEFORE_CLEAR=`echo "set base $ADR_BASE ; show tracefile" | $ORACLE_HOME/bin/adrci | wc -l`

for i in `$ORACLE_HOME/bin/adrci exec="set base $ADR_BASE ; show home" | grep -v :`
do
echo "  set base $ADR_BASE ;
	show base ;
        set home $i ;
        show home ;	
	purge -age $RET_MIN -type alert;
	purge -age $RET_MIN -type incident;
	purge -age $RET_MIN -type trace;
	purge -age $RET_MIN -type cdump;
	purge -age $RET_MIN -type hm;
	purge -age $RET_MIN -type UTSCDMP;"
done >/tmp/purge_adr.scr
$ORACLE_HOME/bin/adrci script=/tmp/purge_adr.scr

AFTER_CLEAR=`echo "set base $ADR_BASE ; show tracefile" | $ORACLE_HOME/bin/adrci | wc -l`

echo "	----------------------------------
	       Retention  : $RET days
	----------------------------------
	BEFORE CLEAR ADR  : $BEFORE_CLEAR lines
	AFTER  CLEAR ADR  : $AFTER_CLEAR lines
	---------------------------------- "


#---------------------------------------------
echo " AWR split of partitions in tablespace SYSAUX   Note 387914.1" 
# (Vu avec Olivier JOURDAN)
#---------------------------------------------
# It prevents a bug encountered in 11g :
# Explanation : At AWR purges (scheduled internally by oracle), a split should be executed.
# but the timeout for these purges is 15 minutes
# So when purges are long (more than 15 minutes), then this split is omitted.
# Consequently, the purges take more and more time, and fail.

        # Why adding the AWR split in this ADR function ? 
        #   As ADR was introduced with 11g and the bug AWR only concerns 11g
        #   we insert the correction in this function
        #   (we do not confuse ADR and AWR, we just add an AWR action inside the ADR function)

$ORACLE_HOME/bin/sqlplus /nolog <<-EOF
connect / as sysdba
alter session set "_swrf_test_action" = 72;
EOF

}

#******************************************************************
F_clear_alert()
{
	echo "
	@ To be launched the first of each month (it can also be launched during the month) :
	@ It archives the AlertFile to alert_$ORACLE_SID.Month
	@ and at first launch in the month, it erases the old M-12 (rotation on 12 month)
	@ Same thing for log.xml (when ADR) and drc$ORACLE_SID.log (when Broker)"


	# Compute the Month (not depending upon the Language) :
	#------------------------------------------------------
	set --  Dec Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec
	shift `date +%m`
	Month=$1			# Current month.

	# For multi-Instance databases (10gRAC for example) :
	# then each Instance have its own AlertFile under bdump$ORACLE_SID

		if [ -d $DBASE/adm/bdump$ORACLE_SID ]
		then FIC_ALERT=$DBASE/adm/bdump$ORACLE_SID/alert_$ORACLE_SID.log
		else FIC_ALERT=$DBASE/adm/bdump/alert_$ORACLE_SID.log
		fi

	#------------------------------
	# Since ADR (introduced in 11g), bdump is replaced by diag/... :
	# and there must be a SymbolicLink for bdump :
	#           bdump -> $DBASE/adm/diag/rdbms/db_uniq_name_lower_case/$ORACLE_SID
	#
	# We assume that the SymbolicLink is correctly created (espacially when Dataguard)
	# and we get this path through a subshell containing 'cd' and 'pwd -P' :

		DIAG_DIR=$(cd $DBASE/adm/bdump ; pwd -P)

	#------------------------------
	# With ADR also : there are 2 alert files :
	#	$DBASE/adm/diag/rdbms/db_uniq_name_lower_case/$ORACLE_SID/trace/alert_$ORACLE_SID.log
	#   and $DBASE/adm/diag/rdbms/db_uniq_name_lower_case/$ORACLE_SID/alert/log.xml)
	# With Broker ; there is a third file : 
	#       $DBASE/adm/diag/rdbms/db_uniq_name_lower_case/$ORACLE_SID/trace/drc$ORACLE_SID.log 

		FIC_ALERT=$DIAG_DIR/alert_$ORACLE_SID.log
		FIC_ALERT_XML=$DIAG_DIR/../alert/log.xml
		FIC_DRC=$DIAG_DIR/drc$ORACLE_SID.log

	#------------------------------
	# TRAITEMENT DU MOIS REVOLU   :
	#------------------------------
	# Si il est planifie toute les nuits, alors ce traitement surviendra le 01 de chaque mois.
	# Cependant, s'il survient pour la premiere fois en cours de mois (le 05 par exemple), 
	# cela sera transparent. 
	#
	# Suppression d'un fichier .Month vieux de plus de 3 mois.
	# Donc, en principe, ce .Month devrait etre celui de l'annee passee.

		find $FIC_ALERT.$Month     -mtime +90 -exec rm -f {} \; 2>&1 1>/dev/null
		find $FIC_ALERT_XML.$Month -mtime +90 -exec rm -f {} \; 2>&1 1>/dev/null
		find $FIC_DRC.$Month       -mtime +90 -exec rm -f {} \; 2>&1 1>/dev/null

	#------------------------------
	# TRAITEMENT DU MOIS EN COURS :
	#------------------------------
	# Rappelons que le $FIC_ALERT.$Month de l'annee passee a ete purge.
	# Si ce $FIC_ALERT.$Month est absent (en tout debut de mois),
	# alors le '>>' l'initialisera, sinon, cela l'abondera :


	# Ici, pour $FIC_ALERT ; pas de condition : ca permet d'obtenir un message d'erreur si absent :

		cat $FIC_ALERT >> $FIC_ALERT.$Month
		> $FIC_ALERT

	if [ -f "$FIC_ALERT_XML" ]
	then 
		cat $FIC_ALERT_XML >> $FIC_ALERT_XML.$Month
		> $FIC_ALERT_XML
	fi

	if [ -f "$FIC_DRC" ]
	then 
		cat $FIC_DRC >> $FIC_DRC.$Month
		> $FIC_DRC
	fi

}
#******************************************************************
F_clear_listener()
{
	LISTENALL=`egrep -i "^$LISTENER( |_|=)" $TNS_ADMIN/listener.ora | cut -d= -f1`

	if [ -z "$LISTENALL" ]
	then echo "	@ [^$LISTENER] not found in $TNS_ADMIN/listener.ora"
	     return 1
	fi

	RC_LISTENALL=0

	for LISTENER in $LISTENALL
	do
		F_clear_listalone $1
		[ $? = 0 -a $RC_LISTENALL = 0 ] || RC_LISTENALL=1
	done

	return $RC_LISTENALL
}
#******************************************************************
F_clear_listalone()
{
    case "$1" in
    ""		) RET=3  ;;    # default retention in month.
    3|2|1|0	) RET=$1 ;;    # it allows 2 month or 1 month or 0 month
    esac

	echo "
	@ A lancer le 01 de chaque mois et possiblement en cours de mois :
	@ Glissement des traces du $LISTENER sur 3 mois pleins ..."

	# Peu importe le listener.ora ; les traces sont toujours en minuscules :
	LIST_MIN=`echo "$LISTENER" | tr '[:upper:]' '[:lower:]'`
	LIST_LOG=$DBASE/adm/network/$LIST_MIN.log
	LIST_TRC=$DBASE/adm/network/$LIST_MIN.trc

	# For oracle 11g with ADR Diagnostic Parameters
	HOSTNAME=`uname -n`
	DIAG_DIR=$DBASE/adm/diag/tnslsnr/$HOSTNAME/$LIST_MIN

	if [ -d $DIAG_DIR ]
	then # oracle 11g with ADR
		LIST_LOG=$DIAG_DIR/trace/$LIST_MIN.log
		LIST_LOG_XML_NUM=$DIAG_DIR/alert/log_[1-9]*.xml		# Archived files when 10MB is reached.
		LIST_LOG_XML=$DIAG_DIR/alert/log.xml			# Current file being written by the process.
	else # oracle 11g without ADR or 9i/10g
		LIST_LOG=$DBASE/adm/network/$LIST_MIN.log
		LIST_TRC=$DBASE/adm/network/$LIST_MIN.trc
	fi

	# Added 02dec2013 to purge all traces even on a cluster after a switch :
	# 125 days is higher than 4 x 31 : so 4 months are retained :
	let RETFIND="(($RET + 1) * 31) + 1"
	echo find $DBASE/adm/diag/tnslsnr/*/$LIST_MIN -type f -mtime +$RETFIND  -exec rm -f {} \;
	     find $DBASE/adm/diag/tnslsnr/*/$LIST_MIN -type f -mtime +$RETFIND  -exec rm -f {} \; -print


	TRACE_LEVEL=`egrep -i "^[ 	]*TRACE_LEVEL_$LIST_MIN[ 	]*=" \
		$ORACLE_HOME/network/admin/listener.ora | awk -F'=' '{print $2}'`

		# Traiter le .trc est inutile si la trace n'est pas activee.
		# TRACE_FLAG permettrait d'eviter de traiter le .trc 
		# TRACE_FLAG est remplace par un test sur la presence du .trc
		case "$TRACE_LEVEL" in
		0|OFF|off|Off ) TRACE_FLAG=no  ;; 
		*             ) TRACE_FLAG=yes ;;
		esac

	# Day=`date +%d`	# Unused in this function.

	# Compute the previous months :
	#------------------------------
	set -- Aug Sep Oct Nov Dec Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec
	shift `date +%m`
	M_4=$1		# Month M-4		# Will be deleted
	M_3=$2		# Month M-3		# Unused
	M_2=$3		# Month M-2		# Unused
	M_1=$4		# Month M-1		# Unused
	Month=$5	# Current Month 	# Will be filled
	
	[ -f "$LIST_LOG.$M_4"     ] && rm $LIST_LOG.$M_4      # Window of 3 full months
	[ -f "$LIST_LOG_XML.$M_4" ] && rm $LIST_LOG_XML.$M_4  # Window of 3 full months

	# for shorter retentions : 2 month or 1 month or 0 month :
	if [ "$RET" -le 2 ]
	then
	    [ -f "$LIST_LOG.$M_3"     ] && rm $LIST_LOG.$M_3    
	    [ -f "$LIST_LOG_XML.$M_3" ] && rm $LIST_LOG_XML.$M_3 
	fi
	if [ "$RET" -le 1 ]
	then
	    [ -f "$LIST_LOG.$M_2"     ] && rm $LIST_LOG.$M_2    
	    [ -f "$LIST_LOG_XML.$M_2" ] && rm $LIST_LOG_XML.$M_2 
	fi
	if [ "$RET" -le 0 ]
	then
	    [ -f "$LIST_LOG.$M_1"     ] && rm $LIST_LOG.$M_1    
	    [ -f "$LIST_LOG_XML.$M_1" ] && rm $LIST_LOG_XML.$M_1 
	fi
 

#-------------------------------
# Desabling the listener logging
#-------------------------------
lsnrctl status $LISTENER > /dev/null
if [ $? -eq 0 ]
then
# stop logging
lsnrctl <<EOF
set current_listener $LISTENER
set log_status off
set trc_level 0
EOF
fi

	cat $LIST_LOG >> $LIST_LOG.$Month 		# No line is forgotten.
	> $LIST_LOG					# Re-initialize.

	if [ -f "$LIST_LOG_XML" ]
	then 
		# cat $LIST_LOG_XML >> $LIST_LOG_XML.$Month 					# Previous v6.3.7
		ls -1rt $LIST_LOG_XML_NUM  $LIST_LOG_XML | xargs cat >> $LIST_LOG_XML.$Month	# New v6.3.8
		> $LIST_LOG_XML					# Re-initialize (file attached).
		ls -1rt $LIST_LOG_XML_NUM  | xargs rm -f        # Remove (files not attached).	# New v6.3.8
	fi
	
	if [ -f "$LIST_TRC" ]
	then 
		cat $LIST_TRC >> $LIST_TRC.$Month
		> $LIST_TRC
	fi
			
#---------------------------------
# Re-enabling the listener logging
#---------------------------------
lsnrctl status $LISTENER > /dev/null
if [ $? -eq 0 ]
then
# start logging again
lsnrctl <<EOF
set current_listener $LISTENER
set log_status on
set trc_level $TRACE_LEVEL
EOF
fi

}

#******************************************************************
F_End()
{
	ReturnCode=$1 
	[ "$ReturnCode" = 0 ] && MsgRetour="$Gre OK $Sgr" || MsgRetour="$Red FAILED $Sgr"
	echo "\n\t@ $ACTION $SUBPROD [$Blu $OBJECT $Sgr] ReturnCode=$ReturnCode ($MsgRetour)"

	case "$SILENT-$BLIND-$NOTRACE" in
	*-yes     )  ;;					# No trace = nothing to grep.
	yes-yes-* )  ;;					# No display at all = no grep.
	yes-no-*  )  grep "^	@ " $TrcFile >&3 ;;	# Grep is directed to screen.
	esac
	exit $ReturnCode
}

#******************************************************************
#******************************************************************
#		    M A I N    P R O G R A M
#******************************************************************
#******************************************************************

#-----------------------------------------------------------------
# Checking the account :
#-----------------------------------------------------------------

	[ "$LOGNAME" = oracle ] || { echo "	@ You must be oracle." ; F_End 1 ; }

#-----------------------------------------------------------------
# Compatibility with both standards : CB and S4D0 :
#-----------------------------------------------------------------

	[ -d /exec/products/genexpl/sh ] && STANDARD=S4D0
	[ -d /opt/operating/bin        ] && STANDARD=CB

#-----------------------------------------------------------------
# Erase any values issued from the father shell :
#-----------------------------------------------------------------

	ORACLE_SID=dumb
	LISTENER=dumb
	PFILE=dumb

	Gre=`tput setf 2`
	Red=`tput setf 4`
	Yel=`tput setf 6`
	Blu=`tput setf 3`
	Whi=`tput setf 9`
	Mar=`tput setf 1`
	Ros=`tput setf 5`

	Sgr=`tput sgr0`		# Retour en video normale (Retire la Couleur et le Rev)
	Rev=`tput rev`		# Reverse video.
	Rms=`tput rmso`		# Retire le Rev (en conservant la Couleur)
	Hpa60=` tput hpa 60`	# Decale de 60car vers la droite.

#-----------------------------------------------------------------
# Interpretation of the Arguments :
#-----------------------------------------------------------------

	SCRIPT=$0
	ARGUMENTS=" $* "   # Comme cela ; tous les args sont entoures de blanc.

	case "$ARGUMENTS" in
	*" help "* | *" aide "* ) echo "$Syntax"  ; exit 0  ;;
	"  "			) F_MenuOperate   ; exit $? ;;
	esac

	# -S = Silent (No Question & Small display)
	# -B = Blind  (No Question &    No display)

	case "$ARGUMENTS" in
	*" -S "*	) SILENT=yes    BLIND=no  ;;
	*" -B "*	) SILENT=yes    BLIND=yes ;;
	*		) SILENT=yes    BLIND=no  ;; # it means : -S as default.
	esac

	if [ "$SILENT" = yes ]
	then ARGUMENTS=`echo "$ARGUMENTS" | sed -e 's/ -S / /' -e 's/ -B / /'`
	fi

	# For -notrace : no risk of confusion
	# (for -S we had to treat " -S " to avoid confusion with -Start ...) 
	case "$ARGUMENTS" in
	*"-notrace"*	) NOTRACE=yes
			  ARGUMENTS=`echo "$ARGUMENTS" | sed -e 's/-notrace//'`
			  ;;
	* 		) unset NOTRACE
			  ;;
	esac

	

#-----------------------------------------------------------------
# ------------ Interpretation of the command line ----------------
#-----------------------------------------------------------------

#--------------------------------------------
# Set the arguments into generic parameters :
#--------------------------------------------

	set -- `echo "$ARGUMENTS" | sed -e 's/-//g' `	# We remove all the "-"
	ACTION=$1   SUBPROD=$2   OBJECT=$3   OPTION=$4

#-----------------------------------------------------
# Set ORACLE_SID and LISTENER (depending of SUBPROD) :
#-----------------------------------------------------

	case "$SUBPROD" in
	base|instance|dumps|alert|dbalog|adr )
			LISTENER=dumb		# Already set to "dumb" above.
			ORACLE_SID=$OBJECT ;;
	sqlnet|listener|listalone )
			LISTENER=$OBJECT
			ORACLE_SID=`echo $LISTENER | cut -d_ -f2` ;;
	esac

#-----------------------------------------------------------------
# When [-S] or [-B] is present, then a Trace File is writen :
#-----------------------------------------------------------------

	case "$STANDARD" in
	S4D0 ) TrcDir=/exec/products/genexpl/logs ;;
	CB   ) TrcDir=/opt/operating/log/OracleAllOperating  ;;
	esac

	if [ "$NOTRACE" = yes ]
	then
		TrcFile=none
	else
		if [ ! -w "$TrcDir" ]
		then  echo "\t@ Error : The TraceDirectory $TrcDir"
		      echo "\t@ doesn't exist or not writable." ; exit 1 
		fi

		Date=`date "+%m%d-%H%M%S"`

		case "$STANDARD" in
		S4D0 ) TrcFile=$TrcDir/Oracle_${OBJECT}_${Date}.trc ;;
		CB   ) TrcFile=$TrcDir/Oracle_${OBJECT}_${Date}.log ;;
		esac

		exec 3>&2 1>$TrcFile 2>&1 
		chmod 644 $TrcFile 
	fi

#-----------------------------------------------------------------
# Clearing the old traces :
#-----------------------------------------------------------------

	# +30 means more than 30 days :
	# here : rm only concerns our current Instance or Listener : $OBJECT

	if [ "$SILENT" = yes ]
	then
	case "$STANDARD" in
	S4D0 ) find -L $TrcDir  -mtime +10  -name "Oracle_${OBJECT}_*.trc"  -exec rm -f {} \;
	;;
	CB   ) find -L $TrcDir  -mtime +10  -name "Oracle_${OBJECT}_*.log"  -exec rm -f {} \;
	;;
	esac
	fi
#

#-----------------------------------------------------------------
# Header of the Trace File :
#-----------------------------------------------------------------

    echo "
	@ -----------------------------------------------------------------
	  DATE      = `date '+%d/%m/%Y %H:%M:%S'`
	  SCRIPT    = $SCRIPT
	  ARGUMENTS = [$ARGUMENTS]
	@ TRACE     = $TrcFile
	  -----------------------------------------------------------------"

#----------------------------------------------------------
# Boite de compatibilite SyntaxeFrancais => SyntaxAnglais :
#----------------------------------------------------------

        case "$ACTION" in
        demarrer) ACTION=start ;;
        arreter ) ACTION=stop  ;;
        tuer    ) ACTION=kill  ;;
        purger  ) ACTION=clear ;;
        tester  ) ACTION=test  ;;
        esac

        case "$SUBPROD" in
        base    ) SUBPROD=instance ;;
        sqlnet  ) SUBPROD=listener ;;
        esac

        case "$OPTION" in
        demarre ) OPTION=started ;;
        arrete  ) OPTION=stopped ;;
        esac

#----------------------------------------
# Set and display the Oracle parameters :
#----------------------------------------

	F_Profile || F_End 1		# Instead of the .profile

	case "$STANDARD" in
	S4D0 ) FlagDir=/exec/FlagBlackOut	;;
	CB   ) FlagDir=/var/opt/FlagBlackOut	;;
	esac

	[ ! -d "$FlagDir" ] && echo "\t@ Warning: FlagDir $FlagDir not found."

	#--------------------------------------------------------------
	# DBNAME is only used inside DBASE.
	# DBASE  is only used for purges (in the 5 functions clear_XXX)
	#--------------------------------------------------------------

	unset DBNAME DBASE

	if [ -z "$DBNAME" ]		# Try for Single-Instance :
	then
	    TRY1=$ORACLE_SID		  
            [   -d /oradata/$TRY1 -a ! -d /data/ora/$TRY1 ] && DBASE=/oradata/$TRY1
            [ ! -d /oradata/$TRY1 -a   -d /data/ora/$TRY1 ] && DBASE=/data/ora/$TRY1
	    [ -n "$DBASE" ] && DBNAME=$ORACLE_SID
	fi

	if [ -z "$DBNAME" ]		# Try for Multi-Instance :
	then
	    TRY2=${ORACLE_SID%[1-9]}
            [   -d /oradata/$TRY2 -a ! -d /data/ora/$TRY2 ] && DBASE=/oradata/$TRY2
            [ ! -d /oradata/$TRY2 -a   -d /data/ora/$TRY2 ] && DBASE=/data/ora/$TRY2
	    [ -n "$DBASE" ] && DBNAME=${ORACLE_SID%[1-9]}
	fi

			    			# Infos pour la trace :
	echo "\tORATAB=$ORATAB
	DBNAME=$DBNAME
	ORACLE_SID=$ORACLE_SID
	ORACLE_HOME=$ORACLE_HOME"

	if [ "$SUBPROD" = listener ] 
	then echo "\tTNS_ADMIN=$TNS_ADMIN \n\tLISTENER=$LISTENER" 
	fi

	echo "\t---------------------------------------------------------------"

#----------------------
# Launch the function :
#----------------------

    case "$ACTION-$SUBPROD-$OPTION" in
	start-instance-			| test-instance-started     | \
	start-instance-restrict		| \
	start-instance-ARCH		| test-instance-ARCH        | \
	start-instance-NOARCH		| test-instance-NOARCH      | \
	stop-instance-			| test-instance-stopped     | \
	stop-instance-abortrestrictimmediate | stop-instance-abrestim | \
	start-listener-			| test-listener-started     | \
	stop-listener-			| test-listener-stopped     | \
	start-listalone-		| test-listalone-started    | \
	stop-listalone-			| test-listalone-stopped    )
	;;
	clear-dbalog-*	 | clear-adr-*  |  clear-dumps-*  | clear-alert-* | \
	clear-listener-* | clear-listalone-* )
	;;
	kill-instance-   ) ACTION=stop ; SUBPROD=instance ; OPTION=abort   ;;
	status-instance- ) ACTION=test ; SUBPROD=instance ; OPTION=started ;;
	status-listener- ) ACTION=test ; SUBPROD=listener ; OPTION=started ;;
	status-listalone-) ACTION=test ; SUBPROD=listalone ; OPTION=started ;;
	 
	*            )  echo "\n\t@ Syntax error :\n$Syntax"
			F_End 1 ;;
    esac

#-------------------------------------------------------------------------
		echo "\tLaunch F_${ACTION}_${SUBPROD} $OPTION"
		eval F_${ACTION}_${SUBPROD} $OPTION
		F_End $?
#-------------------------------------------------------------------------
# End OperateOracleAll.ksh
