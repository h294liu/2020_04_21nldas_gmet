#!/bin/bash
set -e

# H. liu, May 1, 2020.
# Bias correct NLDAS-based GMET ensemble in comparison with NLDAS data.
  
RootDir=/glade/u/home/hongli/scratch/2020_04_21nldas_gmet #cheyenne
EnsDirBase=$RootDir/data
Template=$RootDir/scripts/config/ens_summary_NLDAS.TEMPLATE.sh

EnsFolder=stn_ens
sYear=1980 
# sYear=2015 
eYear=2016
cdoMetrics=(ensmean ensstd enspctl)
Pths=(5 95)

#==========================bias correction===========================
# set up ensemble folders
EnsDir=$EnsDirBase/$EnsFolder
TmpDir=$EnsDirBase/tmp
if [ ! -d $TmpDir ]; then mkdir $TmpDir; fi

# loop years
for Y in $(seq $sYear $eYear); do
    echo $Y   

    # loop metrics
    for Metric in ${cdoMetrics[@]}; do
        
        if [ $Metric = ensmean ] || [ $Metric = ensstd ]; then
            echo $Metric

            # (1) setup configuration file
            ConfigFile=$TmpDir/config.${EnsFolder}_summary.$Y.$Metric.sh
            sed "s,ENSDIRBASE,$EnsDirBase,g" $Template |\
            sed "s,ENSFOLDER,$EnsFolder,g" |\
            sed "s,YEAR,$Y,g" |\
            sed "s,METRIC,$Metric,g" > $ConfigFile 
            chmod 744 $ConfigFile

            # (2) create job submission file
            CommandFile=$TmpDir/qsub.${EnsFolder}_summary.$Y.$Metric
            LogFile=$TmpDir/log.${EnsFolder}_summary.$Y.$Metric
            rm -f ${CommandFile} $LogFile.*

            echo '#!/bin/bash' > $CommandFile
            echo "#PBS -N smry.$Y" >> $CommandFile
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
    
        elif [ $Metric = enspctl ]; then
            for Pth in ${Pths[@]}; do
                echo $Metric.$Pth
                
                # (1) setup configuration file
                ConfigFile=$TmpDir/config.${EnsFolder}_summary.$Y.$Metric.$Pth.sh
                sed "s,ENSDIRBASE,$EnsDirBase,g" $Template |\
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
                echo "#PBS -N smry.$Y" >> $CommandFile
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
        fi
        
    done
done


