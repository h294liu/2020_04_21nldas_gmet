#!/bin/bash
set -e

# H. liu, April 28, 2020.
# calculate x-median for each ensemble member (final goal is MAD).
  
RootDir=/glade/u/home/hongli/scratch/2020_04_21nldas_gmet #cheyenne
EnsDirBase=$RootDir/test_uniform_perturb
Template=$RootDir/scripts/config/ens_summary_part2.sh

EnsFolders=(gmet_ens gmet_ens_bc)

startEns=1   # start number of ensembles to generate
stopEns=100  # stop number of ensembles to generate
interval=5

sYear=2015 
eYear=2016

#==========================bias correction===========================
# loop all stnlist files
FILES=( $(ls ${EnsDirBase}) )
FILE_NUM=${#FILES[@]}
for i in $(seq 0 $(($FILE_NUM -1))); do
# for i in $(seq 0 0); do
    
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

        for Y in $(seq $sYear $eYear); do        

            # split jobs based on ensemble member ininterval
            for startEns_i in $(seq $startEns $interval $(( $stopEns - 1 ))); do
                stopEns_i=$(( $startEns_i + $interval - 1 ))
                echo $Y $startEns_i $stopEns_i

                # setup configuration file
                ConfigFile=$EnsDirBase/$CaseID/tmp/config.${EnsFolder}.abs_x_median.$Y.${startEns_i}_${stopEns_i}.sh

                sed "s,ENSDIR,$EnsDir,g" $Template |\
                sed "s,ENSSUMDIR,$EnsSumDir,g" |\
                sed "s,STARTENS,$startEns_i,g" |\
                sed "s,STOPENS,$stopEns_i,g" |\
                sed "s,YEAR,$Y,g" > $ConfigFile
                chmod 744 $ConfigFile

                # create job submission file
                CommandFile=$EnsDirBase/$CaseID/tmp/qsub.${EnsFolder}.abs_x_median.$Y.${startEns_i}_${stopEns_i}
                LogFile=$EnsDirBase/$CaseID/tmp/log.${EnsFolder}.abs_x_median.$Y.${startEns_i}_${stopEns_i}
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
done

