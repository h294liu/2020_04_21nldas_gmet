#!/bin/bash
set -e

# H. liu, April 28, 2020.
# Convert original NLDAS netcdf to the GMET output format.
# This is for ensemble bias correction.
  
RootDir=/glade/u/home/hongli/scratch/2020_04_21nldas_gmet #cheyenne
WorkDir=/glade/u/home/hongli/scratch/2020_04_21nldas_gmet/data
NldasDir=$RootDir/data/nldas_daily_utc
sYear=1988 #1979 
eYear=2019

NewNldasDir=$RootDir/data/nldas_daily_utc_convert
if [ ! -d $NewNldasDir ]; then mkdir -p $NewNldasDir; fi

# Update setup
configFileName=convert_nldas.sh
configFileNameShort="${configFileName/.sh/}"
Template=/glade/u/home/hongli/github/2020_04_21nldas_gmet/config/$configFileName

#====================NLDAS data pre-process (once for all)===========================
echo NLDAS data pre-process
for Y in $(seq $sYear $eYear); do
    echo $Y
    
    NldasOriginFile=$NldasDir/NLDAS_$Y.nc
    TmpFile=$NewNldasDir/NLDAS_${Y}_tmp.nc
    NldasNewFile=$NewNldasDir/NLDAS_$Y.nc
 
    # configure config, output and log files
    ConfigFileName=$configFileNameShort.$Y.sh
    ConfigFile=${WorkDir}/tmp/$ConfigFileName

    sed "s,YEAR,$Y,g" $Template |\
    sed "s,ORIGINFILE,$NldasOriginFile,g" |\
    sed "s,TMPFILE,$TmpFile,g" |\
    sed "s,NEWFILE,$NldasNewFile,g" > $ConfigFile
    chmod 740 ${ConfigFile}

     # create job submission file
    CommandFile=${WorkDir}/tmp/qsub.$configFileNameShort.$Y.sh
    if [ -e ${CommandFile} ]; then rm -rf ${CommandFile}; fi

    LogFile=${WorkDir}/tmp/log.$configFileNameShort.$Var
    rm -f $LogFile.*

    echo '#!/bin/bash' > ${CommandFile}
    echo "#PBS -N ${Y}" >> ${CommandFile}
    echo '#PBS -A P48500028' >> ${CommandFile}
    echo '#PBS -q regular' >> ${CommandFile}
    echo '#PBS -l select=1:ncpus=1:mpiprocs=1' >> ${CommandFile}
    echo '#PBS -l walltime=00:10:00' >> ${CommandFile}
    echo "#PBS -o ${LogFile}.o" >> ${CommandFile}
    echo "#PBS -e ${LogFile}.e" >> ${CommandFile}

    echo "mkdir -p /glade/scratch/hongli/temp" >> ${CommandFile}
    echo "export TMPDIR=/glade/scratch/hongli/temp" >> ${CommandFile}

    echo "cd ${WorkDir}/tmp/" >> ${CommandFile}
    echo "./${ConfigFileName}" >> ${CommandFile}
    chmod 740 ${CommandFile}

    qsub ${CommandFile}

done



