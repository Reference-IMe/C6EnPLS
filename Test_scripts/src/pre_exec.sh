#!/bin/bash

sleep 8

########################################################################
# Main paths
########################################################################

USERDIR="/afs/enea.it/por/user/mcolonna/PFS/por/tirocinio"
BATCHDIR=$(dirname "$(readlink -f "$0")")

########################################################################
# Preparing information to begin the job
########################################################################

LENGTH=$(( $2 * 20 ))
JOB_NAME=$1
JOB_ID=$( bjobs -noheader -o "jobid" -J "${JOB_NAME}" )

LIST=$( bjobs -noheader -o "exec_host:${LENGTH}" -J "${JOB_NAME}" | xargs )
NODES=($(echo ${LIST} | grep -o 'cresco6x[0-9]\+'))

START_TS=$( bjobs -W -noheader -J "${JOB_NAME}" | awk '{ print $14 }' | awk '{ gsub("-", " ");  print $1 " " $2 }' )
START_UTS=$( date --date="${START_TS}" +"%s" )
CURRENT_TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

########################################################################
# Insert information in the database to begin the job
########################################################################

insert_query="INSERT INTO Colonna.jobmichele VALUES ('${JOB_ID}','${JOB_NAME}','${CURRENT_TIMESTAMP}','${START_UTS}','R','0','${NODES[0]}',\
		'${NODES[1]}','${NODES[2]}','${NODES[3]}','${NODES[4]}','${NODES[5]}','${NODES[6]}','${NODES[7]}','${NODES[8]}',\
		'${NODES[9]}','${NODES[10]}','${NODES[11]}','${NODES[12]}','${NODES[13]}','${NODES[14]}','${NODES[15]}');"
${BATCHDIR}/../utils/db_ops/query.sh ${insert_query}

sleep 2

exit 0;
