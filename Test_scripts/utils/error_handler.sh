#USERDIR="/afs/enea.it/por/user/mcolonna"
USERDIR="/afs/enea.it/por/user/mcolonna/PFS/por/tirocinio"
RESDIR="${USERDIR}/results/"				# Variabile eventualmente da cambiare
REPORT_DIR="${USERDIR}/reports"				# Variabile eventualmente da cambiare
CMDDIR="${USERDIR}/test_scripts/src"

########################################################################
# Clean file prevjob.txt
########################################################################

echo "Are there any previous jobs in progress? [N/Y] "
read INPUT_STRING
FIRST_LETTER="${INPUT_STRING:0:1}"

if [ "${FIRST_LETTER^}" = "N" ]; then
        >  ${CMDDIR}/prevjob.txt
fi


TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_FILE="${REPORT_DIR}/${TIMESTAMP}_report_recovery.txt"
printf "%-10s %-10s %-3s %-3s %-7s %-7s %-7s %-7s %-6s %-3s %-3s %-7s %-4s %-5s %-7s %-3s %-4s %-100s\n" \
        "ALGORITHM" "PRECISION" "FT" "NF" "CPROCS" "SPROCS" "TPROCS" "MATSIZE" "NODES" "FL" "FR" "SPK-CP" \
        "BKF" "SBAL" "NxSOCK" "R" "WT" "JOB_NAME" > ${REPORT_FILE}

BATCHDIR=$(dirname "$(readlink -f "$0")")

#echo "${BATCHDIR}"
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
					cd ${MSIZE}/err

					ERRORS=$(find $(pwd) -maxdepth 1 -type f -size +0 -exec bash -c 'basename "$0" | sed "s/\.[^\.]*$//"' {} \;)	

					if [ "${ERRORS}" != "" ];then
						for JOB_NAME in ${ERRORS}
						do
							JOBID=$(cat ../txt/${JOB_NAME}.txt | grep -oP 'Subject: Job\s+\K\d+' | xargs )
							echo ${JOBID},${JOB_NAME} >> ${REPORT_DIR}/errors_info.csv
							mkdir -p recovered
							mkdir -p ../txt/recovered
							mkdir -p ../csv/recovered
							
							${USERDIR}/test_scripts/utils/parser.sh ${JOB_NAME} ${REPORT_FILE}

							mv ${JOB_NAME}.err recovered/
							mv ../txt/${JOB_NAME}.txt ../txt/recovered/
                        	                        mv ../csv/${JOB_NAME}.csv ../csv/recovered/
						done
					fi
					cd ..
					cd ..
				done
				cd ..
			done
			cd ..
		done
		cd ..
	done
	cd ..
done
