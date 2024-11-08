#!/bin/bash

########################################################################
# Parameter check
########################################################################

if [ "$#" -lt 10 ]; then
        echo "Usage: $0 CALC_PROCS MATRIX_SIZE PRECISION REPETITIONS FAULT_TOLERANCE NUM_FAULTS ALGORITHM BALANCE W_TIME REPORT_FILE"
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
BATCHDIR=$(dirname "$(readlink -f "$0")")
MATRIXDIR="/afs/enea.it/fra/user/artioli/PFS/tmp/data/test_matrices"

########################################################################
# Input parameters analisys
########################################################################

CALC_PROCS=$1
MATRIX_SIZE=$2
PRECISION=$3
REPETITIONS=$4
FAULT_TOLERANCE=$5
NUM_FAULTS=$6
ALGORITHM=$7
BALANCE=$8
WTIME=$9
REPORT_FILE=${10}
QUEUE="cresco6_48h24"

########################################################################
# Preparing the other variables
########################################################################

########################### Algorithm selection ########################

PR=$(echo "${PRECISION}" | head -c 1)

if [ "${ALGORITHM}" = "IMeWO" ]; then
        ROUTINE="IMe-p${PR^}GESV-wo-ft"
elif [ "${ALGORITHM}" = "IMeCO" ]; then
        ROUTINE="IMe-p${PR^}GESV-co-ft"
else
	echo "Algorithm ${ALGORITHM} does not exist."
	exit 2;
fi

############### Fault tolerance parameter computation ##################

PROCESSES_PER_COL=$(echo "sqrt(${CALC_PROCS})" | bc)
IME_SPARE=$(expr ${PROCESSES_PER_COL} \* ${FAULT_TOLERANCE})
IME_FT_PROCESSES=$(expr ${CALC_PROCS} + ${IME_SPARE})

################# Computation of the number of nodes ###################

NODES=$(( IME_FT_PROCESSES%48 == 0 ? IME_FT_PROCESSES/48 : IME_FT_PROCESSES/48+1 ))
TOT_PROCS=$(( NODES*48 ))

######################### Balance computation ##########################

NPERSOCKET="-"
if [ "${BALANCE}" == "y" ]; then
        NPERSOCKET=$(( IME_FT_PROCESSES%(NODES*2) == 0 ? IME_FT_PROCESSES/(NODES*2) : IME_FT_PROCESSES/(NODES*2)+1 ))
fi

################# Calculation of scheduling condition ##################

LAST_JOB=$(cat ${BATCHDIR}/prevjob.txt | xargs )

if [ -z "${LAST_JOB}" ]; then
        CONDITION=""
else
        CONDITION="-w ended(\"${LAST_JOB}\") "
fi

########################################################################
# Job submission
########################################################################

####################### Results path preparation #######################

if [ "${BALANCE}" = "y" ]; then
        RESDIR="${USERDIR}/results/balance/${ALGORITHM}/${PRECISION}/P${CALC_PROCS}/MS${MATRIX_SIZE}"		# Variabile eventualmente da cambiare
else
        RESDIR="${USERDIR}/results/nobalance/${ALGORITHM}/${PRECISION}/P${CALC_PROCS}/MS${MATRIX_SIZE}"		# Variabile eventualmente da cambiare
fi

mkdir -p ${RESDIR}/txt
mkdir -p ${RESDIR}/err
mkdir -p ${RESDIR}/csv

######################### Job name preparation #########################

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
JOB_NAME="${ALGORITHM}FT${FAULT_TOLERANCE}_nf${NUM_FAULTS}_cp${CALC_PROCS}_tnp${IME_FT_PROCESSES}_ms${MATRIX_SIZE}_${PRECISION}_lb${BALANCE}_r${REPETITIONS}_W${WTIME}_${TIMESTAMP}"

############################ Job submission ############################
	
echo "${JOB_NAME} bsub init"

bsub    -n ${TOT_PROCS} 							\
	-W ${WTIME} 								\
       	-q ${QUEUE} 								\
        -E "${BATCHDIR}/${PRE_EXEC} ${JOB_NAME} ${NODES}" 			\
        -Ep "${BATCHDIR}/${POST_EXEC} ${JOB_NAME} ${NODES}"                     \
       	-J "${JOB_NAME}" 							\
        -o "${RESDIR}/txt/${JOB_NAME}.txt" 					\
       	-e "${RESDIR}/err/${JOB_NAME}.err" 					\
        -R "slots == 48" 							\
	${CONDITION} 								\
       	${BATCHDIR}/${RUN_CMD} ${IME_FT_PROCESSES} ${NPERSOCKET} 		\
                -no-cnd-set                                                     \
                -no-cnd-readback                                                \
                -energy-reading                                                 \
		-o "${RESDIR}/csv/${JOB_NAME}.csv" 				\
               	-r ${REPETITIONS} 						\
                -nm ${MATRIX_SIZE} 						\
       	        -ft ${FAULT_TOLERANCE} 						\
        	-npf ${NUM_FAULTS} 						\
        	-fr 5 								\
	        -fl 2 								\
       		-nps ${IME_SPARE} 						\
		-i "${MATRIXDIR}/${PRECISION}_rank${MATRIX_SIZE}_cnd1000_seed1"	\
		-type ${PRECISION} 						\
       	        --run ${ROUTINE}

############################# Report info ##############################
	
# "ALGORITHM" "PRECISION" "FT" "NF" "CPROCS" "SPROCS" "TPROCS" "MATSIZE" "NODES" "FL" "FR" "SPK-CP"
# "BKF" "SBAL" "NxSOCK" "R" "WT" "JOB NAME"
printf "%-10s %-10s %-3s %-3s %-7s %-7s %-7s %-7s %-6s %-3s %-3s %-7s %-4s %-5s %-7s %-3s %-4s %-100s\n" \
	"${ALGORITHM}ft" "${PRECISION}" "${FAULT_TOLERANCE}" "${NUM_FAULTS}" "${CALC_PROCS}" "${IME_SPARE}" \
	"${IME_FT_PROCESSES}" "${MATRIX_SIZE}" "${NODES}" "2" "2" "-" "-" "${BALANCE^}" "${NPERSOCKET}" \
	"${REPETITIONS}" "${WTIME}" "${JOB_NAME}" >> ${REPORT_FILE}

########################## Final operations ############################

echo "${JOB_NAME}" >  ${BATCHDIR}/prevjob.txt

echo "Ready."
