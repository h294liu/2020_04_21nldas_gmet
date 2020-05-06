#!/bin/bash
set -e

#copy GMETresults from hydro-c1 to cheyenne
SrcDir=/home/hongli/work/2020_04_21nldas_gmet/test_uniform #hydro-c1
DstDir=/home/hongli/work/2020_04_21nldas_gmet/test_uniform #cheyenne

# remove sub-directoryesi with combine 
# loop all stnlist files
EnsDirBase=/home/hongli/work/2020_04_21nldas_gmet/test_uniform
FILES=( $(ls ${EnsDirBase}) )
FILE_NUM=${#FILES[@]}
for i in $(seq 0 $(($FILE_NUM -1))); do
# for i in $(seq 1 1); do
    
    CaseID=${FILES[${i}]}
    echo $CaseID
    
    rm -rf $EnsDirBase/$CaseID/gmet_ens_combine
    rm -rf $EnsDirBase/$CaseID/tmp/*combine*
    rm -rf $EnsDirBase/$CaseID/tmp/*${CaseID}*
done


