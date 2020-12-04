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
eYear=2019 #2016

#==========================bias correction===========================
# loop all stnlist files
FILES=( $(ls ${EnsDirBase}) )
FILE_NUM=${#FILES[@]}
# for i in $(seq 0 $(($FILE_NUM -1))); do
for i in $(seq $(($FILE_NUM -1)) $(($FILE_NUM -1))); do
    
    CaseID=${FILES[${i}]}
    EnsDir=$EnsDirBase/$CaseID/gmet_ens
    echo $CaseID

    for Y in $(seq $sYear $eYear); do        
        for startEns_i in $(seq $startEns $interval $(( $stopEns - 1 ))); do
            
            stopEns_i=$(( $startEns_i + $interval - 1 ))
            echo $Y ${startEns_i}_${stopEns_i}

            # setup configuration file
            if [ ! -d $EnsDirBase/$CaseID/tmp ]; then mkdir $EnsDirBase/$CaseID/tmp; fi
            ConfigFile=$EnsDirBase/$CaseID/tmp/$configFileNameShort.$Y.${startEns_i}_${stopEns_i}.sh

            sed "s,ENSDIR,$EnsDir,g" $Template |\
            sed "s,YEAR,$Y,g" |\
            sed "s,STARTENS,$startEns_i,g" |\
            sed "s,STOPENS,$stopEns_i,g" > $ConfigFile
            chmod 744 $ConfigFile

            # create job submission file
            CommandFile=$EnsDirBase/$CaseID/tmp/qsub.$configFileNameShort.$Y.${startEns_i}_${stopEns_i}.sh
            LogFile=$EnsDirBase/$CaseID/tmp/log.$configFileNameShort.$Y.${startEns_i}_${stopEns_i}
            rm -f ${CommandFile} $LogFile.*

            echo '#!/bin/bash' > $CommandFile
            echo "#PBS -N temp.$CaseID" >> $CommandFile
            echo '#PBS -A P48500028' >> $CommandFile
            echo '#PBS -q regular' >> $CommandFile
            echo '#PBS -l walltime=12:00:00' >> $CommandFile
            echo '#PBS -l select=1:ncpus=1' >> $CommandFile
            echo "#PBS -o $LogFile.o" >> $CommandFile 
            echo "#PBS -e $LogFile.e" >> $CommandFile 

            echo 'export TMPDIR=/glade/scratch/hongli/tmp' >> $CommandFile
            echo 'mkdir -p $TMPDIR' >> $CommandFile

            echo "$ConfigFile" >> $CommandFile
            chmod 744 $CommandFile 

            qsub $CommandFile
        done
    done
done

