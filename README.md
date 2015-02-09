# zookeeper-nagios
shell scripts to monitor nodes on zookeeper that send status information to display on nagios

Most existing programs or tools that are used to monitor zookeeper can only supervise the general status of zookeeper, mostly using the 4 letter command of zookeeper. But in more circumstances we need to monitor particular node paths or data on zookeeper, which can be achieved by the ls /path1/path2 and get /path1/path2 commands of zookeeper. I didn't find any available software that can implement that funtionality. So I wrote this software to collect path information and data on zookeeper, you can modify my scripts to adjust to your application. Welcome of any suggestions or bug report.

This software contains two scripts and two configuration files. zk_monitor.sh should be put in nagios plugin path and zkJob.sh should be placed in zookeeper/bin. The two config files hosts.cfg and zookeeper.cfg should be put in nagios/etc/objects and be included in file nagios/etc/nagios.cfg.
