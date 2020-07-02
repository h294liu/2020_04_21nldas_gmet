#!/bin/bash
#PBS -N model
#PBS -A P48500028
#PBS -q regular
#PBS -l select=2:ncpus=36:mpiprocs=36
#PBS -l walltime=00:10:00
#PBS -M hongli@ucar.edu
#PBS -j oe

mkdir -p /glade/scratch/hongli/temp
export TMPDIR=/glade/scratch/hongli/temp

# Run the executable
python step21_nldas_gamma_IQR_DOY_pcp_series.py
