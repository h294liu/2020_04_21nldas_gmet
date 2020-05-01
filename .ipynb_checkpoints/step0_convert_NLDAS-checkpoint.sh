#!/bin/bash
set -e

# H. liu, April 28, 2020.
# Bias correct NLDAS-based GMET ensemble in comparison with NLDAS data.
  
RootDir=/glade/u/home/hongli/scratch/2020_04_21nldas_gmet #cheyenne
NldasDir=$RootDir/data/nldas_daily_utc
sYear=1980 
eYear=2016

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

    # convert units (pcp: mm/hr -> mm/day, t: K -> degC)
    ncap2 -h -s "pcp=prcp_avg*24;t_mean=tair_avg-273.15;t_range=tair_max-tair_min" $NldasOriginFile $TmpFile

    # change NLDAS data's dimension names to be same as GMET output's
    ncrename -h -d lon_110,y -d lat_110,x -v lon_110,longitude -v lat_110,latitude $TmpFile
    
    # extract useful variable
    ncks -h -v pcp,t_mean,t_range,longitude,latitude,time $TmpFile $NldasNewFile
    rm -f $TmpFile
    
done



