#!/bin/bash
set -e

# H. liu, May 6, 2020.
# Bias correct NLDAS-based GMET ensemble in comparison with NLDAS data.
  
ScriptPath=/glade/u/home/hongli/github/2020_04_21nldas_gmet/step7_stn_ens_summary_function.py
EnsDirBase=/glade/u/home/hongli/scratch/2020_04_21nldas_gmet/data
EnsFolder=stn_ens

# sYear=1980 
sYear=2015 
eYear=2016

startEns=1
stopEns=100

lb_perct=5
ub_perct=95

#==========================bias correction===========================
# loop all stnlist files
FILES=( $(ls ${EnsDirBase}) )
FILE_NUM=${#FILES[@]}
    
# set up ensemble folders
EnsDir=$EnsDirBase/$EnsFolder
TmpDir=$EnsDirBase/tmp
if [ ! -d $TmpDir ]; then mkdir $TmpDir; fi

# loop years
for Y in $(seq $sYear $eYear); do
    echo $Y   
                
    CommandFile=$TmpDir/qsub.${EnsFolder}_summary.$Y
    LogFile=$TmpDir/log.${EnsFolder}_summary.$Y
    rm -f ${CommandFile} $LogFile.*

    echo '#!/bin/bash' > $CommandFile
    echo "#PBS -N smry.$Y" >> $CommandFile
    echo '#PBS -A P48500028' >> $CommandFile
    echo '#PBS -q regular' >> $CommandFile
    echo '#PBS -l walltime=12:00:00' >> $CommandFile
#     echo '#PBS -l select=1:ncpus=1:mem=109GB' >> $CommandFile
    echo '#PBS -l select=1:ncpus=1:mem=365GB' >> $CommandFile
    echo "#PBS -o $LogFile.o" >> $CommandFile 
    echo "#PBS -e $LogFile.e" >> $CommandFile 

    echo 'export TMPDIR=/glade/scratch/hongli/tmp' >> $CommandFile
    echo 'mkdir -p $TMPDIR' >> $CommandFile

    echo 'module load peak_memusage' >> $CommandFile
    echo "peak_memusage.exe python $ScriptPath $EnsDirBase $EnsFolder $Y $startEns $stopEns $lb_perct $ub_perct" >> $CommandFile
    chmod 744 $CommandFile 
    qsub $CommandFile

done


