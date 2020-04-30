#!/bin/bash
set -e

# H. liu, April 28, 2020.
# Bias correct NLDAS-based GMET ensemble in comparison with NLDAS data.
  
RootDir=/glade/u/home/hongli/work/2020_04_21nldas_gmet #cheyenne
NldasDir=$RootDir/data/nldas_daily_utc
SourceDir=$RootDir/scripts

EnsDirBase=$RootDir/test_uniform
if [ ! -d $EnsDirBase ]; then mkdir -p $EnsDirBase; fi

startEns=1   # start number of ensembles to generate
stopEns=100  # stop number of ensembles to generate
sYear=2015 
eYear=2016

numEns=$(($stopEns - $startEns +1))
numYear=$(($eYear - $sYear +1))

Template=${SourceDir}/config/biascorrect.TEMPLATE.sh
OutputDir=$SourceDir/step9_bias_correct_ens
if [ ! -d $OutputDir ]; then mkdir -p $OutputDir; fi

#====================NLDAS pre-process (once for all)===========================
NldasRawFile=$OutputDir/NLDAS_${sYear}-${eYear}.raw.nc
NldasUnitFile=$OutputDir/NLDAS_${sYear}-${eYear}.unit.nc
NldasFormtFile=$OutputDir/NLDAS_${sYear}-${eYear}.formt.nc

# rm -f $NldasRawFile $NldasUnitFile $NldasFormtFile
# # concatenate NLDAS records (time,y,x)
# echo concatenate NLDAS records
# ncrcat -h -n $numYear,4,1 -v prcp_avg,tair_avg ${NldasDir}/NLDAS_$sYear.nc $NldasRawFile

# # convert units (pcp: mm/hr -> mm/day, t: K -> degC)
# echo convert units
# ncap2 -h -s "prcp_avg=prcp_avg*24;tair_avg=tair_avg-273.15" $NldasRawFile $NldasUnitFile

# # change NLDAS data's dimension & variable names to be same as GMET output's
# echo change dimension and variable names
# ncrename -d lon_110,y -d lat_110,x -v prcp_avg,pcp -v tair_avg,t_mean $NldasUnitFile $NldasFormtFile

#==========================bias correction===========================
# loop all stnlist files
FILES=( $(ls ${EnsDirBase}) )
FILE_NUM=${#FILES[@]}
#for i in $(seq 0 $(($FILE_NUM -1))); do
for i in $(seq 0 1); do
    
    CaseID=${FILES[${i}]}
    echo $CaseID
    
    # setup configuration file
    if [ ! -d $EnsDirBase/$CaseID/tmp ]; then mkdir $EnsDirBase/$CaseID/tmp; fi
    ConfigFile=$EnsDirBase/$CaseID/tmp/config.BiasCorrect.sh
    
    sed "s,ROOTDIR,$RootDir,g" $Template |\
    sed "s,ENSDIRBASE,$EnsDirBase,g" |\
    sed "s,STARTENS,$startEns,g" |\
    sed "s,STOPENS,$stopEns,g" |\
    sed "s,SYEAR,$sYear,g" |\
    sed "s,EYEAR,$eYear,g" |\
    sed "s,OUTPUTDIR,$OutputDir,g" |\
    sed "s,NLDASFORMTFILE,$NldasFormtFile,g" |\
    sed "s,CASEID,$CaseID,g" > $ConfigFile 
    chmod 744 $ConfigFile
    
    # create job submission file
    CommandFile=$EnsDirBase/$CaseID/tmp/qsub.BiasCorrect
    LogFile=$EnsDirBase/$CaseID/tmp/log.BiasCorrect
    rm -f ${CommandFile} $LogFile.*

    echo '#!/bin/bash' > $CommandFile
    echo "#PBS -N bias.$CaseID" >> $CommandFile
    echo '#PBS -A P48500028' >> $CommandFile
    echo '#PBS -q regular' >> $CommandFile
    echo '#PBS -l walltime=01:00:00' >> $CommandFile
    echo '#PBS -l select=1:ncpus=1' >> $CommandFile
    echo '#PBS -j oe' >> $CommandFile 

    echo 'export TMPDIR=/glade/scratch/hongli/tmp' >> $CommandFile
    echo 'mkdir -p $TMPDIR' >> $CommandFile
    
    echo "$ConfigFile" >> $CommandFile
    chmod 744 $CommandFile 
    
    #qsub $CommandFile

done

