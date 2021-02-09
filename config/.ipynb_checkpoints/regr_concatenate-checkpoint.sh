#!/bin/bash
set -e

# H. liu, Nov 16, 2020.
# regression result variable over the years 1979-2019(regression mean, error)

#==========================input (need update)=========================== 
RegrInDir=INDIR    #regression result directory
RegrOutDir=OUTDIR  #ncrcat output directory
Var=VAR

#========================== (no need to update)===========================
echo $CaseID
rm -f ${RegrOutDir}/regress_ts_${Var}.nc
# ncrcat -h -O -n 10,4,1 -v $Var ${RegrInDir}/regress_ts.2007.nc ${RegrOutDir}/regress_ts_${Var}.nc
ncrcat -h -O -n 41,4,1 -v $Var ${RegrInDir}/regress_ts.1979.nc ${RegrOutDir}/regress_ts_${Var}.nc
