#!/usr/bin/bash

########################################################################
# Parameter check
########################################################################

if [ "$#" -lt 8 ]; then
        echo "Usage: $0 CALC_PROCS MATRIX_SIZE PRECISION REPETITIONS ALGORITHM BALANCE W_TIME REPORT_FILE"
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
ALGORITHM=$5
BALANCE=$6
WTIME=$7
REPORT_FILE=$8
QUEUE="cresco6_48h24"


########################################################################
# Preparing the other variables
########################################################################

########################### Algorithm selection ########################

PR=$(echo "${PRECISION}" | head -c 1)

if [ "${ALGORITHM}" = "IMeWO" ]; then
	ROUTINE="IMe-p${PR^}GESV-wo"
	BLOCKING_FACTOR=""
elif [ "${ALGORITHM}" = "IMeCO" ]; then
	ROUTINE="IMe-p${PR^}GESV-co"
	BLOCKING_FACTOR=""
elif [ "${ALGORITHM}" = "SPK" ]; then
        ROUTINE="SPK-p${PR^}GESV"
	BLOCKING_FACTOR="-spk-nb 24"
else
        echo "Algorithm ${ALGORITHM} does not exist."
        exit 2;
fi

################## Computation of the number of nodes ##################

NODES=$(( CALC_PROCS%48 == 0 ? CALC_PROCS/48 : CALC_PROCS/48+1 ))
TOT_PROCS=$(( NODES*48 ))

######################### Balance computation ##########################

NPERSOCKET="-"
if [ "${BALANCE}" == "y" ]; then
        NPERSOCKET=$(( CALC_PROCS%(NODES*2) == 0 ? CALC_PROCS/(NODES*2) : CALC_PROCS/(NODES*2)+1 ))
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
JOB_NAME="${ALGORITHM}FT0_cp${CALC_PROCS}_tnp${CALC_PROCS}_ms${MATRIX_SIZE}_${PRECISION}_lb${BALANCE}_r${REPETITIONS}_W${WTIME}_${TIMESTAMP}"

############################ Job submission ############################

echo "${JOB_NAME} bsub init"

bsub    -n ${TOT_PROCS} 							\
	-W ${WTIME} 								\
        -q ${QUEUE} 								\
        -E "${BATCHDIR}/${PRE_EXEC} ${JOB_NAME} ${NODES}"  			\
	-Ep "${BATCHDIR}/${POST_EXEC} ${JOB_NAME} ${NODES}"			\
        -J "${JOB_NAME}" 							\
        ${CONDITION} 								\
        -o "${RESDIR}/txt/${JOB_NAME}.txt"					\
        -e "${RESDIR}/err/${JOB_NAME}.err"					\
        -R "slots == 48" 							\
         ${BATCHDIR}/${RUN_CMD} ${CALC_PROCS} ${NPERSOCKET} 			\
		-no-cnd-set 							\
		-no-cnd-readback 						\
		-energy-reading 						\
		-o "${RESDIR}/csv/${JOB_NAME}.csv" 				\
		-r ${REPETITIONS} 						\
		-nm ${MATRIX_SIZE} 						\
		-ft 0 								\
		-i "${MATRIXDIR}/${PRECISION}_rank${MATRIX_SIZE}_cnd1000_seed1"	\
		-type ${PRECISION} 						\
		${BLOCKING_FACTOR} 						\
		--run ${ROUTINE}

############################# Report info ##############################

# "ALGORITHM" "PRECISION" "FT" "NF" "CPROCS" "SPROCS" "TPROCS" "MATSIZE" "NODES" "FL" "FR" "SPK-CP" "BKF" "SBAL" "NxSOCK" "R" "WT" "JOB NAME" 

printf "%-10s %-10s %-3s %-3s %-7s %-7s %-7s %-7s %-6s %-3s %-3s %-7s %-4s %-5s %-7s %-3s %-4s %-100s\n" \
	"${ALGORITHM}" "${PRECISION}" "-" "-" "${CALC_PROCS}" "0" "${CALC_PROCS}" "${MATRIX_SIZE}" \
	"${NODES}" "-" "-" "-" "-" "${BALANCE^}" "${NPERSOCKET}" "${REPETITIONS}" "${WTIME}" "${JOB_NAME}" >> ${REPORT_FILE} 

########################## Final operations ############################

echo "${JOB_NAME}" >  ${BATCHDIR}/prevjob.txt
echo "Ready."
