2015.7.14 
create by FaN
---
不要再生产环境用，这就是写着玩的，练习shell。
请 主备库: 
echo "export LANG=en_CN.UTF-8" >> /etc/profile
source /etc/profile
因为我expect找的关键词是英文的，所以中文的截不到
primary内的文件放在/oracle/711目录下
standby内的文件放在/oracle/711目录下

安装前的那些包自己yum装
需要安装tcl expect(必须)！！！！

需要配置config.conf文件(ctrlfile文件的定制配置没写完，我注释掉了)

安装只需在主库以root用户执行dg.sh即可，脚本会判断是否需要创建oracle用户

相关日志文件：
安装oracle软件：setupDatabase.out
创建监听：    netca.log
创建实例：    dbca.log
其余操作的日志均在 dg.log中


后来发现，其实数据文件、控制文件、日志文件等都可以自定义大小位置、字符集、可选组件等等都可以自定义，只需要自己在脚本中生成.dbt文件即可


pdksh-5.2.14-37.el5_8.1.x86_64是centos 6.4安装oracle所需的依赖包

建议搞之前，做个快照。
