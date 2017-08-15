#!/bin/bash
echo "#################################################"                                               
echo "#                                               #"
echo "#                                               #"
echo "#                FaN's Script                   #"
echo "#                                               #"
echo "#                                               #"
echo "#################################################"

service iptables stop

SETPASSWD(){
#set password
expect -c "
           set timeout 2;
           spawn passwd oracle
           expect {
               password { send \"oracle\r\"; exp_continue }
               *assword* { send \"oracle\r\" }
           };
           "
}

#create user and group
cat /etc/passwd|awk -F':' '{print $1}'|grep 'oracle\>' > /dev/null
result=$?
if [ "$result" == "1" ];then
	echo "user oracle does not exist,Starting to create user!"
	/usr/sbin/groupadd oinstall > /dev/null
	/usr/sbin/groupadd dba > /dev/null
	/usr/sbin/useradd -g oinstall -G dba -d /home/oracle oracle
	cat /etc/passwd|awk -F':' '{print $1}'|grep 'oracle\>' > /dev/null
	result1=$?
	if [ "$result1" == "0" ];then
		echo "user oracle has been created"
	else
		echo "we has a few problems during creating the user,please check!"
	fi
#set passwd
	SETPASSWD >> /dev/null
	echo " The user oracle's password is set to oracle "
#chown chmod for /oracle
	chown oracle:oinstall /oracle
	chmod 755 /oracle
	chown oracle:oinstall /oracle/711
	chmod 755 /oracle/711
elif [ "$result" == "0" ];then
	echo "user oracle have already been created"
fi



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
[ "x$ORACLE_SID" == "x" ] && ORACLE_SID=orcl
[ "x$INVENTORY_LOCATION" == "x" ] && INVENTORY_LOCATION=/oracle/Inventory
[ "x$ORACLE_BASE" == "x" ] && ORACLE_BASE=/oracle
[ "x$ORACLE_HOME" == "x" ] && ORACLE_HOME=/oracle/db11g
[ "x$DB_NAME" == "x" ] && DB_NAME=orcl
[ "x$ARCH" == "x" ] && ARCH=/oracle/arch
[ "x$P_B_UNIQUE_NAME" == "x" ] && P_B_UNIQUE_NAME=primary
[ "x$S_B_UNIQUE_NAME" == "x" ] && S_B_UNIQUE_NAME=standby

echo
echo "#################################################"
echo "SOFTWARE_HOME is $SOFTWARE_HOME"
echo "ORACLE_SID is $ORACLE_SID"
echo "INVENTORY_LOCATION is $INVENTORY_LOCATION"
echo "ORACLE_BASE is $ORACLE_BASE"
echo "ORACLE_HOME is $ORACLE_HOME"
echo "DB_NAME is $DB_NAME"
echo "Archivelogs are in $ARCH"
#echo "Controlfiles are in $ctl"

cont="&quot;$ctl&quot;"

set_host(){
cat >> /etc/hosts << EOF
$P_IP	$P_DB
$S_IP	$S_DB
EOF
}

set_host

# Set up the shell variables:
echo "EDITOR=vi" >> /home/oracle/.bash_profile
echo "export EDITOR" >> /home/oracle/.bash_profile
echo "umask 022" >> /home/oracle/.bash_profile
echo "export ORACLE_SID=standby" >> /home/oracle/.bash_profile
echo "export ORACLE_BASE=$ORACLE_BASE" >> /home/oracle/.bash_profile
echo "export ORACLE_HOME=$ORACLE_HOME" >> /home/oracle/.bash_profile
echo "export PATH=$ORACLE_HOME/bin:$GRID_HOME/bin:$PATH" >> /home/oracle/.bash_profile
echo "export LD_LIBRARY_PATH=$ORACLE_HOME/lib:$ORACLE_HOME/rdbms/lib:/lib:/usr/lib" >> /home/oracle/.bash_profile
echo "export CLASSPATH=$ORACLE_HOME/JRE:$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib:$ORACLE_HOME/network/jlib" >> /home/oracle/.bash_profile
echo "stty erase ^h" >> /home/oracle/.bash_profile


#preinstall 
echo "#add for database" >> /etc/sysctl.conf
echo "fs.file-max = 6815744" >> /etc/sysctl.conf
echo "net.ipv4.ip_local_port_range = 9000 65500" >> /etc/sysctl.conf
echo "net.core.rmem_max=262144" >> /etc/sysctl.conf
echo "net.core.rmem_max = 4194304" >> /etc/sysctl.conf
echo "net.core.wmem_max=262144" >> /etc/sysctl.conf
echo "net.core.wmem_max = 1048576" >> /etc/sysctl.conf
echo "fs.aio-max-nr = 1048576" >> /etc/sysctl.conf
echo "kernel.shmmni = 4096" >> /etc/sysctl.conf
echo "kernel.shmmax = 957691904" >> /etc/sysctl.conf
echo "kernel.shmall = 2097152" >> /etc/sysctl.conf
echo "kernel.sem = 250 32000 100 128" >> /etc/sysctl.conf
echo "net.core.rmem_default = 262144" >> /etc/sysctl.conf
echo "net.core.wmem_default = 262144" >> /etc/sysctl.conf

sysctl -p >> /dev/null

echo "oracle soft nproc 2047" >> /etc/security/limits.conf
echo "oracle hard nproc 16384" >> /etc/security/limits.conf
echo "oracle soft nofile 1024" >> /etc/security/limits.conf
echo "oracle hard nofile 65536" >> /etc/security/limits.conf

echo "session    required    pam_limits.so" >>/etc/pam.d/login

echo "if [ $USER = "oracle" ] || [ $USER = "grid" ]; then" >> /etc/profile
echo "if [ $SHELL = "/bin/ksh" ]; then" >> /etc/profile
echo "ulimit -p 16384" >> /etc/profile
echo "ulimit -n 65536" >> /etc/profile
echo "else" >> /etc/profile
echo "ulimit -u 16384 -n 65536" >> /etc/profile
echo "fi" >> /etc/profile
echo "umask 022" >> /etc/profile
echo "fi" >> /etc/profile

#make db_install.rsp
mk_db_install(){
	echo "oracle.install.responseFileVersion=/oracle/install/rspfmt_dbinstall_response_schema_v11_2_0" >> db_install.rsp
	echo "oracle.install.option=INSTALL_DB_SWONLY" >> db_install.rsp
	echo "ORACLE_HOSTNAME=$HOSTNAME" >> db_install.rsp
	echo "UNIX_GROUP_NAME=oinstall" >> db_install.rsp
	echo "INVENTORY_LOCATION=$INVENTORY_LOCATION" >> db_install.rsp
	echo "SELECTED_LANGUAGES=zh_CN,en" >> db_install.rsp
	echo "ORACLE_HOME=$ORACLE_HOME" >> db_install.rsp
	echo "ORACLE_BASE=$ORACLE_BASE" >> db_install.rsp
	echo "oracle.install.db.InstallEdition=EE" >> db_install.rsp
	echo "oracle.install.db.EEOptionsSelection=false" >> db_install.rsp
	echo "oracle.install.db.optionalComponents=" >> db_install.rsp
	echo "oracle.install.db.DBA_GROUP=dba" >> db_install.rsp
	echo "oracle.install.db.OPER_GROUP=oinstall" >> db_install.rsp
	echo "oracle.install.db.CLUSTER_NODES=" >> db_install.rsp
	echo "oracle.install.db.isRACOneInstall=false" >> db_install.rsp
	echo "oracle.install.db.racOneServiceName=" >> db_install.rsp
	echo "oracle.install.db.config.starterdb.type=GENERAL_PURPOSE" >> db_install.rsp
	echo "oracle.install.db.config.starterdb.globalDBName=" >> db_install.rsp
	echo "oracle.install.db.config.starterdb.SID=" >> db_install.rsp
	echo "oracle.install.db.config.starterdb.characterSet=" >> db_install.rsp
	echo "oracle.install.db.config.starterdb.memoryOption=false" >> db_install.rsp
	echo "oracle.install.db.config.starterdb.memoryLimit=" >> db_install.rsp
	echo "oracle.install.db.config.starterdb.installExampleSchemas=false" >> db_install.rsp
	echo "oracle.install.db.config.starterdb.enableSecuritySettings=true" >> db_install.rsp
	echo "oracle.install.db.config.starterdb.password.ALL=" >> db_install.rsp
	echo "oracle.install.db.config.starterdb.password.SYS=" >> db_install.rsp
	echo "oracle.install.db.config.starterdb.password.SYSTEM=" >> db_install.rsp
	echo "oracle.install.db.config.starterdb.password.SYSMAN=" >> db_install.rsp
	echo "oracle.install.db.config.starterdb.password.DBSNMP=" >> db_install.rsp
	echo "oracle.install.db.config.starterdb.control=DB_CONTROL" >> db_install.rsp
	echo "oracle.install.db.config.starterdb.gridcontrol.gridControlServiceURL=" >> db_install.rsp
	echo "oracle.install.db.config.starterdb.automatedBackup.enable=false" >> db_install.rsp
	echo "oracle.install.db.config.starterdb.automatedBackup.osuid=" >> db_install.rsp
	echo "oracle.install.db.config.starterdb.automatedBackup.ospwd=" >> db_install.rsp
	echo "oracle.install.db.config.starterdb.storageType=" >> db_install.rsp
	echo "oracle.install.db.config.starterdb.fileSystemStorage.dataLocation=" >> db_install.rsp
	echo "oracle.install.db.config.starterdb.fileSystemStorage.recoveryLocation=" >> db_install.rsp
	echo "oracle.install.db.config.asm.diskGroup=" >> db_install.rsp
	echo "oracle.install.db.config.asm.ASMSNMPPassword=" >> db_install.rsp
	echo "MYORACLESUPPORT_USERNAME=" >> db_install.rsp
	echo "MYORACLESUPPORT_PASSWORD=" >> db_install.rsp
	echo "SECURITY_UPDATES_VIA_MYORACLESUPPORT=false" >> db_install.rsp
	echo "DECLINE_SECURITY_UPDATES=true" >> db_install.rsp
	echo "PROXY_HOST=" >> db_install.rsp
	echo "PROXY_PORT=" >> db_install.rsp
	echo "PROXY_USER=" >> db_install.rsp
	echo "PROXY_PWD=" >> db_install.rsp
	echo "PROXY_REALM=" >> db_install.rsp
	echo "COLLECTOR_SUPPORTHUB_URL=" >> db_install.rsp
	echo "oracle.installer.autoupdates.option=SKIP_UPDATES" >> db_install.rsp
	echo "oracle.installer.autoupdates.downloadUpdatesLoc=" >> db_install.rsp
	echo "AUTOUPDATES_MYORACLESUPPORT_USERNAME=" >> db_install.rsp
	echo "AUTOUPDATES_MYORACLESUPPORT_PASSWORD=" >> db_install.rsp
}

#mk db_install.rsp
mk_db_install
echo "db_install.rsp has been created"
echo 
#chown chmod db_install.rsp
chown oracle:oinstall db_install.rsp
chmod 755 db_install.rsp


#mkdir ORACLE_HOME ORACLE_BASE INVENTORY_LOCATION
if [ ! -d "$ORACLE_BASE" ];then
	mkdir -p $ORACLE_BASE
fi

if [ ! -d "$ORACLE_HOME" ];then
	mkdir -p $ORACLE_HOME
fi

if [ ! -d "$INVENTORY_LOCATION" ];then
	mkdir -p $INVENTORY_LOCATION
fi

if [ ! -d "$ARCH" ];then
	mkdir -p $ARCH
fi

chown -R oracle:oinstall $ORACLE_BASE
chown -R oracle:oinstall $ORACLE_HOME
chown -R oracle:oinstall $ARCH
chown -R oracle:oinstall $INVENTORY_LOCATION



#install oracle software
setupDatabase() {
  runStr="
  cd $SOFTWARE_HOME
  nohup ./runInstaller -silent -force -responseFile /oracle/711/db_install.rsp >> /oracle/711/setupDatabase.out 2>&1 &
  "
  su - oracle -c "$runStr"
  while true
  do
     echo -n "."
     sleep 3s
     grep "Successfully Setup Software" /oracle/711/setupDatabase.out >> /dev/null
     if [ $? -eq 0 ]; then
       sh ${INVENTORY_LOCATION}/orainstRoot.sh
       sh ${ORACLE_HOME}/root.sh
       break
     fi 
   done
}

sleep 1s
echo "steup oracle database..."
setupDatabase
echo "steup succsed."

listenrsp(){
cat >> /oracle/711/listen.rsp << EOF
[GENERAL]
RESPONSEFILE_VERSION="11.2"
CREATE_TYPE="CUSTOM"
[oracle.net.ca]
INSTALLED_COMPONENTS={"server","net8","javavm"}
INSTALL_TYPE=""typical""
LISTENER_NUMBER=1
LISTENER_NAMES={"LISTENER"}
LISTENER_PROTOCOLS={"TCP;1521"}
LISTENER_START=""LISTENER""
NAMING_METHODS={"TNSNAMES","ONAMES","HOSTNAME"}
NSN_NUMBER=1
NSN_NAMES={"EXTPROC_CONNECTION_DATA"}
NSN_SERVICE={"PLSExtProc"}
NSN_PROTOCOLS={"TCP;HOSTNAME;1521"}
EOF
}

listenrsp
chown oracle:oinstall /oracle/711/listen.rsp
chmod 755 /oracle/711/listen.rsp

netcac(){
	cmd="
	nohup netca -silent -responseFile /oracle/711/listen.rsp >> /oracle/711/netca.log 2>&1 &
	"
	su - oracle -c "$cmd"
	while true
	do
		echo -n "."
		sleep 1s
		grep -E 'The exit code is 0|退出代码是0' /oracle/711/netca.log >> /dev/null
		if [ $? -eq 0 ]; then
			echo "Listener Successfully Created"
			break
		fi
	done
}

sleep 1s
echo "starting create listener..."
netcac
echo "Create Successfully"