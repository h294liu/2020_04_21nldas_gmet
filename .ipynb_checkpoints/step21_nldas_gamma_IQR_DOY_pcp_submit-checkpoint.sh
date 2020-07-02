#!/bin/bash
set -e

#PBS -N iqr_pcp
#PBS -A P48500028
#PBS -q regular
#PBS -l select=2:ncpus=36
#PBS -l walltime= 00:10:00
#PBS -M hongli@ucar.edu
#PBS -j oe

export TMPDIR=/glade/scratch/hongli/temp
mkdir -p $TMPDIR

# Run the executable
time python step21_nldas_gamma_IQR_DOY_pcp.py