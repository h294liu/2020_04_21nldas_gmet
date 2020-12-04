#!/bin/bash
set -e

# H. Liu, July 4, 2020.
# Re-scale regression pcp and pcp_error to de-standardize because AndyN's latest code has removed this standardize step (pcp = (y-ymean)/ystd)
# replace fillValue zero with -999

#------------------------------------------------------------
# Update setup
RootDir=/glade/u/home/hongli/scratch/2020_04_21nldas_gmet
SampleMode=uniform #uniform random

SourceDir=${RootDir}/scripts
StnlistDir=${SourceDir}/step1_sample_stnlist_${SampleMode}_perturb

gridFile=${RootDir}/data/nldas_topo/conus_ens_grid_eighth.nc
configFileName=config.ens_regr.part3.sh
configFileNameShort="${configFileName/.sh/}"
Template=/glade/u/home/hongli/github/2020_04_21nldas_gmet/config/$configFileName 

WorkDirBase=${RootDir}/test_${SampleMode}_perturb
if [ ! -d ${WorkDirBase} ]; then mkdir -p ${WorkDirBase}; fi

StartDateOut=19790101 #20130101
EndDateOut=20191231 #20161231

# identify start and end time
StartYr=$(echo $StartDateOut| cut -c1-4)
EndYr=$(echo $EndDateOut| cut -c1-4)

#------------------------------------------------------------
# loop all stnlist files
FILES=( $(ls ${StnlistDir}/*.txt) )
FILE_NUM=${#FILES[@]}
for i in $(seq 0 $(($FILE_NUM -1))); do
# for i in $(seq 0 0); do

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
    
    for Y in $(seq ${StartYr} ${EndYr}); do
        echo $Y        

        # 1. configure config, output and log files
        ConfigFileName=$configFileNameShort.$Y.sh
        ConfigFile=${WorkDir}/tmp/$ConfigFileName
        if [ -e ${ConfigFile} ]; then rm -rf ${ConfigFile}; fi

        sed "s,WORKDIR,$WorkDir,g" $Template |\
        sed "s,YR,$Y,g" |\
        sed "s,GRIDFILE,$gridFile,g" > $ConfigFile             
        chmod 740 ${ConfigFile}

        # 2. create job submission file
        CommandFile=${WorkDir}/tmp/qsub.$configFileNameShort.$Y
        if [ -e ${command_file} ]; then rm -rf ${command_file}; fi

        LogFile=${WorkDir}/tmp/log.$configFileNameShort.$Y
        rm -f $LogFile.*

        echo '#!/bin/bash' > ${CommandFile}
        echo "#PBS -N regr.${CaseID}.${Y}" >> ${CommandFile}
        echo '#PBS -A P48500028' >> ${CommandFile}
        echo '#PBS -q regular' >> ${CommandFile}
        echo '#PBS -l select=1:ncpus=1:mpiprocs=1' >> ${CommandFile}
        echo '#PBS -l walltime=00:20:00' >> ${CommandFile}
        echo "#PBS -o ${LogFile}.o" >> ${CommandFile}
        echo "#PBS -e ${LogFile}.e" >> ${CommandFile}

        echo "mkdir -p /glade/scratch/hongli/temp" >> ${CommandFile}
        echo "export TMPDIR=/glade/scratch/hongli/temp" >> ${CommandFile}
        
        echo "cd ${WorkDir}/tmp/" >> ${CommandFile}
        echo "${ConfigFileName}" >> ${CommandFile}
        chmod 740 ${CommandFile}

        qsub ${CommandFile}
    done
done
