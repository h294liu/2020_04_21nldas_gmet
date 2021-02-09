#!/bin/bash
set -e

# H. liu, April 28, 2020.
# Bias correct NLDAS-based GMET ensemble in comparison with NLDAS data.
  
RootDir=/glade/u/home/hongli/scratch/2020_04_21nldas_gmet #cheyenne
NewNldasDir=$RootDir/data/nldas_daily_utc_convert
EnsDirBase=$RootDir/test_uniform_perturb

configFileName=biascorrect_part2.sh
configFileNameShort="${configFileName/.sh/}"
Template=$RootDir/scripts/config/$configFileName

startEns=1   # start number of ensembles to generate
stopEns=100  # stop number of ensembles to generate
interval=5

sYear=2005 #1979 #2016 
eYear=2006 #2019 #2016

#==========================bias correction===========================
# loop all stnlist files
FILES=( $(ls ${EnsDirBase}) )
FILE_NUM=${#FILES[@]}
# for i in $(seq 0 $(($FILE_NUM -1))); do
for i in $(seq $(($FILE_NUM -1)) $(($FILE_NUM -1))); do
    
    CaseID=${FILES[${i}]}
    echo $CaseID
    
    EnsDir=$EnsDirBase/$CaseID/gmet_ens
    EnsBcDir=$EnsDirBase/$CaseID/gmet_ens_bc
    TmpDir=$EnsDirBase/$CaseID/tmp
    if [ ! -d $EnsBcDir ]; then mkdir $EnsBcDir; fi
    if [ ! -d $TmpDir ]; then mkdir $TmpDir; fi

    for Y in $(seq $sYear $eYear); do        
        
        # split jobs based on ensemble member ininterval
        for startEns_i in $(seq $startEns $interval $(( $stopEns - 1 ))); do
            stopEns_i=$(( $startEns_i + $interval - 1 ))
            echo $Y $startEns_i $stopEns_i

            # setup configuration file
            ConfigFile=$EnsDirBase/$CaseID/tmp/$configFileNameShort.$Y.${startEns_i}_${stopEns_i}.sh

            sed "s,ENSDIR,$EnsDir,g" $Template |\
            sed "s,ENSBCDIR,$EnsBcDir,g" |\
            sed "s,TMPDIR,$TmpDir,g" |\
            sed "s,STARTENS,$startEns_i,g" |\
            sed "s,STOPENS,$stopEns_i,g" |\
            sed "s,YEAR,$Y,g" > $ConfigFile
            chmod 744 $ConfigFile

            # create job submission file
            CommandFile=$EnsDirBase/$CaseID/tmp/qsub.$configFileNameShort.$Y.${startEns_i}_${stopEns_i}.sh
            LogFile=$EnsDirBase/$CaseID/tmp/log.$configFileNameShort.$Y.${startEns_i}_${stopEns_i}
            rm -f ${CommandFile} $LogFile.*

            echo '#!/bin/bash' > $CommandFile
            echo "#PBS -N bias.$CaseID" >> $CommandFile
            echo '#PBS -A P48500028' >> $CommandFile
            echo '#PBS -q regular' >> $CommandFile
            echo '#PBS -l walltime=00:30:00' >> $CommandFile
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

