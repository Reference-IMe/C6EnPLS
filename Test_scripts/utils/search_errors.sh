#USERDIR="/afs/enea.it/por/user/mcolonna"
USERDIR="/afs/enea.it/por/user/mcolonna/PFS/por/tirocinio"
RESDIR="${USERDIR}/results"						# Variabile eventualmente da cambiare
REPORT_DIR="${USERDIR}/reports"						# Variabile eventualmente da cambiare
BATCHDIR=$(dirname "$(readlink -f "$0")")

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_FILE="${REPORT_DIR}/${TIMESTAMP}_report_recovery.txt"

cd "${RESDIR}"
for LBAL in $(ls -d */ )
do
	cd "${LBAL}"
	for ALG in $( ls -d */ )
	do	
	        cd "${ALG}"
		for PREC in $( ls -d */ )
		do
			cd "${PREC}"
			for CPROC in $( ls -d */ )
			do
				cd "${CPROC}"
				for MSIZE in $( ls -d */ )
				do
					cd "${MSIZE}/err"

					ERRORS=$(find $(pwd) -maxdepth 1 -type f -size +0 -exec basename {} \;)	

					if [ "${ERRORS}" != "" ];then
						for ERR in ${ERRORS}
						do
							echo "$(pwd)/${ERR}"
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
