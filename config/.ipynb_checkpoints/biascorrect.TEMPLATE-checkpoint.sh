#!/bin/bash
set -e

# H. liu, April 30, 2020.
# Bias correct NLDAS-based GMET ensemble in comparison with NLDAS data.

#==========================input (need update)=========================== 
RootDir=ROOTDIR 
NldasDir=$RootDir/data/nldas_daily_utc
SourceDir=$RootDir/scripts

EnsDirBase=ENSDIRBASE
if [ ! -d $EnsDirBase ]; then mkdir -p $EnsDirBase; fi

startEns=STARTENS   # start number of ensembles to generate
stopEns=STOPENS  # stop number of ensembles to generate
sYear=SYEAR 
eYear=EYEAR

numEns=$(($stopEns - $startEns +1))
numYear=$(($eYear - $sYear +1))

OutputDir=OUTPUTDIR
if [ ! -d $OutputDir ]; then mkdir -p $OutputDir; fi

NldasFormtFile=NLDASFORMTFILE
CaseID=CASEID

#==========================bias correction (no need to update)===========================

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
#for M in $(seq ${startEns} ${stopEns}); do
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

