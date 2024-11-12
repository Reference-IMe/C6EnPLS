#!/bin/bash

sleep 2

########################################################################
# Main paths
########################################################################

BATCHDIR=$(dirname "$(readlink -f "$0")")
USERDIR="/afs/enea.it/por/user/mcolonna/PFS/por/tirocinio"


########################################################################
# Preparing information to end the job
########################################################################

LENGTH=$(( $2 * 20 ))
JOB_NAME=$1
JOB_ID=$( bjobs -a -noheader -o "jobid" -J "${JOB_NAME}" )

LIST=$( bjobs -a -noheader -o "exec_host:${LENGTH}" -J "${JOB_NAME}" | xargs )
NODES=($(echo ${LIST} | grep -o 'cresco6x[0-9]\+'))

START_TS=$( bjobs -aW -noheader -J "$1" | awk '{ print $14 }' | awk '{ gsub("-", " ");  print $1 " " $2 }' )
START_UTS=$( date --date="${START_TS}" +"%s" )
CURRENT_TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

########################################################################
# Insert information in the database to end the job
########################################################################

update_query="UPDATE Colonna.jobmichele SET jobmichele.Lock='D' where jobmichele.Jobid='${JOB_ID}';" 

#insert_query="INSERT INTO Colonna.jobmichele VALUES ('${JOB_ID}','${JOB_NAME}','${CURRENT_TIMESTAMP}','${START_UTS}','D','0','${NODES[0]}',\
#                '${NODES[1]}','${NODES[2]}','${NODES[3]}','${NODES[4]}','${NODES[5]}','${NODES[6]}','${NODES[7]}','${NODES[8]}',\
#                '${NODES[9]}','${NODES[10]}','${NODES[11]}','${NODES[12]}','${NODES[13]}','${NODES[14]}','${NODES[15]}');"

${BATCHDIR}/../utils/db_ops/query.sh ${update_query}

sleep 6

########################################################################
# Export data from database to csv file
########################################################################

TODAY=$(date +"%Y%m%d")
DATADIR="${USERDIR}/energy_data"
DATA_FILE=${DATADIR}/${TODAY}_measures.csv

if [ -e ${DATA_FILE} ] && [ "$(cat ${DATA_FILE})" != "" ]; then
        ${BATCHDIR}/../utils/db_ops/show_db_results.sh -noheader ${JOB_ID} >> ${DATA_FILE}
else
        mkdir -p ${DATADIR}
        ${BATCHDIR}/../utils/db_ops/show_db_results.sh ${JOB_ID} > ${DATA_FILE}
fi

########################################################################
# Write job info in the jobs file
########################################################################

INFODIR="${USERDIR}/jobs_data"
INFO_FILE=${INFODIR}/${TODAY}_jobs.txt

END_TS=$( bjobs -aW -noheader -J "$1" | awk '{ print $15 }' | awk '{ gsub("-", " ");  print $1 " " $2 }' )
END_UTS=$( date --date="${END_TS}" +"%s" )

if [ -e ${INFO_FILE} ]; then
	echo "${JOB_ID}" "${JOB_NAME}" "${START_UTS}" "${END_UTS}" "${LIST}" >> ${INFO_FILE}
else
        mkdir -p ${INFODIR}
        echo "${JOB_ID}" "${JOB_NAME}" "${START_UTS}" "${END_UTS}" "${LIST}" > ${INFO_FILE}
fi

########################################################################
# Update energy field in the database
########################################################################

energy_query="UPDATE Colonna.jobmichele SET jobmichele.energy=(SELECT SUM(forecast.delta_e) FROM Colonna.forecast WHERE forecast.Jobid='${JOB_ID}' \
AND forecast.timestamp_measure>"${START_UTS}" AND forecast.timestamp_measure<="${END_UTS}") where jobmichele.Jobid="${JOB_ID}";"
${BATCHDIR}/../utils/db_ops/query.sh ${energy_query}

########################################################################
# Update energy field in the database
########################################################################

${BATCHDIR}/../utils/db_ops/query.sh "DELETE FROM Colonna.forecast where forecast.Jobid='${JOB_ID}';"

exit 0;
