#!/bin/bash

if [ $# -ne 1 ]; then
	echo Usage: $0 JOB_NAME
	exit 1;
fi

JOB_NAME=$( echo $1 | sed "s/\.[^\.]*$//" )

ALGORITHM=$(echo "${JOB_NAME}" | grep -oP '.*(?=FT)')
MATRIX_SIZE=$(echo "${JOB_NAME}" | grep -oP '_ms\K\d+')
PRECISION=$(echo "${JOB_NAME}" |  grep -oP 'single|double')
BALANCE=$(echo "${JOB_NAME}" | grep -oP '_lb\K.')
CALC_PROCS=$(echo "${JOB_NAME}" | grep -oP '_cp\K\d+')

RESDIR="/afs/enea.it/por/user/mcolonna/PFS/por/tirocinio/results"			# Variabile eventualmente da cambiare

if [ "${BALANCE}" = "n" ]; then
	BLDIR="nobalance"
elif [ "${BALANCE}" = "y" ]; then
	BLDIR="balance"
else
	echo "Job name not valid"
fi

rm ${RESDIR}/${BLDIR}/${ALGORITHM}/${PRECISION}/P${CALC_PROCS}/MS${MATRIX_SIZE}/err/${JOB_NAME}.err
rm ${RESDIR}/${BLDIR}/${ALGORITHM}/${PRECISION}/P${CALC_PROCS}/MS${MATRIX_SIZE}/csv/${JOB_NAME}.csv
rm ${RESDIR}/${BLDIR}/${ALGORITHM}/${PRECISION}/P${CALC_PROCS}/MS${MATRIX_SIZE}/txt/${JOB_NAME}.txt
