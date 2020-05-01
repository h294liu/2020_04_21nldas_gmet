#!/bin/bash
set -e

# H. liu, April 28, 2020.
# Combine years for each ensemble member.
# Depending on the existence of ensemble files.
# Reference: /home/hydrofcst/otl_support/forcings/GMET/run/combine_ens_forc.RETRO.csh
  
RootDir=/home/hongli/work/2020_04_21nldas_gmet

SourceDir=${RootDir}/scripts
StnlistDir=${SourceDir}/step4_sample_stnlist

startEns=1   # start number of ensembles to generate
stopEns=100  # stop number of ensembles to generate
sYear=2015 
eYear=2016

WorkDirBase=${RootDir}/test_uniform
if [ ! -d ${WorkDirBase} ]; then mkdir -p ${WorkDirBase}; fi

# loop all stnlist files
FILES=( $(ls ${StnlistDir}) )
FILE_NUM=${#FILES[@]}
#for i in $(seq 0 $(($FILE_NUM -1))); do
for i in $(seq 8 8); do
    
    FileName=${FILES[${i}]}
    FileNameShort="${FileName/.txt/}" # remove suffix ".txt"
    GridNum=$(echo $FileNameShort| cut -d'_' -f 2) # extract substring "012grids"    
    CaseID=${GridNum}
    echo ${CaseID}

    # create work folders
    WorkDir=${WorkDirBase}/${CaseID}
    if [ ! -d ${WorkDir} ]; then mkdir ${WorkDir}; fi
    if [ ! -d ${WorkDir}/tmp ]; then mkdir ${WorkDir}/tmp; fi
    if [ ! -d ${WorkDir}/gmet_ens_combine ]; then mkdir ${WorkDir}/gmet_ens_combine; fi
           
    # loop through members
    for M in $(seq ${startEns} ${stopEns}); do
        
        NUM=$(echo $M | awk '{printf("%03d",$1)}')
        echo ens member $NUM
        
        # clear existing output file
        OutputFile=${WorkDir}/gmet_ens_combine/ens_forc.$sYear-$eYear.$NUM.nc 
        rm -f $OutputFile
        
#         ncrcat -h ${WorkDir}/gmet_ens/ens_forc.$CaseID.*.$NUM.nc $OutputFile

        # create job submission file
        CommandFile=${WorkDir}/tmp/sbatch.ens_forc_combine.$NUM
        if [ -e ${command_file} ]; then rm -rf ${command_file}; fi
        
        LogFile=${WorkDir}/tmp/log.ens_forc_combine.$NUM
#         rm -f $LogFile.*

        echo '#!/bin/bash' > ${CommandFile}
        echo "#SBATCH --job-name=cmb.${CaseID}.${NUM}" >> ${CommandFile}
        echo '#SBATCH --partition=main' >> ${CommandFile}
        echo '#SBATCH --ntasks=1' >> ${CommandFile}
        echo '#SBATCH --time=04:00:00' >> ${CommandFile}
        echo "#SBATCH --output=${LogFile}.%j" >> ${CommandFile}

        echo "ncrcat -h ${WorkDir}/gmet_ens/ens_forc.*.${NUM}.nc ${OutputFile}" >> ${CommandFile}
        chmod 740 ${CommandFile}
        
        sbatch ${CommandFile}
        
     done
done

