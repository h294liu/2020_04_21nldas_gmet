#!/bin/bash
set -e

# H. liu, April 30, 2020.
# ensemble summary statistics, such as mean, std, median, and percentiles.

#==========================input (need update)=========================== 
EnsDirBase=ENSDIRBASE # ens results' parent directory
CaseID=CASEID
EnsFolder=ENSFOLDER
Year=YEAR
Metric=METRIC
Pth=PTH

#==========================bias correction (no need to update)===========================
module load cdo

echo $CaseID,$Year
EnsDir=$EnsDirBase/$CaseID/$EnsFolder
EnsFile=$EnsDir/ens_forc.$Year.*.nc
EnsSumDir=$EnsDirBase/$CaseID/${EnsFolder}_summary

if [ $Metric = ensmean ] || [ $Metric = ensstd1 ]; then
    echo $Metric   
    OutputFile=$EnsSumDir/ens_forc.$Year.$Metric.nc
    rm -f $OutputFile
    cdo $Metric $EnsFile $OutputFile
    
    # add back some variables that are mistakenly processsed by ensstd
    if [ $Metric = ensstd1 ]; then
        # (1) create a static netcdf that has correct variable values 
        # for latitude,longitude,elevation,data_mask
        ref_nc=$EnsDir/ens_forc.$Year.001.nc
        static_nc=$EnsSumDir/static_var.nc
        
        if [ ! -f $static_nc ]; then
            ncks -h -v latitude,longitude,elevation,data_mask $ref_nc $static_nc
        fi
        # (2) append these variables to std result
        ncks -h -A -v latitude,longitude,elevation,data_mask $static_nc $OutputFile 
    fi

    ncatted -h -O -a history,global,d,, $OutputFile # remove history
#     ncatted -h -a _FillValue,,o,d,1e+20 $OutputFile # modify missing value to the same as gmet data

elif [ $Metric = enspctl ]; then
    echo $Metric.$Pth        
    OutputFile=$EnsSumDir/ens_forc.$Year.$Metric.$Pth.nc
    rm -f $OutputFile
    cdo $Metric,$Pth $EnsFile $OutputFile

    ncatted -h -O -a history,global,d,, $OutputFile # remove history
#     ncatted -h -a _FillValue,,o,d,1e+20 $OutputFile # modify missing value to the same as gmet data
fi
