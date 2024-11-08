#!/bin/bash

# $@.. command line arguments

module unload mpi_flavour pgi gcc intel
module load gcc/gcc730 mpi_flavour/openmpi_gcc730-3.1.2

# from https://www.afs.enea.it/project/eneagrid/Resources_en/CRESCO_documents/index.html

exe=/afs/enea.it/por/user/mcolonna/private/ime/bin/tester
HOSTFILE=$LSB_DJOB_HOSTFILE     # name of hostfile for mpirun

#############N_procs=`cat $LSB_DJOB_HOSTFILE | wc -l`     # give to mpirun same number of slots

N_procs=$1
NPERSOCKET=$2
shift
shift

if [ "${NPERSOCKET}" == "-" ]
then
	mpirun --map-by core --mca plm_rsh_agent "blaunch.sh" -n $N_procs --hostfile $HOSTFILE $exe "$@"
else
	mpirun --map-by ppr:${NPERSOCKET}:socket --bind-to core --mca plm_rsh_agent "blaunch.sh" -n $N_procs --hostfile $HOSTFILE $exe "$@"
fi

sleep 3

