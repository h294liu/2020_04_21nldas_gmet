#!/bin/bash
set -e

# H. liu, May 1, 2020.
# Bias correct NLDAS-based GMET ensemble in comparison with NLDAS data.
  
RootDir=/glade/u/home/hongli/scratch/2020_04_21nldas_gmet #cheyenne
EnsDirBase=$RootDir/test_uniform_perturb
Template=$RootDir/scripts/config/ens_summary_part3.sh

EnsFolders=(gmet_ens gmet_ens_bc)
# EnsFolders=(gmet_ens)

#==========================bias correction===========================
# loop all stnlist files
FILES=( $(ls ${EnsDirBase}) )
FILE_NUM=${#FILES[@]}
for i in $(seq 1 $(($FILE_NUM -1))); do
# for i in $(seq 0 0); do
    
    CaseID=${FILES[${i}]}
    echo $CaseID
        
    # loop ensemble and bias-correct ensemble 
    for EnsFolder in ${EnsFolders[@]}; do
        echo ------------------------------
        echo $EnsFolder

        # set up ensemble folders
        TmpDir=$EnsDirBase/$CaseID/tmp
        EnsSumDir=$EnsDirBase/$CaseID/${EnsFolder}_summary
        
#         rm -r $TmpDir
        rm $EnsSumDir/abs_x_median.*.nc

 
    done
done

