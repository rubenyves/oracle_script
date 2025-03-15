#!/bin/ksh

[ "$(whoami)" != "oracle" ] && echo "Please run the script as oracle user." && exit 1
[ $# -lt 1 ] && echo "Usage: $0 [ORACLE_SID]" && exit 1

source /opt/oracle/.profile
export ORACLE_SID=$1 

 rman target / <<-EOF
  delete force noprompt archivelog all; 
  exit;
EOF
 
