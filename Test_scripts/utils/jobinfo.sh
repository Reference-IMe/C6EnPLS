#!/bin/bash

if [ $# -lt 1 ]; then
	echo -e "Usage: $0 JOB_NAME '\n' -v option to see verbose version '\n' -o to print information in csv format ';' separator"
	exit 1;
fi

USERDIR="/afs/enea.it/por/user/mcolonna/PFS/por/tirocinio"


#########################################################################################
# Analysis of input parameters 
#########################################################################################


MODE=0
if [ "$1" = "-v" ]; then
	MODE=1
	shift
elif [ "$1" = "-o" ]; then
	MODE=2
	shift
fi
 

JOB_NAME=$1


#########################################################################################
# Information retrieval from the job name
#########################################################################################

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
	RESDIR="${USERDIR}/results/balance/${ALGORITHM}/${PRECISION}/P${CALC_PROCS}/MS${MATRIX_SIZE}/" # Variabile eventualmente da cambiare
else
        RESDIR="${USERDIR}/results/nobalance/${ALGORITHM}/${PRECISION}/P${CALC_PROCS}/MS${MATRIX_SIZE}/" # Variabile eventualmente da cambiare
fi


#########################################################################################
# Output viewing
#########################################################################################

if [ ${MODE} -eq 1 ]; then

	echo -e "\n############################################################################################"
	echo "JOB INFORMATION"
	echo -e "############################################################################################\n"
	echo -e "JOB NAME: ${JOB_NAME}\n"
	echo -e "############################################################################################\n"

	echo 	-e 	" Algorithm:\t\t${ALGORITHM}\n"			\
			"Fault Tolerance:\t${FAULT_TOLERANCE}\n"	\
			"Number Faults:\t\t${NUM_FAULTS}\n"		\
			"Precision:\t\t${PRECISION}\n"			\
			"Calc Processes:\t${CALC_PROCS}\n"		\
			"Spare Processes:\t${SPARE_PROCS}\n"		\
			"Tot Processes:\t\t${TOT_PROCS}\n"		\
			"Matrix Size:\t\t${MATRIX_SIZE}\n"		\
			"Repetitions:\t\t${REPETITIONS}\n"		\
			"Wall Time:\t\t${WTIME}\n"			\
			"Nodes used:\t\t${NODES}\n"			\
			"Sockets Balance:\t${BALANCE}\n"		\
			"Num Proc x Socket:\t${NPERSOCKET}\n"		\
			"Results path: ${RESDIR}\n"			\
                        "Text file path: ${RESDIR}txt/${JOB_NAME}.txt\n"        	\
                        "Error file path: ${RESDIR}err/${JOB_NAME}.err\n"	\
                        "CSV file path: ${RESDIR}csv/${JOB_NAME}.csv\n"
	echo -e "############################################################################################"
elif [ ${MODE} -eq 2 ]; then
	printf "%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s\n" \
		"${ALGORITHM}" "${FAULT_TOLERANCE}" "${NUM_FAULTS}" "${PRECISION}" "${CALC_PROCS}" "${SPARE_PROCS}" \
	        "${TOT_PROCS}" "${MATRIX_SIZE}" "${REPETITIONS}" "${WTIME}" "${NODES}" "${BALANCE}" "${NPERSOCKET}"

else
	printf "%-12s %-8s %-9s %-13s %-10s %-10s %-12s %-12s %-9s %-10s %-12s %-9s %-13s\n" \
	"ALG: ${ALGORITHM}" "FT: ${FAULT_TOLERANCE}" "NFT: ${NUM_FAULTS}" "PR: ${PRECISION}" "CP: ${CALC_PROCS}" "SP: ${SPARE_PROCS}" \
        "TOTP: ${TOT_PROCS}" "MS: ${MATRIX_SIZE}" "REP: ${REPETITIONS}" "WT: ${WTIME}" "NODES: ${NODES}" "BAL: ${BALANCE}" "NxSock: ${NPERSOCKET}"
fi
