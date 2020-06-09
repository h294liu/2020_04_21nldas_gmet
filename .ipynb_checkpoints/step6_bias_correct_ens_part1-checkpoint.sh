#!/bin/bash
set -e

# H. liu, April 28, 2020.
# Bias correct NLDAS-based GMET ensemble in comparison with NLDAS data.
  
RootDir=/glade/u/home/hongli/scratch/2020_04_21nldas_gmet #cheyenne
NewNldasDir=$RootDir/data/nldas_daily_utc_convert
EnsDirBase=$RootDir/test_uniform_perturb

Template=$RootDir/scripts/config/biascorrect_part1.sh
SubstractPy=$RootDir/scripts/config/substract.py
AdditionPy=$RootDir/scripts/config/addition.py

startEns=1   # start number of ensembles to generate
stopEns=100  # stop number of ensembles to generate
interval=5

sYear=2015 
eYear=2016

#==========================bias correction===========================
# loop all stnlist files
FILES=( $(ls ${EnsDirBase}) )
FILE_NUM=${#FILES[@]}
for i in $(seq 1 $(($FILE_NUM -1))); do
# for i in $(seq 0 0); do
    
    CaseID=${FILES[${i}]}
    echo $CaseID
    
    EnsDir=$EnsDirBase/$CaseID/gmet_ens
    EnsBcDir=$EnsDirBase/$CaseID/gmet_ens_bc
    TmpDir=$EnsDirBase/$CaseID/tmp
    if [ ! -d $EnsBcDir ]; then mkdir $EnsBcDir; fi
    if [ ! -d $TmpDir ]; then mkdir $TmpDir; fi

    for Y in $(seq $sYear $eYear); do
        echo $Y
    
        # remove useless files
        ConfigFile=$EnsDirBase/$CaseID/tmp/config.bias_corr.$Y.sh
        CommandFile=$EnsDirBase/$CaseID/tmp/qsub.bias_corr.$Y
        LogFile1=$EnsDirBase/$CaseID/tmp/log.bias_corr.$Y.o
        LogFile2=$EnsDirBase/$CaseID/tmp/log.bias_corr.$Y.e
        for file in $ConfigFile $CommandFile $LogFile1 $LogFile2; do
            if [ -e $file ]; then rm $file; fi
        done        

        # setup configuration file
        ConfigFile=$EnsDirBase/$CaseID/tmp/config.bias_corr.$Y.sh
        NldasFile=$NewNldasDir/NLDAS_$Y.nc

        sed "s,ENSDIR,$EnsDir,g" $Template |\
        sed "s,ENSBCDIR,$EnsBcDir,g" |\
        sed "s,TMPDIR,$TmpDir,g" |\
        sed "s,STARTENS,$startEns,g" |\
        sed "s,STOPENS,$stopEns,g" |\
        sed "s,NLDASFILE,$NldasFile,g" |\
        sed "s,YEAR,$Y,g" > $ConfigFile
        chmod 744 $ConfigFile

        # create job submission file
        CommandFile=$EnsDirBase/$CaseID/tmp/qsub.bias_corr.$Y
        LogFile=$EnsDirBase/$CaseID/tmp/log.bias_corr.$Y
        rm -f ${CommandFile} $LogFile.*

        echo '#!/bin/bash' > $CommandFile
        echo "#PBS -N bias.$CaseID" >> $CommandFile
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

