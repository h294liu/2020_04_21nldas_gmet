#!/bin/bash
set -e

# H. liu, April 28, 2020.
# Bias correct NLDAS-based GMET ensemble in comparison with NLDAS data.
  
RootDir=/glade/u/home/hongli/scratch/2020_04_21nldas_gmet #cheyenne
EnsDirBase=$RootDir/test_uniform_perturb

configFileName=cal_tmin_tmax.sh
configFileNameShort="${configFileName/.sh/}"
Template=$RootDir/scripts/config/$configFileName

startEns=1   # start number of ensembles to generate
stopEns=100  # stop number of ensembles to generate
interval=5

sYear=1979 #2016 
eYear=2006 #2016

work_dir=/glade/u/home/hongli/work/2020_04_21nldas_gmet/test_uniform_perturb
#==========================bias correction===========================
# loop all stnlist files
FILES=( $(ls ${EnsDirBase}) )
FILE_NUM=${#FILES[@]}
# for i in $(seq 0 $(($FILE_NUM -1))); do
for i in $(seq 1 7); do
    
    CaseID=${FILES[${i}]}
    EnsDir=$EnsDirBase/$CaseID/gmet_ens
    echo $CaseID
    
    # clean tmp
#     if [ -d $EnsDirBase/$CaseID/tmp ]; then rm $EnsDirBase/$CaseID/tmp/*; fi

#     for Y in $(seq $sYear $eYear); do        
#         rm -f $EnsDirBase/$CaseID/gmet_regr/regress_ts.$Y.*
#         rm -f $EnsDirBase/$CaseID/gmet_regr/*_bk
#     done
    
#     tar -cvf $tar_dir/${CaseID}.tar $EnsDirBase/$CaseID
    mv $EnsDirBase/$CaseID $work_dir/
done

