#!/bin/bash
set -e

# H. liu, May 6, 2020.
# Calculate Andy N's station-based ensemble statistics
# Mean, median, standard deviation, 95th and 5th percentiles.
  
ScriptPath=/glade/u/home/hongli/github/2020_04_21nldas_gmet/step7_stn_ens_summary_function.py
EnsDirBase=/glade/u/home/hongli/scratch/2020_04_21nldas_gmet/data
EnsFolder=stn_ens

# sYear=1980 
# eYear=2014
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
                
    CommandFile=$TmpDir/sbatch.${EnsFolder}_summary.$Y
    LogFile=$TmpDir/log.${EnsFolder}_summary.$Y
    rm -f ${CommandFile} $LogFile.*

    echo '#!/bin/bash -l' > $CommandFile
    echo "#SBATCH --job-name=smry.$Y" >> $CommandFile
    echo '#SBATCH --account=P48500028' >> $CommandFile
    echo '#SBATCH --ntasks=1' >> $CommandFile
    echo '#SBATCH --time=04:30:00' >> $CommandFile
    echo '#SBATCH --mem=256000' >> $CommandFile # memory in MB. 250GB. Actually only uses 182GB.
    echo '#SBATCH --partition=dav' >> $CommandFile 
    echo "#SBATCH --output=$LogFile.%j" >> $CommandFile 

    echo 'export TMPDIR=/glade/scratch/hongli/tmp' >> $CommandFile
    echo 'mkdir -p $TMPDIR' >> $CommandFile
    
    echo "module load python/3.7.5" >> $CommandFile
    echo "ncar_pylib" >> $CommandFile
    echo "python $ScriptPath $EnsDirBase $EnsFolder $Y $startEns $stopEns $lb_perct $ub_perct" >> $CommandFile
    chmod 744 $CommandFile 
    sbatch $CommandFile

done
