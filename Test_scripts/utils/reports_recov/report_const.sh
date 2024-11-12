#!/bin/bash

if [ $# -ne 1 ]; then
	echo usage: $0 report_file
	exit 1
fi 

REPORT_FILE=$1


printf "%-10s %-10s %-3s %-3s %-7s %-7s %-7s %-7s %-6s %-3s %-3s %-7s %-4s %-5s %-7s %-3s %-4s %-100s\n" \
        "ALGORITHM" "PRECISION" "FT" "NF" "CPROCS" "SPROCS" "TPROCS" "MATSIZE" "NODES" "FL" "FR" "SPK-CP" \
        "BKF" "SBAL" "NxSOCK" "R" "WT" "JOB_NAME" > ${REPORT_FILE}


JOBS=$(cat ./recov.txt | xargs)

for JOB_NAME in ${JOBS}
do

	ALGORITHM=$(echo "${JOB_NAME}" | grep -oP '.*(?=FT)')
	FAULT_TOLERANCE=$(echo "${JOB_NAME}" | grep -oP 'FT\K\d+')
	MATRIX_SIZE=$(echo "${JOB_NAME}" | grep -oP '_ms\K\d+')
	PRECISION=$(echo "${JOB_NAME}" |  grep -oP 'single|double')
	BALANCE=$(echo "${JOB_NAME}" | grep -oP '_lb\K.')
	CALC_PROCS=$(echo "${JOB_NAME}" | grep -oP '_cp\K\d+')
	TOT_PROCS=$(echo "${JOB_NAME}" | grep -oP '_tnp\K\d+')
	SPARE_PROCS=$(( TOT_PROCS - CALC_PROCS ))
	REPETITIONS=$(echo "${JOB_NAME}" | grep -oP '_r\K\d+')
	WTIME=$(echo "${JOB_NAME}" | grep -oP '_W\K\d+')
	NUM_FAULTS=$(echo "${JOB_NAME}" | grep -oP '_nf\K\d+')
	NODES=$(( TOT_PROCS%48 == 0 ? TOT_PROCS/48 : TOT_PROCS/48+1 ))

	NPERSOCKET="-"
	if [ "${BALANCE}" == "y" ]; then
	        NPERSOCKET=$(( TOT_PROCS%(NODES*2) == 0 ? TOT_PROCS/(NODES*2) : TOT_PROCS/(NODES*2)+1 ))
	fi

	if [ ${FAULT_TOLERANCE} -eq 0 ];then
		printf "%-10s %-10s %-3s %-3s %-7s %-7s %-7s %-7s %-6s %-3s %-3s %-7s %-4s %-5s %-7s %-3s %-4s %-100s\n" \
	     	"${ALGORITHM}" "${PRECISION}" "-" "-" "${CALC_PROCS}" "0" "${CALC_PROCS}" "${MATRIX_SIZE}" \
        	"${NODES}" "-" "-" "-" "-" "${BALANCE^}" "${NPERSOCKET}" "${REPETITIONS}" "${WTIME}" "${JOB_NAME}" >> ${REPORT_FILE}
	else
		if [ "${ALGORITHM}" = "IMeCO" ]; then
			printf "%-10s %-10s %-3s %-3s %-7s %-7s %-7s %-7s %-6s %-3s %-3s %-7s %-4s %-5s %-7s %-3s %-4s %-100s\n" \
	        	"${ALGORITHM}ft" "${PRECISION}" "${FAULT_TOLERANCE}" "${NUM_FAULTS}" "${CALC_PROCS}" "${SPARE_PROCS}" \
		        "${TOT_PROCS}" "${MATRIX_SIZE}" "${NODES}" "2" "2" "-" "-" "${BALANCE^}" "${NPERSOCKET}" \
		        "${REPETITIONS}" "${WTIME}" "${JOB_NAME}" >> ${REPORT_FILE}	
		else

			SPK_CHECKPOINT=$(( MATRIX_SIZE/2 ))

			GRID_SIZE=$(echo "sqrt(${CALC_PROCS})" | bc)

			if [ ${GRID_SIZE} -eq 10 ] || [ ${GRID_SIZE} -eq 20 ] || [ ${GRID_SIZE} -eq 22 ]; then
			        SPK_BLOCKING_FACTOR=24
			elif [ ${MATRIX_SIZE} -eq 26400 ]; then
			        SPK_BLOCKING_FACTOR=25
			elif ([ ${MATRIX_SIZE} -eq 31680 ] && [ ${GRID_SIZE} -ne 16 ]) || \
			        ([ $(( MATRIX_SIZE % 21120 )) -eq 0 ] && ( [ ${GRID_SIZE} -eq 8 ] || [ ${GRID_SIZE} -eq 16 ])) || \
			        ([ ${MATRIX_SIZE} -eq 15840 ] && ([ ${GRID_SIZE} -eq 6 ] || [ ${GRID_SIZE} -eq 12 ])) || \
			        ([ ${MATRIX_SIZE} -eq 10560 ] && [ ${GRID_SIZE} -eq 8 ]); then
			        SPK_BLOCKING_FACTOR=24
			else
			        SPK_BLOCKING_FACTOR=22
			fi

			printf "%-10s %-10s %-3s %-3s %-7s %-7s %-7s %-7s %-6s %-3s %-3s %-7s %-4s %-5s %-7s %-3s %-4s %-100s\n" \
			        "SPKft" "${PRECISION}" "${FAULT_TOLERANCE}" "${NUM_FAULTS}" "${CALC_PROCS}" "${SPARE_PROCS}" \
			        "${TOT_PROCS}" "${MATRIX_SIZE}" "${NODES}" "2" "2" "${SPK_CHECKPOINT}" "${SPK_BLOCKING_FACTOR}" \
			        "${BALANCE^}" "${NPERSOCKET}" "${REPETITIONS}" "${WTIME}" "${JOB_NAME}" >> ${REPORT_FILE}
		fi



	fi

done

