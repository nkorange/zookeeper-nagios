# zookeeper-nagios
Shell scripts to monitor nodes on zookeeper that send status information to display on nagios

This software contains two scripts and two configuration files. zk_monitor.sh should be put in nagios plugin path and zkJob.sh should be placed in zookeeper/bin. The two config files hosts.cfg and zookeeper.cfg should be put in nagios/etc/objects and be included in file nagios/etc/nagios.cfg.
