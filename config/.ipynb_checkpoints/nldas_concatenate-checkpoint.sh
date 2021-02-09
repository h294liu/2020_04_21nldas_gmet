#!/bin/bash
set -e

# H. liu, Nov 16, 2020.
# regression result variable over the years 1979-2019(regression mean, error)

#==========================input (need update)=========================== 
NldasInDir=INDIR    #regression result directory
NldasOutDir=OUTDIR  #ncrcat output directory
Var=VAR

#========================== (no need to update)===========================
echo $CaseID
rm -f ${NldasOutDir}/regress_ts_${Var}.nc
# ncrcat -h -O -n 10,4,1 -v $Var ${NldasInDir}/NLDAS_2007.nc ${NldasOutDir}/NLDAS_${Var}.nc
ncrcat -h -O -n 41,4,1 -v $Var ${NldasInDir}/NLDAS_1979.nc ${NldasOutDir}/NLDAS_${Var}.nc
