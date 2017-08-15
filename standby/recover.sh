#!/bin/bash
echo "开始收尾工作recover主库"
recc(){
su - oracle -c "sqlplus -S / as sysdba << !
set trimspool on feedback off pagesize 0 heading off
ALTER DATABASE RECOVER MANAGED STANDBY DATABASE USING CURRENT LOGFILE DISCONNECT FROM SESSION;
exit;
!
"
}
recc >> /oracle/711/dg.log 2>&1