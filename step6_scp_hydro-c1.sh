#!/bin/bash
set -e

SrcDir=/home/hongli/work/2020_04_21nldas_gmet #hydro-c1
DstDir=/glade/u/home/hongli/work/2020_04_21nldas_gmet #cheyenne
StnlistDir=${DstDir}/scripts/step4_sample_stnlist

ResultFolder=test_uniform
if [ ! -d ${DstDir}/${ResultFolder} ]; then mkdir ${DstDir}/${ResultFolder}; fi

# loop all stnlist files
FILES=( $(ls ${StnlistDir} -I *.png) )
FILE_NUM=${#FILES[@]}
# for i in $(seq 0 $(($FILE_NUM -1))); do
for i in $(seq 7 7); do
    
    FileName=${FILES[${i}]}
    FileNameShort="${FileName/.txt/}" # remove suffix ".txt"
    GridNum=$(echo $FileNameShort| cut -d'_' -f 2) # extract substring "012grids"    
    CaseID=${GridNum}
    echo ${CaseID}

    if [ ! -d ${DstDir}/${ResultFolder}/${CaseID} ]; then mkdir ${DstDir}/${ResultFolder}/${CaseID}; fi
    scp -r hongli@hydro-c1.rap.ucar.edu:${SrcDir}/${ResultFolder}/${CaseID}/gmet_ens_combine \
    ${DstDir}/${ResultFolder}/${CaseID}/
done



