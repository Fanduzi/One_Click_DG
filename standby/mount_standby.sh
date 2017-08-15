#!/bin/bash
#Parsing the config file
errParam() {
  echo "[ERROR] \`$1' is empty, check configfile '$configfile'"
  echo ""
  exit
}

SOFTWARE_HOME=
ORACLE_SID=
INVENTORY_LOCATION=
ORACLE_BASE=
ORACLE_HOME=
DB_NAME=

configfile=/oracle/711/config.conf
if [ -f $configfile ]; then
  param=$(cat $configfile | tr -d "\015" | grep -v "^#" | grep -v "^$")
else
  echo "[ERROR] $configfile not found!"
  exit
fi


while read i
do
   key=$(echo "$i" | awk -F'=' '{print $1}')
   value=$(echo "$i" | awk -F'=' '{print $2}')
   [ "$key" == "SOFTWARE_HOME" ] && SOFTWARE_HOME=$value
   [ "$key" == "ORACLE_SID" ] && ORACLE_SID=$value
   [ "$key" == "INVENTORY_LOCATION" ] && INVENTORY_LOCATION=$value
   [ "$key" == "ORACLE_HOME" ] && ORACLE_HOME=$value
   [ "$key" == "ORACLE_BASE" ] && ORACLE_BASE=$value
   [ "$key" == "DB_NAME" ] && DB_NAME=$value
   [ "$key" == "ARCH" ] && ARCH=$value
   [ "$key" == "P_DB" ] && P_DB=$value
   [ "$key" == "P_IP" ] && P_IP=$value
   [ "$key" == "S_DB" ] && S_DB=$value
   [ "$key" == "S_IP" ] && S_IP=$value
   [ "$key" == "P_B_UNIQUE_NAME" ] && P_B_UNIQUE_NAME=$value
   [ "$key" == "S_B_UNIQUE_NAME" ] && S_B_UNIQUE_NAME=$value
   [ "$key" == "ctl" ] && ctl=$value
done <<< "$param"

[ "x$SOFTWARE_HOME" == "x" ] && errParam SOFTWARE_HOME
[ "x$ORACLE_SID" == "x" ] && ORACLE_SID=standby
[ "x$INVENTORY_LOCATION" == "x" ] && INVENTORY_LOCATION=/oracle/Inventory
[ "x$ORACLE_BASE" == "x" ] && ORACLE_BASE=/oracle
[ "x$ORACLE_HOME" == "x" ] && ORACLE_HOME=/oracle/db11g
[ "x$DB_NAME" == "x" ] && DB_NAME=orcl
[ "x$ARCH" == "x" ] && ARCH=/oracle/arch
[ "x$P_B_UNIQUE_NAME" == "x" ] && P_B_UNIQUE_NAME=primary
[ "x$S_B_UNIQUE_NAME" == "x" ] && S_B_UNIQUE_NAME=standby


cspfile_from_pfile(){
su - oracle -c "sqlplus -S / as sysdba << !
set trimspool on feedback off pagesize 0 heading off
create spfile from  pfile;
exit;
!
"
}

echo "create standby spfile"
echo
cspfile_from_pfile >> /oracle/711/dg.log 2>&1

lsnr(){
su - oracle -c "
lsnrctl start
"
}

lsnr >> /oracle/711/dg.log 2>&1


register(){
su - oracle -c "sqlplus -S / as sysdba << !
set trimspool on feedback off pagesize 0 heading off
alter system register;
exit;
!
"
}


mountoracle(){
Mount_Oracle=$(
su - oracle -c "sqlplus -S / as sysdba << !
set trimspool on feedback off pagesize 0 heading off
startup mount;
alter database add standby logfile '/oracle/oradata/standby/std_redo01.log' size 50m;
alter database add standby logfile '/oracle/oradata/standby/std_redo02.log' size 50m;
alter database add standby logfile '/oracle/oradata/standby/std_redo03.log' size 50m;
alter database add standby logfile '/oracle/oradata/standby/std_redo04.log' size 50m;
alter system register;
exit;
!
"
)
echo $Mount_Oracle | grep "Database mounted"
if [ $? -eq 0 ];then
        echo "Database Mounted Successfully!"
fi
} 

mountoracle >> /oracle/711/dg.log 2>&1

#register >> /oracle/711/dg.log 2>&1

add_p_stdlog(){
su - oracle -c "sqlplus -S / as sysdba << !
set trimspool on feedback off  pagesize 0 heading off
alter database add standby logfile '/oracle/oradata/standby/std_redo01.log' size 50m;
alter database add standby logfile '/oracle/oradata/standby/std_redo02.log' size 50m;
alter database add standby logfile '/oracle/oradata/standby/std_redo03.log' size 50m;
alter database add standby logfile '/oracle/oradata/standby/std_redo04.log' size 50m;
exit;
!
"
}


#echo "create standby redolog for primary"
#add_p_stdlog >> /oracle/711/dg.log 2>&1
