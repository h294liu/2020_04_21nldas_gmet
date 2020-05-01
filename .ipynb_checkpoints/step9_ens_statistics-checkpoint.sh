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
echo numEns:$numEns, numYear:$numYear

OutputDir=$SourceDir/step9_bias_correct_ens
if [ ! -d $OutputDir ]; then mkdir -p $OutputDir; fi

#====================NLDAS pre-process (once for all)===========================
NldasRawFile=$OutputDir/NLDAS_${sYear}-${eYear}.raw.nc
NldasUnitFile=$OutputDir/NLDAS_${sYear}-${eYear}.unit.nc
NldasFormtFile=$OutputDir/NLDAS_${sYear}-${eYear}.formt.nc
#for file in $NldasRawFile $NldasUnitFile $NldasFormtFile; do
#    if [ -e $file ]; then rm $file; fi
#done
rm -f $NldasRawFile $NldasUnitFile $NldasFormtFile

# concatenate NLDAS records (time,y,x)
echo concatenate NLDAS records
ncrcat -h -n $numYear,4,1 -v prcp_avg,tair_avg ${NldasDir}/NLDAS_$sYear.nc $NldasRawFile

# convert units (pcp: mm/hr -> mm/day, t: K -> degC)
echo convert units
ncap2 -h -s "prcp_avg=prcp_avg*24;tair_avg=tair_avg-273.15" $NldasRawFile $NldasUnitFile

# change NLDAS data's dimension & variable names to be same as GMET output's
echo change dimension and variable names
ncrename -d lon_110,y -d lat_110,x -v prcp_avg,pcp -v tair_avg,t_mean $NldasUnitFile $NldasFormtFile

#==========================bias correction===========================
# loop all stnlist files
FILES=( $(ls ${EnsDirBase}) )
FILE_NUM=${#FILES[@]}
#for i in $(seq 0 $(($FILE_NUM -1))); do
for i in $(seq 0 1); do
    
    CaseID=${FILES[${i}]}
    echo $CaseID

    # configure ensemble results folders
    EnsDir=$EnsDirBase/$CaseID/gmet_ens_combine
    EnsBcDir=$EnsDirBase/$CaseID/gmet_ens_combine_bc
    if [ ! -d $EnsBcDir ]; then mkdir $EnsBcDir; fi
     
    # calculate ensemble mean over members (time,y,x)
    echo calculate ensmeble mean
    EnsFile=$EnsDir/ens_forc.$sYear-$eYear.001.nc
    EnsMeanFile=$OutputDir/ens_forc.$sYear-$eYear.mean.$CaseID.nc
    #if [ -e $EnsMeanFile ]; then rm $EnsMeanFile; fi
    rm -f $EnsMeanFile
    ncea -n $numEns,3,1 -v pcp,t_mean $EnsFile $EnsMeanFile # -n file_number,digit_number,numeric_increment
    
    # calculate delta = NLDAS - ensemble mean
    echo calculate delta
    EnsBiasFile=$OutputDir/ens_forc.$sYear-$eYear.bias.$CaseID.nc
    #if [ -e $EnsBiasFile ]; then rm $EnsBiasFile; fi
    rm -f $EnsBiasFile
    ncflint -w -1,1 -v pcp,t_mean $EnsMeanFile $NldasFormtFile $EnsBiasFile # output is in file1 format 
    
    # bias correct all ensmeble members
    echo bias correct
#     for M in $(seq ${startEns} ${stopEns}); do
    for M in $(seq ${startEns} 2); do
        
        NUM=$(echo $M | awk '{printf("%03d",$1)}')
        echo ens member $NUM
        
        # clear existing output file
        InFile=$EnsDir/ens_forc.$sYear-$eYear.$NUM.nc 
        TmpFile=$EnsBcDir/BiasCorr.nc
        OutputFile=$EnsBcDir/ens_forc.$sYear-$eYear.$NUM.nc 
        rm -f $OutputFile
        
        # bias correct
        ncflint -w 1,1 -v pcp,t_mean $InFile $EnsBiasFile $TmpFile
        
        # add corrected P and T to OutputFile
        cp $InFile $OutputFile
        ncks -A -v pcp,t_mean $TmpFile $OutputFile
        rm -f $TmpFile 
        
    done
done

