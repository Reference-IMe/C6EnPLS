#!/bin/bash

########################################################################
# Parameter check
########################################################################

if [ "$#" -lt 9 ]; then
        echo "Usage: $0 CALC_PROCS MATRIX_SIZE PRECISION REPETITIONS FAULT_TOLERANCE NUM_FAULTS BALANCE W_TIME REPORT_FILE"
	exit 1
fi

echo "Submitting:"

########################################################################
# Main paths
########################################################################

RUN_CMD="launch.sh"
PRE_EXEC="pre_exec.sh"
POST_EXEC="post_exec.sh"
#USERDIR="/afs/enea.it/por/user/mcolonna"
USERDIR="/afs/enea.it/por/user/mcolonna/PFS/por/tirocinio"
MATRIXDIR="/afs/enea.it/fra/user/artioli/PFS/tmp/data/test_matrices"
BATCHDIR=$(dirname "$(readlink -f "$0")")

########################################################################
# Input parameters analisys
########################################################################

CALC_PROCS=$1
MATRIX_SIZE=$2
PRECISION=$3
REPETITIONS=$4
FAULT_TOLERANCE=$5
NUM_FAULTS=$6
BALANCE=$7
WTIME=$8
REPORT_FILE=$9
QUEUE="cresco6_48h24"

########################################################################
# Preparing the other variables
########################################################################

########################### Algorithm selection ########################

PR=$(echo "${PRECISION}" | head -c 1)
ROUTINE="SPK-p${PR^}GESV-ft"

############### Fault tolerance parameter computation ##################

SPK_SPARE=${FAULT_TOLERANCE}
SPK_FT_PROCESSES=$(expr ${CALC_PROCS} + ${SPK_SPARE})
SPK_CHECKPOINT=$(( MATRIX_SIZE/2 ))

################## Computation of the number of nodes ##################

NODES=$(( SPK_FT_PROCESSES%48 == 0 ? SPK_FT_PROCESSES/48 : SPK_FT_PROCESSES/48+1 ))
TOT_PROCS=$(( NODES*48 ))

######################### Balance computation ##########################

NPERSOCKET="-"
if [ "${BALANCE}" == "y" ]; then
        NPERSOCKET=$(( SPK_FT_PROCESSES%(NODES*2) == 0 ? SPK_FT_PROCESSES/(NODES*2) : SPK_FT_PROCESSES/(NODES*2)+1 ))
fi

################# Preparation of scheduling condition ##################

LAST_JOB=$(cat ${BATCHDIR}/prevjob.txt | xargs )
if [ -z "${LAST_JOB}" ]; then
        CONDITION=""
else
        CONDITION="-w ended(\"${LAST_JOB}\") "
fi

##################### Blocking factor computation ######################

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

########################################################################
# Job submission
########################################################################

####################### Results path preparation #######################

if [ "${BALANCE}" = "y" ]; then
        RESDIR="${USERDIR}/results/balance/SPK/${PRECISION}/P${CALC_PROCS}/MS${MATRIX_SIZE}"			# Variabile eventualmente da cambiare
else
        RESDIR="${USERDIR}/results/nobalance/SPK/${PRECISION}/P${CALC_PROCS}/MS${MATRIX_SIZE}"			# Variabile eventualmente da cambiare
fi

mkdir -p ${RESDIR}/txt
mkdir -p ${RESDIR}/err
mkdir -p ${RESDIR}/csv

######################### Job name preparation #########################

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
JOB_NAME="SPKFT${FAULT_TOLERANCE}_nf${NUM_FAULTS}_cp${CALC_PROCS}_tnp${SPK_FT_PROCESSES}_ms${MATRIX_SIZE}_${PRECISION}_lb${BALANCE}_r${REPETITIONS}_W${WTIME}_${TIMESTAMP}"

############################ Job submission ############################
        
echo "${JOB_NAME} bsub init"

bsub	-n ${TOT_PROCS} 							\
	-W ${WTIME} 								\
	-q ${QUEUE} 								\
	-E "${BATCHDIR}/${PRE_EXEC} ${JOB_NAME} ${NODES}" 			\
        -Ep "${BATCHDIR}/${POST_EXEC} ${JOB_NAME} ${NODES}"                     \
	-J "${JOB_NAME}" 							\
	-o "${RESDIR}/txt/${JOB_NAME}.txt" 					\
	-e "${RESDIR}/err/${JOB_NAME}.err" 					\
	-R "slots == 48" 							\
	${CONDITION} 								\
	${BATCHDIR}/${RUN_CMD} ${SPK_FT_PROCESSES} ${NPERSOCKET} 		\
                -no-cnd-set                                                     \
                -no-cnd-readback                                                \
                -energy-reading                                                 \
		-o "${RESDIR}/csv/${JOB_NAME}.csv" 				\
		-r ${REPETITIONS} 						\
		-nm ${MATRIX_SIZE} 						\
		-ft ${FAULT_TOLERANCE} 						\
		-npf ${NUM_FAULTS} 						\
		-fr 2 								\
		-fl 2 								\
		-nps ${SPK_SPARE} 						\
		-spk-cp ${SPK_CHECKPOINT} 					\
		-spk-nb ${SPK_BLOCKING_FACTOR} 					\
		-i "${MATRIXDIR}/${PRECISION}_rank${MATRIX_SIZE}_cnd1000_seed1" \
		-type ${PRECISION} 						\
		--run ${ROUTINE}

############################# Report info ##############################

# "ALGORITHM" "PRECISION" "FT" "NF" "CPROCS" "SPROCS" "TPROCS" "MATSIZE" "NODES" "FL" "FR" "SPK-CP"
# "BKF" "SBAL" "NxSOCK" "R" "WT" "JOB NAME"

printf "%-10s %-10s %-3s %-3s %-7s %-7s %-7s %-7s %-6s %-3s %-3s %-7s %-4s %-5s %-7s %-3s %-4s %-100s\n" \
	"SPKft" "${PRECISION}" "${FAULT_TOLERANCE}" "${NUM_FAULTS}" "${CALC_PROCS}" "${SPK_SPARE}" \
	"${SPK_FT_PROCESSES}" "${MATRIX_SIZE}" "${NODES}" "2" "2" "${SPK_CHECKPOINT}" "${SPK_BLOCKING_FACTOR}" \
	"${BALANCE^}" "${NPERSOCKET}" "${REPETITIONS}" "${WTIME}" "${JOB_NAME}" >> ${REPORT_FILE}

########################## Final operations ############################
	
echo "${JOB_NAME}" >  ${BATCHDIR}/prevjob.txt
	
echo "Ready."
