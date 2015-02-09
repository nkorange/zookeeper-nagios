#!/bin/bash

ZK_OP=$1
ZK_PATH=$2

if [ "$1"x = "-lx" ];then
	ZK_OP="ls"
elif [ "$1"x = "-gx" ];then
	ZK_OP="get"
fi

sh ./zkCli.sh << EOF 2>/dev/null 
	$ZK_OP $ZK_PATH
EOF

