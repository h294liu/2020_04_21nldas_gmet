#!/bin/bash
set -e

# H. liu, April 28, 2020.
# Bias correct NLDAS-based GMET ensemble in comparison with NLDAS data.
  
RootDir=/glade/u/home/hongli/scratch/2020_04_21nldas_gmet #cheyenne
EnsDir=/glade/p/ral/hap/anewman/conus_v1p2/eighth/v2_landmask
Template=$RootDir/scripts/config/cal_tmin_tmax_STN.sh

OutputDir=$RootDir/data/stn_ens
TmpDir=$RootDir/data/tmp
if [ ! -d $OutputDir ]; then mkdir $OutputDir; fi
if [ ! -d $TmpDir ]; then mkdir $TmpDir; fi

startEns=1   # start number of ensembles to generate
stopEns=100  # stop number of ensembles to generate
interval=5

sYear=1980 
eYear=2014
# sYear=2015 
# eYear=2016

#==========================bias correction===========================
for Y in $(seq $sYear $eYear); do        
    for startEns_i in $(seq $startEns $interval $(( $stopEns - 1 ))); do
        
        stopEns_i=$(( $startEns_i + $interval - 1 ))
        echo $Y ${startEns_i}_${stopEns_i}

        # setup configuration file        
        ConfigFile=$TmpDir/config.tmin_tmax.$Y.${startEns_i}_${stopEns_i}.sh

        sed "s,ENSDIR,$EnsDir,g" $Template |\
        sed "s,OUTPUTDIR,$OutputDir,g" |\
        sed "s,YEAR,$Y,g" |\
        sed "s,STARTENS,$startEns_i,g" |\
        sed "s,STOPENS,$stopEns_i,g" > $ConfigFile
        chmod 744 $ConfigFile

        # create job submission file
        CommandFile=$TmpDir/qsub.tmin_tmax.$Y.${startEns_i}_${stopEns_i}
        LogFile=$TmpDir/log.tmin_tmax.$Y.${startEns_i}_${stopEns_i}
        rm -f ${CommandFile} $LogFile.*

        echo '#!/bin/bash' > $CommandFile
        echo "#PBS -N temp.$CaseID" >> $CommandFile
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
done


