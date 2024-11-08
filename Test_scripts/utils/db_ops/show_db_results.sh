#!/bin/bash

if [ $# -eq 2 ];
then
	JOBID=$2
else
	JOBID=$1
	shift
fi

BATCHDIR=$(dirname "$(readlink -f "$0")")
QUERY="SELECT * FROM Colonna.forecast WHERE forecast.Jobid='${JOBID}';"

${BATCHDIR}/query.sh "$1" "${QUERY}"


