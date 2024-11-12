#!/bin/bash

if [ "$#" -lt 1  ];then
	echo "Query missing"
	exit 1;
fi

if [ "$1" = "-noheader" ]; then
	shift
        echo "$@"  | mysql -h 192.107.70.130 -u jobanalizer --password=aboutyourJOBS_2021 --skip-column-names
else
        echo "$@"  | mysql -h 192.107.70.130 -u jobanalizer --password=aboutyourJOBS_2021
fi
