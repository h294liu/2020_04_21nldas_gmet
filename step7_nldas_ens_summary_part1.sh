#!/bin/bash
set -e

# H. liu, May 1, 2020.
# ensemble statistic summary.
  
RootDir=/glade/u/home/hongli/scratch/2020_04_21nldas_gmet #cheyenne
EnsDirBase=$RootDir/test_uniform_perturb

configFileName=ens_summary_part1.sh
configFileNameShort="${configFileName/.sh/}"
Template=$RootDir/scripts/config/$configFileName

EnsFolders=(gmet_ens gmet_ens_bc)
# EnsFolders=(gmet_ens_bc)
sYear=2012 
eYear=2016
cdoMetrics=(ensmean ensstd enspctl)
Pths=(5 95 25 50 75)

#==========================bias correction===========================
# loop all stnlist files
FILES=( $(ls ${EnsDirBase}) )
FILE_NUM=${#FILES[@]}
# for i in $(seq 1 $(($FILE_NUM -1))); do
for i in $(seq $(($FILE_NUM -2)) $(($FILE_NUM -2))); do
    
    CaseID=${FILES[${i}]}
    echo $CaseID
        
    # loop ensemble and bias-correct ensemble 
    for EnsFolder in ${EnsFolders[@]}; do
        echo ------------------------------
        echo $EnsFolder

        # set up ensemble folders
        EnsDir=$EnsDirBase/$CaseID/$EnsFolder
        TmpDir=$EnsDirBase/$CaseID/tmp
        EnsSumDir=$EnsDirBase/$CaseID/${EnsFolder}_summary
        if [ ! -d $TmpDir ]; then mkdir $TmpDir; fi
        if [ ! -d $EnsSumDir ]; then mkdir $EnsSumDir; fi

        # loop years
        for Y in $(seq $sYear $eYear); do
            echo $Y   

            # loop metrics
            for Metric in ${cdoMetrics[@]}; do

                if [ $Metric = ensmean ] || [ $Metric = ensstd ]; then
                    echo $Metric

                    # (1) setup configuration file
                    ConfigFile=$TmpDir/$configFileNameShort.${EnsFolder}_summary.$Y.$Metric.sh
                    sed "s,ENSDIRBASE,$EnsDirBase,g" $Template |\
                    sed "s,CASEID,$CaseID,g" |\
                    sed "s,ENSFOLDER,$EnsFolder,g" |\
                    sed "s,YEAR,$Y,g" |\
                    sed "s,METRIC,$Metric,g" > $ConfigFile 
                    chmod 744 $ConfigFile

                    # (2) create job submission file
                    CommandFile=$TmpDir/qsub.$configFileNameShort.${EnsFolder}_summary.$Y.$Metric.sh
                    LogFile=$TmpDir/log.$configFileNameShort.${EnsFolder}_summary.$Y.$Metric
                    rm -f ${CommandFile} $LogFile.*

                    echo '#!/bin/bash' > $CommandFile
                    echo "#PBS -N smry.$CaseID" >> $CommandFile
                    echo '#PBS -A P48500028' >> $CommandFile
                    echo '#PBS -q regular' >> $CommandFile
                    echo '#PBS -l walltime=01:00:00' >> $CommandFile
                    echo '#PBS -l select=1:ncpus=1' >> $CommandFile
                    echo "#PBS -o $LogFile.o" >> $CommandFile 
                    echo "#PBS -e $LogFile.e" >> $CommandFile 

                    echo 'export TMPDIR=/glade/scratch/hongli/tmp' >> $CommandFile
                    echo 'mkdir -p $TMPDIR' >> $CommandFile

                    echo "$ConfigFile" >> $CommandFile
                    chmod 744 $CommandFile 
                    qsub $CommandFile

                elif [ $Metric = enspctl ]; then
                    for Pth in ${Pths[@]}; do
                        echo $Metric.$Pth

                        # (1) setup configuration file
                        ConfigFile=$TmpDir/config.${EnsFolder}_summary.$Y.$Metric.$Pth.sh
                        sed "s,ENSDIRBASE,$EnsDirBase,g" $Template |\
                        sed "s,CASEID,$CaseID,g" |\
                        sed "s,ENSFOLDER,$EnsFolder,g" |\
                        sed "s,YEAR,$Y,g" |\
                        sed "s,METRIC,$Metric,g" |\
                        sed "s,PTH,$Pth,g" > $ConfigFile  
                        chmod 744 $ConfigFile

                        # (2) create job submission file
                        CommandFile=$TmpDir/qsub.${EnsFolder}_summary.$Y.$Metric.$Pth
                        LogFile=$TmpDir/log.${EnsFolder}_summary.$Y.$Metric.$Pth
                        rm -f ${CommandFile} $LogFile.*

                        echo '#!/bin/bash' > $CommandFile
                        echo "#PBS -N smry.$CaseID" >> $CommandFile
                        echo '#PBS -A P48500028' >> $CommandFile
                        echo '#PBS -q regular' >> $CommandFile
                        echo '#PBS -l walltime=01:00:00' >> $CommandFile
                        echo '#PBS -l select=1:ncpus=1' >> $CommandFile
                        echo "#PBS -o $LogFile.o" >> $CommandFile 
                        echo "#PBS -e $LogFile.e" >> $CommandFile 

                        echo 'export TMPDIR=/glade/scratch/hongli/tmp' >> $CommandFile
                        echo 'mkdir -p $TMPDIR' >> $CommandFile

                        echo "$ConfigFile" >> $CommandFile
                        chmod 744 $CommandFile 
                        qsub $CommandFile
                    done
                fi

            done
        done
    done
done

