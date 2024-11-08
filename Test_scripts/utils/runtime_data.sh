#!/bin/bash

#USERDIR="/afs/enea.it/por/user/mcolonna"
USERDIR="/afs/enea.it/por/user/mcolonna/PFS/por/tirocinio"
RESDIR="${USERDIR}/results/"						# Variabile eventualmente da cambiare
REPORT_DIR="${USERDIR}/reports"						# Variabile eventualmente da cambiare
BATCHDIR=$(dirname "$(readlink -f "$0")")

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_FILE="${REPORT_DIR}/${TIMESTAMP}_report_results.csv"

echo "ALGORITHM;FT;NFT;PREC;CPROCS;SPROCS;TPROCS;MATSIZE;REP;WTIME;NODES;BALANCE;NUMxSOCK;RUNTIME_S;RUNTIME;NRE;NODO;EN_TOT_SOCK0_IN;EN_TOT_SOCK0_FIN;EN_TOT_SOCK1_IN;\
EN_TOT_SOCK1_FIN;EN_DRAM_SOCK0_IN;EN_DRAM_SOCK0_FIN;EN_DRAM_SOCK1_IN;EN_DRAM_SOCK1_FIN;JOB NAME" > ${REPORT_FILE}

cd ${RESDIR}
for LBAL in $( ls -d */ )
do
	cd ${LBAL}
	for ALG in $( ls -d */ )
	do	
		cd ${ALG}
		for PREC in $( ls -d */ )
		do
			cd ${PREC}
			for CPROC in $( ls -d */ )
			do
				cd ${CPROC}
				for MSIZE in $( ls -d */ )
                                do
                                        cd "${MSIZE}err"
					#echo -e "################################### ${ALG} ${PREC} - ${CPROC} - ${MSIZE} - ${LBAL} ###################################\n"
					JOBS=$(find $(pwd)  -maxdepth 1 -type f -size 0 -exec bash -c 'basename "$0" | sed "s/\.[^\.]*$//"' {} \;)
				
					if [ "${JOBS}" != "" ]; then
						for JOB_NAME in ${JOBS}
						do
							INFO_JOB=$(${BATCHDIR}/jobinfo.sh -o ${JOB_NAME})
							RUN_TIME_S=$( grep -oP 'Run time\s*:\s*\K\d+' ../txt/${JOB_NAME}.txt )
							HOURS=$((RUN_TIME_S/ 3600))
							MINUTES=$(( (RUN_TIME_S % 3600) / 60 ))
							SECONDS=$((RUN_TIME_S % 60))
							NRE=$(cat ../txt/${JOB_NAME}.txt | grep -oP "nre: \K[-]?\d+.\d+" | head -n 1 )
							ENERGY_VALUES=$(cat ../txt/${JOB_NAME}.txt | grep -P "cresco6x\d+.portici.enea.it")

							COUNT=0;
							(IFS=$'\n'
							for riga in ${ENERGY_VALUES}
							do
							        if [ $(( COUNT % 4)) -eq 0 ]; then
							                EN_TOT_SOCK0_IN=$(echo $riga | awk '{print $4}')
							                EN_TOT_SOCK0_FIN=$(echo $riga | awk '{print $5}')
							        elif [ $(( COUNT % 4)) -eq 1 ]; then
							                EN_DRAM_SOCK0_IN=$(echo $riga | awk '{print $4}')
							                EN_DRAM_SOCK0_FIN=$(echo $riga | awk '{print $5}')
							        elif [ $(( COUNT % 4)) -eq 2 ]; then
							                EN_TOT_SOCK1_IN=$(echo $riga | awk '{print $4}')
							                EN_TOT_SOCK1_FIN=$(echo $riga | awk '{print $5}')
							        else
							                EN_DRAM_SOCK1_IN=$(echo $riga | awk '{print $4}')
							                EN_DRAM_SOCK1_FIN=$(echo $riga | awk '{print $5}')

							                NODE=$(echo $riga | grep -oP "cresco6x\d+")
							                echo -e "${INFO_JOB};${RUN_TIME_S};${HOURS}h ${MINUTES}m ${SECONDS}s;${NRE};${NODE};"\
										"${EN_TOT_SOCK0_IN};${EN_TOT_SOCK0_FIN};${EN_TOT_SOCK1_IN};${EN_TOT_SOCK1_FIN};"\
										"${EN_DRAM_SOCK0_IN};${EN_DRAM_SOCK0_FIN};${EN_DRAM_SOCK1_IN};"\
										"${EN_DRAM_SOCK1_FIN};${JOB_NAME}" >> ${REPORT_FILE}
							        fi
							        COUNT=$((COUNT + 1))
							done
							)
						done
					fi
					cd ../..
				done
				cd ..
			done
			cd ..
		done
		cd ..
	done
	cd ..
done

CONTENT=$(cat ${REPORT_FILE})
if [ "${CONTENT}" = "" ]; then
	rm ${REPORT_FILE}
fi
