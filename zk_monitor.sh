#!/bin/sh

########################################################################
#  description: script to monitor zookeeper cluster
#        usage: zk_monitor.sh -s SERVER -k KEY 
#               SERVERS are the host and port information of zk servers, 
#               like "1.1.1.1:2181"
#               KEY is the project/service name, like "user","transfer"
#       author: zpf.073@gmail.com
#         date: 2015-02-06
########################################################################

LOG_FILE=`pwd`/monitor.log

log() {
	if [ $# -lt 2 ];then
		return
	fi	
	echo "`date +%Y-%m-%d-%H:%M:%S` [`echo $1 | tr '[a-z]' '[A-Z]'`] $2" >> $LOG_FILE
}

STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

# check arguments:
#echo "checking arguments...server:$2 project:$4"
log info "checking arguments...server:$2 project:$4"
if [ $# -ne 4 ];then
	log error "invalid argument number:$#"
	exit $STATE_UNKNOWN
fi
SERVER=$2
ZK_HOST=`echo $SERVER | awk -F ":" '{print $1}'`
ZK_PORT=`echo $SERVER | awk -F ":" '{print $2}'`

# test if ZK_HOST can be connected:
#RECV_PK=`ping $ZK_HOST -w 4 | tail -2 | head -1 | awk -F "," '{print $2}' | awk '{print $1}'`
#if [ $RECV_PK -le 0 ];then
#	log error "cannot connect to remote server:$ZK_HOST"
#	exit $STATE_UNKNOWN
#fi
NUM_ZK_PORT=`echo $ZK_PORT | bc`
if [ $NUM_ZK_PORT -le 0 ];then
	log error "zk port invalid:$ZK_PORT"
	echo "zk port invalid:$ZK_PORT"
	exit $STATE_UNKNOWN
fi

PROJECT=$4

ZK_PATH=/usr/local/zookeeper-3.4.6
ZK_SHELL_FILE=$ZK_PATH/bin/zkJob.sh
# read config from zookeeper:
SERVICE_LIST=`ssh deployer@$ZK_HOST "cd $ZK_PATH/bin; \
	sh $ZK_SHELL_FILE -g /$PROJECT/conf/service_list | tail -2 | head -1"`

# check if service list valid:
REGEX_IP_PORT="(2[0-4][0-9]|25[0-5]|1[0-9][0-9]|[1-9]?[0-9])(\.(2[0-4][0-9]|25[0-5]|1[0-9][0-9]|[1-9]?[0-9])){3}:[0-9]{1,}"
SECTION_NUM=`echo $SERVICE_LIST | awk -F , '{print NF}'`
SERVICE_NUM=$SECTION_NUM
for SERVICE_IND in $( seq 1 $SECTION_NUM )
do
	SERVICE_VALID=`echo $SERVICE_LIST | awk -F , '{print $'$SERVICE_IND'}' | grep -c -E "$REGEX_IP_PORT"`
	if [ $SERVICE_VALID -le 0 ];then
		log error "service list invalid:$SERVICE_LIST"
		SERVICE_NUM=0
		SERVICE_LIST=""
		break
	fi
done
log info "configured service list:$SERVICE_LIST"
log info "configured service num:$SERVICE_NUM"
ALIVE_SERVICE_NUM=0
ALIVE_SERVICE_LIST=""

PROJECT_SERVER=""
PROJECT_SERVERS=`ssh deployer@$ZK_HOST "cd $ZK_PATH/bin; \
	sh $ZK_SHELL_FILE -l /$PROJECT | tail -2 | head -1"`

SERVER_NUM=`echo $PROJECT_SERVERS | awk -F , '{print NF}'`

PROJECT_SERVERS_LEN=`expr $PROJECT_SERVERS_LEN - 2`
PROJECT_SERVERS=`echo $PROJECT_SERVERS | awk -F [ '{print $2}'`

for IND in $( seq 1 $SERVER_NUM )
do
	PROJECT_SERVER=`echo $PROJECT_SERVERS | awk -F , '{print $'$IND'}' | awk '{print $1}'`
	if [ "$PROJECT_SERVER"x = "confx" ];then
		continue
	fi

	PROJECT_PORTS=`ssh deployer@$ZK_HOST "cd $ZK_PATH/bin; \
			sh $ZK_SHELL_FILE -l /$PROJECT/$PROJECT_SERVER | tail -2 | head -1"`
	PORT_NUM=`echo $PROJECT_PORTS | awk -F , '{print NF}'`
	PLAY_PORT_NUM=`echo $PROJECT_PORTS | awk -F , '{for(i=1;i<=NF;i++) print $i}' | grep play | wc -l`
	ALIVE_SERVICE_NUM=`expr $ALIVE_SERVICE_NUM + $PLAY_PORT_NUM`
	SERVICE_INFO=""
	PROJECT_PORTS="${PROJECT_PORTS%]}"
	PROJECT_PORTS=`echo $PROJECT_PORTS | awk -F [ '{print $2}'`

	for PORT_IND in $( seq 1 $PORT_NUM )
	do
                SERVICE_INFO=`echo $PROJECT_PORTS | awk -F , '{print $'$PORT_IND'}'`
		if [ `echo $SERVICE_INFO | grep -c play` -gt 0 ];then
			PLAY_PORT=`echo $SERVICE_INFO | awk  -F : '{print $2}'`
			if [ "$ALIVE_SERVICE_LIST"x = "x" ];then
                		ALIVE_SERVICE_LIST=`echo $PROJECT_SERVER:$PLAY_PORT`
			else
				ALIVE_SERVICE_LIST=`echo $ALIVE_SERVICE_LIST,$PROJECT_SERVER:$PLAY_PORT`
        		fi
		fi
	done
done

log info "ALIVE_SERVICE_LIST:$ALIVE_SERVICE_LIST"

log info  "ALIVE_SERVICE_NUM:$ALIVE_SERVICE_NUM"

if [ $ALIVE_SERVICE_NUM -lt $SERVICE_NUM -a $ALIVE_SERVICE_NUM -gt 0 ];then
	log warn "alive service list:$ALIVE_SERVICE_LIST"
	log warn "configured service list:$SERVICE_LIST"
	echo -e "alive service list:$ALIVE_SERVICE_LIST\nconfigured service list:$SERVICE_LIST"
	exit $STATE_WARNING
elif [ $ALIVE_SERVICE_NUM -eq 0 -a $SERVICE_NUM -gt 0 ];then
	log error "alive service list:$ALIVE_SERVICE_LIST"
	log error "configured service list:$SERVICE_LIST"
	echo -e "alive service list:$ALIVE_SERVICE_LIST\nconfigured service list:$SERVICE_LIST"
	exit $STATE_CRITICAL
else
	log info "alive service list:$ALIVE_SERVICE_LIST"
	log info "configured service list:$SERVICE_LIST"
	echo -e "alive service list:$ALIVE_SERVICE_LIST\nconfigured service list:$SERVICE_LIST"
	exit $STATE_OK
fi





