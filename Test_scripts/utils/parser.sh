#!/bin/bash

if [ $# -lt 1 ]; then
        echo Usage: $0 JOB_NAME [ ERR_HANDLER_REPORT ]
        exit 1
fi

JOB_NAME=$1

BATCHDIR=$(dirname "$(readlink -f "$0")")
CMDDIR="${BATCHDIR}/../src"
#USERDIR="/afs/enea.it/por/user/mcolonna/"
USERDIR="/afs/enea.it/por/user/mcolonna/PFS/por/tirocinio"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

REPORT_DIR="${USERDIR}/reports"						# Variabile eventualmente da cambiare

if [ "$2" = "" ]; then
        REPORT_FILE="${REPORT_DIR}/${TIMESTAMP}_report_relaunch.txt"
	echo -e "ALG"'\t'"PREC"'\t'"M_SIZE"' \t'"REP"'\t'"CPROCS"'\t'"SPROCS"'\t'"TPROCS"'\t'"NODES"'\t'"FTO " \
        "FT"'\t'"NFS" "FL"'\t'"FR"'  '"SPK-CP" "BKF"'\t'"LD_BAL"'\t '"NxSOCK"'\t'"JOB_NAME"'\n' > ${REPORT_FILE}
else
        REPORT_FILE="$2"
fi

mkdir -p ${REPORT_DIR}

ALGORITHM=$(echo "${JOB_NAME}" | grep -oP '.*(?=FT)')
FAULT_TOLERANCE=$(echo "${JOB_NAME}" | grep -oP 'FT\K\d+')
MATRIX_SIZE=$(echo "${JOB_NAME}" | grep -oP '_ms\K\d+')
PRECISION=$(echo "${JOB_NAME}" |  grep -oP 'single|double')
BALANCE=$(echo "${JOB_NAME}" | grep -oP '_lb\K.')
CALC_PROCS=$(echo "${JOB_NAME}" | grep -oP '_cp\K\d+')
REPETITIONS=$(echo "${JOB_NAME}" | grep -oP '_r\K\d+')
#WTIME=$(echo "${JOB_NAME}" | grep -oP '_W\K\d+')
WTIME=40

if [ ${FAULT_TOLERANCE} -eq 0 ]; then
        ${CMDDIR}/no_ft_tester.sh ${CALC_PROCS} ${MATRIX_SIZE} ${PRECISION} ${REPETITIONS} ${ALGORITHM} ${BALANCE} ${WTIME} ${REPORT_FILE}
else
        NUM_FAULTS=$(echo "${JOB_NAME}" | grep -oP '_nf\K\d+')
        if [ "${ALGORITHM}" = "SPK" ]; then
                ${CMDDIR}/spk_ft_tester.sh ${CALC_PROCS} ${MATRIX_SIZE} ${PRECISION} ${REPETITIONS} ${FAULT_TOLERANCE} ${NUM_FAULTS} ${BALANCE} ${WTIME} ${REPORT_FILE}
        else
        	${CMDDIR}/ime_ft_tester.sh ${CALC_PROCS} ${MATRIX_SIZE} ${PRECISION} ${REPETITIONS} ${FAULT_TOLERANCE} ${NUM_FAULTS} ${ALGORITHM} ${BALANCE} ${WTIME} ${REPORT_FILE}
        fi
fi
