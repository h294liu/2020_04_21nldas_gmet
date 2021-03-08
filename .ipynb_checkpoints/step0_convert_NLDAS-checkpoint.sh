#!/bin/bash
set -e

# H. liu, April 28, 2020.
# Convert original NLDAS netcdf to the GMET output format.
# This is for ensemble bias correction.
  
RootDir=/glade/u/home/hongli/scratch/2020_04_21nldas_gmet #cheyenne
NldasDir=$RootDir/data/nldas_daily_utc
# sYear=1982 
# eYear=2014
sYear=1979 
eYear=2019

NewNldasDir=$RootDir/data/nldas_daily_utc_convert
if [ ! -d $NewNldasDir ]; then mkdir -p $NewNldasDir; fi

#====================NLDAS data pre-process (once for all)===========================
echo NLDAS data pre-process
for Y in $(seq $sYear $eYear); do
    echo $Y
    
    NldasOriginFile=$NldasDir/NLDAS_$Y.nc
    TmpFile=$NewNldasDir/NLDAS_tmp.nc
    NldasNewFile=$NewNldasDir/NLDAS_$Y.nc
    rm -f $TmpFile $NldasNewFile
    
    # add attribute: missing value
    ncatted -h -a _FillValue,prcp_avg,o,f,1.e+20 -a missing_value,prcp_avg,o,f,1.e+20 $NldasOriginFile
    ncatted -h -a _FillValue,tair_avg,o,f,1.e+20 -a missing_value,tair_avg,o,f,1.e+20 $NldasOriginFile
    ncatted -h -a _FillValue,tair_max,o,f,1.e+20 -a missing_value,tair_max,o,f,1.e+20 $NldasOriginFile
    ncatted -h -a _FillValue,tair_min,o,f,1.e+20 -a missing_value,tair_min,o,f,1.e+20 $NldasOriginFile

    # convert units (pcp: mm/hr -> mm/day, t: K -> degC)
    ncap2 -h -s "pcp=prcp_avg*24;t_min=tair_min-273.15;t_max=tair_max-273.15;t_mean=tair_avg-273.15;t_range=tair_max-tair_min" $NldasOriginFile $TmpFile

    # change NLDAS data's dimension names to be same as GMET output's
    if [ $Y -ne 2019 ]; then 
        ncrename -h -d lon_110,x -d lat_110,y -v lon_110,longitude -v lat_110,latitude $TmpFile
    elif [ $Y -eq 2019 ]; then 
        ncrename -h -d lon,x -d lat,y -v lon,longitude -v lat,latitude $TmpFile    
    fi
    
    # extract useful variable
    ncks -h -v pcp,t_mean,t_min,t_max,t_range,longitude,latitude,time $TmpFile $NldasNewFile
    rm -f $TmpFile
        
done



