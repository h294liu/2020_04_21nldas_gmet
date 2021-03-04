#!/bin/bash
set -e

# H. Liu, April 27, 2020.
# Run downscaling regression year by year using GMET downscaling code.
# Reference: /home/hydrofcst/otl_support/forcings/GMET/run/run_ens_regr.csh

#------------------------------------------------------------
# Update setup
RootDir=/glade/u/home/hongli/scratch/2020_04_21nldas_gmet
SampleMode=uniform #uniform random

SourceDir=${RootDir}/scripts
StnlistDir=${SourceDir}/step1_sample_stnlist_${SampleMode}_perturb
StndataDir=${SourceDir}/step2_prepare_stndata_${SampleMode}_perturb

WorkDirBase=${RootDir}/test_${SampleMode}_perturb
if [ ! -d ${WorkDirBase} ]; then mkdir -p ${WorkDirBase}; fi

StartDateStn=19790101
EndDateStn=20191231

StartDateOut=19790101
EndDateOut=20191231 #20161231

Program=/glade/u/home/hongli/tools/GMET-1/downscale/downscale_bc.exe 
configFileName=config.ens_regr.part2.txt
configFileNameShort="${configFileName/.txt/}"
Template=/glade/u/home/hongli/github/2020_04_21nldas_gmet/config/$configFileName 
GridInfo=${RootDir}/data/nldas_topo/conus_ens_grid_eighth.nc

#------------------------------------------------------------
# loop all stnlist files
FILES=( $(ls ${StnlistDir}/*.txt) )
FILE_NUM=${#FILES[@]}
# for i in $(seq 0 $(($FILE_NUM -1))); do
for i in $(seq $(($FILE_NUM -2)) $(($FILE_NUM -2))); do

    FileName=${FILES[${i}]} 
    FileName=${FileName##*/} # get basename of filename
    FileNameShort="${FileName/.txt/}" # remove suffix ".txt"
    GridNum=$(echo $FileNameShort| cut -d'_' -f 2) # extract substring "012grids"    
    CaseID=${GridNum}
    echo ${CaseID}

    # create work folders
    WorkDir=${WorkDirBase}/${CaseID}
    if [ ! -d ${WorkDir} ]; then mkdir ${WorkDir}; fi
    if [ ! -d ${WorkDir}/tmp ]; then mkdir ${WorkDir}/tmp; fi
    if [ ! -d ${WorkDir}/gmet_regr ]; then mkdir ${WorkDir}/gmet_regr; fi
    
    # configure stnlist and stndata
    StnList=$StnlistDir/$FileName
    StnDataDir=$StndataDir/stndata_${CaseID}
    WeightFile=${WorkDir}/gmet_regr/${CaseID}.bin
    
    # identify start and end time
    StartYr=$(echo $StartDateOut| cut -c1-4)
    EndYr=$(echo $EndDateOut| cut -c1-4)
    StMoDy=$(echo $StartDateOut| cut -c5-8)
    EndMoDy='1231'
    
    # loop through years
    for Y in $(seq ${StartYr} ${EndYr}); do
        echo $Y
        if [ $Y -gt ${StartYr} ]; then 
            StMoDy='0101'
        fi
        if [ $Y -eq ${EndYr} ]; then 
            EndMoDy=$(echo $EndDateOut| cut -c5-8)
        fi
        
        # configure config, output and log files
        ConfigFileName=$configFileNameShort.$Y.txt
        ConfigFile=${WorkDir}/tmp/$ConfigFileName
        OutputFile=${WorkDir}/gmet_regr/regress_ts.$Y.nc
        if [ -e ${OutputFile} ]; then rm -rf ${OutputFile}; fi
        
        sed "s,RunYr,$Y,g" $Template |\
        sed "s,StMoDy,$StMoDy,g" |\
        sed "s,EndMoDy,$EndMoDy,g" |\
        sed "s,StnList,$StnList,g" |\
        sed "s,GridInfo,$GridInfo,g" |\
        sed "s,OutputFile,$OutputFile,g" |\
        sed "s,StnDataDir,$StnDataDir,g" |\
        sed "s,StartDateStn,$StartDateStn,g" |\
        sed "s,EndDateStn,$EndDateStn,g" |\
        sed "s,WeightFile,$WeightFile,g" > $ConfigFile
        chmod 740 ${ConfigFile}

        # create job submission file
        CommandFile=${WorkDir}/tmp/qsub.$configFileNameShort.$Y.sh
        if [ -e ${command_file} ]; then rm -rf ${command_file}; fi
        
        LogFile=${WorkDir}/tmp/log.$configFileNameShort.$Y
        rm -f $LogFile.*

        echo '#!/bin/bash' > ${CommandFile}
        echo "#PBS -N regr.${CaseID}.${Y}" >> ${CommandFile}
        echo '#PBS -A P48500028' >> ${CommandFile}
        echo '#PBS -q regular' >> ${CommandFile}
        echo '#PBS -l select=1:ncpus=1:mpiprocs=1' >> ${CommandFile}
        echo '#PBS -l walltime=12:00:00' >> ${CommandFile}
        echo "#PBS -o ${LogFile}.o" >> ${CommandFile}
        echo "#PBS -e ${LogFile}.e" >> ${CommandFile}
        
        echo "mkdir -p /glade/scratch/hongli/temp" >> ${CommandFile}
        echo "export TMPDIR=/glade/scratch/hongli/temp" >> ${CommandFile}

        echo "module load gnu" >> ${CommandFile}
        echo "module load netcdf" >> ${CommandFile}
        
        echo "cd ${WorkDir}/tmp/" >> ${CommandFile}
        echo "${Program} ${ConfigFileName}" >> ${CommandFile}
#         echo "${Program} ${ConfigFile}" >> ${CommandFile}
        chmod 740 ${CommandFile}
        
        qsub ${CommandFile}
#         ${Program} ${ConfigFile}
     done
done
