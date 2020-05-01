#!/bin/bash
set -e

# H. liu, April 28, 2020.
# Bias correct NLDAS-based GMET ensemble in comparison with NLDAS data.
  
RootDir=/glade/u/home/hongli/scratch/2020_04_21nldas_gmet #cheyenne
NewNldasDir=$RootDir/data/nldas_daily_utc_convert
EnsDirBase=$RootDir/test_uniform
Template=$RootDir/scripts/config/biascorrect.TEMPLATE.sh

startEns=1   # start number of ensembles to generate
stopEns=3 #100  # stop number of ensembles to generate
numEns=$(($stopEns - $startEns +1))

sYear=2015 
eYear=2016

#==========================bias correction===========================
# loop all stnlist files
FILES=( $(ls ${EnsDirBase}) )
FILE_NUM=${#FILES[@]}
# for i in $(seq 0 $(($FILE_NUM -1))); do
for i in $(seq 6 7); do
    
    CaseID=${FILES[${i}]}
    echo $CaseID

    for Y in $(seq $sYear $eYear); do
        echo $Y

        # setup configuration file
        if [ ! -d $EnsDirBase/$CaseID/tmp ]; then mkdir $EnsDirBase/$CaseID/tmp; fi
        ConfigFile=$EnsDirBase/$CaseID/tmp/config.bias_corr.$Y.sh
        NldasFile=$NewNldasDir/NLDAS_$Y.nc

        sed "s,ROOTDIR,$RootDir,g" $Template |\
        sed "s,ENSDIRBASE,$EnsDirBase,g" |\
        sed "s,STARTENS,$startEns,g" |\
        sed "s,STOPENS,$stopEns,g" |\
        sed "s,NLDASFILE,$NldasFile,g" |\
        sed "s,CASEID,$CaseID,g" |\
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
        echo '#PBS -l walltime=04:00:00' >> $CommandFile
        echo '#PBS -l select=1:ncpus=1' >> $CommandFile
        echo "#PBS -o $LogFile.o.%j" >> $CommandFile 
        echo "#PBS -e $LogFile.e.%j" >> $CommandFile 

        echo 'export TMPDIR=/glade/scratch/hongli/tmp' >> $CommandFile
        echo 'mkdir -p $TMPDIR' >> $CommandFile

        echo "$ConfigFile" >> $CommandFile
        chmod 744 $CommandFile 

        #qsub $CommandFile
    done
done

