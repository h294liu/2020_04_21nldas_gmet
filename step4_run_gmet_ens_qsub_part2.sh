#!/bin/bash
set -e

# H. liu, April 28, 2020.
# Add data_mask to ens and replace FillVlaue with 1e+20.
# Reference: /home/hydrofcst/otl_support/forcings/GMET/run/run_ens_forc.RETRO.csh
 
#------------------------------------------------------------
# Update setup
RootDir=/glade/u/home/hongli/scratch/2020_04_21nldas_gmet
SampleMode=uniform #uniform random

SourceDir=${RootDir}/scripts
StnlistDir=${SourceDir}/step1_sample_stnlist_${SampleMode}_perturb
WorkDirBase=${RootDir}/test_${SampleMode}_perturb
if [ ! -d ${WorkDirBase} ]; then mkdir -p ${WorkDirBase}; fi

startEns=1  # start number of ensembles to generate
stopEns=100  # stop number of ensembles to generate
interval=5

sYear=2012 #1979 
eYear=2016 #2019

configFileName=ens_forc.part2.sh
configFileNameShort="${configFileName/.sh/}"
Template=/glade/u/home/hongli/github/2020_04_21nldas_gmet/config/$configFileName
GridInfo=${RootDir}/data/nldas_topo/conus_ens_grid_eighth.nc

#------------------------------------------------------------
FILES=( $(ls ${StnlistDir}/*.txt) )
FILE_NUM=${#FILES[@]}
# for i in $(seq 0 $(($FILE_NUM -1))); do
# for i in $(seq $(($FILE_NUM -1)) $(($FILE_NUM -1))); do
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
    if [ ! -d ${WorkDir}/gmet_ens ]; then mkdir ${WorkDir}/gmet_ens; fi
           
    # loop through years
    for Y in $(seq ${sYear} ${eYear}); do
        echo $Y

        # split jobs based on ensemble member ininterval
        for startEns_i in $(seq $startEns $interval $(( $stopEns - 1 ))); do
            stopEns_i=$(( $startEns_i + $interval - 1 ))
            echo $Y $startEns_i $stopEns_i

            # setup configuration file
            ConfigFileName=$configFileNameShort.$Y.${startEns_i}_${stopEns_i}.sh
            ConfigFile=${WorkDir}/tmp/$ConfigFileName

            sed "s,WORKDIR,$WorkDir,g" $Template |\
            sed "s,YR,$Y,g" |\
            sed "s,STARTENS,$startEns_i,g" |\
            sed "s,STOPENS,$stopEns_i,g" |\
            sed "s,GRIDFILE,$GridInfo,g" > $ConfigFile
            chmod 740 ${ConfigFile}

            # create job submission file
            CommandFile=${WorkDir}/tmp/qsub.$configFileNameShort.$Y.${startEns_i}_${stopEns_i}.sh
            if [ -e ${command_file} ]; then rm -rf ${command_file}; fi

            LogFile=${WorkDir}/tmp/log.$configFileNameShort.$Y.${startEns_i}_${stopEns_i}
            rm -f $LogFile.*

            echo '#!/bin/bash' > ${CommandFile}
            echo "#PBS -N ens.${CaseID}.${Y}" >> ${CommandFile}
            echo '#PBS -A P48500028' >> ${CommandFile}
            echo '#PBS -q regular' >> ${CommandFile}
            echo '#PBS -l select=1:ncpus=1:mpiprocs=1' >> ${CommandFile}
            echo '#PBS -l walltime=00:10:00' >> ${CommandFile}
            echo "#PBS -o ${LogFile}.o" >> ${CommandFile}
            echo "#PBS -e ${LogFile}.e" >> ${CommandFile}

            echo "mkdir -p /glade/scratch/hongli/temp" >> ${CommandFile}
            echo "export TMPDIR=/glade/scratch/hongli/temp" >> ${CommandFile}

            echo "module load gnu" >> ${CommandFile}
            echo "module load netcdf" >> ${CommandFile}
        
            echo "cd ${WorkDir}/tmp/" >> ${CommandFile}
            echo "${ConfigFileName}" >> ${CommandFile}
#             echo "${ConfigFile}" >> ${CommandFile}
            chmod 740 ${CommandFile}

            qsub ${CommandFile}
        done

     done
done

