#!/bin/ksh 

[ $(whoami) != 'oracle' ] && echo "Please run this script as oracle user" && exit 1
[ $# -lt 1 ] && echo "Usage: $0 [ORACLE_SID]" && exit 1 

export ORACLE_SID=$1

grep $ORACLE_SID /etc/oratab > /dev/null
test $? -ne 0 && echo "Incorrect SID." && exit 1

sqlplus -L -s / as sysdba <<< "
select * from (
select to_char(sysdate,'dd/mm/yyyy') as \"Date\", b.tablespace_name, tbs_size SizeGb, tbs_size-a.free_space UsedGb, trunc(((tbs_size-a.free_space)/tbs_size)*100, 1) UsedGbper
from  (select tablespace_name, round(sum(bytes)/1024/1024/1024 ,2) as free_space
       from dba_free_space
       group by tablespace_name) a,
      (select tablespace_name, sum(bytes)/1024/1024/1024 as tbs_size
       from dba_data_files
       group by tablespace_name) b
where a.tablespace_name(+)= b.tablespace_name
union
SELECT to_char(sysdate,'dd/mm/yyyy') as \"Date\", tablespace_name, round(SUM(bytes_used)/1024/1024/1024, 2) SizeGb, round((SUM(bytes_used)-SUM(bytes_free))/1024/1024/1024, 2) UsedGb, round(((SUM(bytes_used)-SUM(bytes_free))/nvl(SUM(bytes_used),1))*100,2) UsedGbper
FROM   V$temp_space_header
GROUP  BY tablespace_name ) order by 5 ;
exit;
"

sqlplus -L -s / as sysdba <<< "
SELECT A.tablespace_name tablespace, D.mb_total,
    SUM (A.used_blocks * D.block_size) / 1024 / 1024 mb_used,
    D.mb_total - SUM (A.used_blocks * D.block_size) / 1024 / 1024 mb_free
   FROM v$sort_segment A,
    (
   SELECT B.name, C.block_size, SUM (C.bytes) / 1024 / 1024 mb_total
    FROM v$tablespace B, v$tempfile C
     WHERE B.ts#= C.ts#
      GROUP BY B.name, C.block_size) D
    WHERE A.tablespace_name = D.name
    GROUP by A.tablespace_name, D.mb_total;
exit;

" 


