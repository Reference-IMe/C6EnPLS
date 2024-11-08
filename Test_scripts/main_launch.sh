#!/bin/bash

#noft_tester
#Usage: ./no_ft_tester.sh CALC_PROCS MATRIX_SIZE PRECISION REPETITIONS ALGORITHM BALANCE W_TIME REPORT_FILE (ALGORITHM : IMeWO IMeCO SPK)

#ime_ft_tester
#Usage: ./ime_ft_tester.sh CALC_PROCS MATRIX_SIZE PRECISION REPETITIONS FAULT_TOLERANCE NUM_FAULTS ALGORITHM BALANCE W_TIME REPORT_FILE (ALG: IMeWO IMeCO)

#spk_ft_tester
#Usage: ./spk_ft_tester.sh CALC_PROCS MATRIX_SIZE PRECISION REPETITIONS FAULT_TOLERANCE NUM_FAULTS BALANCE W_TIME REPORT_FILE


########################################################################
# Main paths
########################################################################

USERDIR="/afs/enea.it/por/user/mcolonna/PFS/por/tirocinio"
INFODIR="${USERDIR}/jobs_data"
BATCHDIR=$(dirname "$(readlink -f "$0")")
CMDDIR="${BATCHDIR}/src"
REPORT_DIR="${USERDIR}/reports"						# Variabile eventualmente da cambiare

########################################################################
# Preparing info jobs directory 
########################################################################

mkdir -p ${INFODIR}

########################################################################
# Preparing report directory
########################################################################

mkdir -p ${REPORT_DIR}

########################################################################
# Print report initial informations
########################################################################

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_FILE="${REPORT_DIR}/${TIMESTAMP}_report.txt"

printf "%-10s %-10s %-3s %-3s %-7s %-7s %-7s %-7s %-6s %-3s %-3s %-7s %-4s %-5s %-7s %-3s %-4s %-100s\n" \
	"ALGORITHM" "PRECISION" "FT" "NF" "CPROCS" "SPROCS" "TPROCS" "MATSIZE" "NODES" "FL" "FR" "SPK-CP" \
	"BKF" "SBAL" "NxSOCK" "R" "WT" "JOB_NAME" > ${REPORT_FILE}

########################################################################
# Clean file prevjob.txt
########################################################################

echo "Are there any previous jobs in progress? [N/Y] "
read INPUT_STRING
FIRST_LETTER="${INPUT_STRING:0:1}"

if [ "${FIRST_LETTER^}" = "N" ]; then
	>  ${CMDDIR}/prevjob.txt
fi

########################################################################
# Counters initialization
########################################################################

#COUNT_IME_WO=0
COUNT_IME_CO=0
COUNT_SPK=0

########################################################################
# Main Program
########################################################################
REPETITIONS=1
WTIME=60

for CALC_PROCS in 144 # 484 576 # 256 # 64 576 256 144 400 100 484 #64                      # calc procs ord (36 forse non più) 64 100 144 256 400 484 576
do
        for FAULT_TOLERANCE in 0 ##8 4 2 1
	do
		for MATRIX_SIZE in 42240 36960 31680 			#matrix sizes ord 5280 10560 15840 21120 26400 31680 36960 42240
		do
			for BALANCE in "n" "y"
			do
				for PRECISION in "single" "double"
				do			
					if [ ${FAULT_TOLERANCE} -eq 0 ]; then
	                                        #COUNT_IME_WO=$((${COUNT_IME_WO}+1))
                                                COUNT_IME_CO=$((${COUNT_IME_CO}+1))
                                       	        COUNT_SPK=$((${COUNT_SPK}+1))
						#${CMDDIR}/no_ft_tester.sh ${CALC_PROCS} ${MATRIX_SIZE} ${PRECISION} ${REPETITIONS} "IMeWO" ${BALANCE} ${WTIME} ${REPORT_FILE}
                	       	 		${CMDDIR}/no_ft_tester.sh ${CALC_PROCS} ${MATRIX_SIZE} ${PRECISION} ${REPETITIONS} "IMeCO" ${BALANCE} ${WTIME} ${REPORT_FILE}
                        	        	#${CMDDIR}/no_ft_tester.sh ${CALC_PROCS} ${MATRIX_SIZE} ${PRECISION} ${REPETITIONS} "SPK" ${BALANCE} ${WTIME} ${REPORT_FILE}
					else
	                                        #COUNT_IME_WO=$((${COUNT_IME_WO}+2)) #NOT IMPLEMENTED YET
	                                        COUNT_IME_CO=$((${COUNT_IME_CO}+2))
                                                COUNT_SPK=$((${COUNT_SPK}+2))
						for NUM_FAULTS in 0 ${FAULT_TOLERANCE}
						do
							#${CMDDIR}/ime_ft_tester.sh ${CALC_PROCS} ${MATRIX_SIZE} ${PRECISION} ${REPETITIONS} ${FAULT_TOLERANCE} ${NUM_FAULTS} "IMeWO" ${BALANCE} ${WTIME} ${REPORT_FILE}
							${CMDDIR}/ime_ft_tester.sh ${CALC_PROCS} ${MATRIX_SIZE} ${PRECISION} ${REPETITIONS} ${FAULT_TOLERANCE} ${NUM_FAULTS} "IMeCO" ${BALANCE} ${WTIME} ${REPORT_FILE}
						#	${CMDDIR}/spk_ft_tester.sh ${CALC_PROCS} ${MATRIX_SIZE} ${PRECISION} ${REPETITIONS} ${FAULT_TOLERANCE} ${NUM_FAULTS} ${BALANCE} ${WTIME} ${REPORT_FILE}
						done
					fi
				done		
			done
		done
	done
done

COUNT=$(( COUNT_IME_WO + COUNT_IME_CO + COUNT_SPK ))
echo IME-WO: ${COUNT_IME_WO} - IME-CO: ${COUNT_IME_CO} - SPK: ${COUNT_SPK} - TOTAL: ${COUNT}
