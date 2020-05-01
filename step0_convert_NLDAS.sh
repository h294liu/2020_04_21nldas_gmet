#!/bin/bash
set -e

# H. liu, April 28, 2020.
# Bias correct NLDAS-based GMET ensemble in comparison with NLDAS data.
  
RootDir=/glade/u/home/hongli/work/2020_04_21nldas_gmet #cheyenne
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
    NldasNewFile=$NewNldasDir/NLDAS_$Y.nc
    rm -f $NldasNewFile

    # convert units (pcp: mm/hr -> mm/day, t: K -> degC)
    ncap2 -h -s "prcp_avg=prcp_avg*24;tair_avg=tair_avg-273.15" $NldasOriginFile $NldasNewFile

    # change NLDAS data's dimension & variable names to be same as GMET output's
    ncrename -d lon_110,y -d lat_110,x -v prcp_avg,pcp -v tair_avg,t_mean $NldasNewFile
done



