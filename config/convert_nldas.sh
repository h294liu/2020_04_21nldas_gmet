#!/bin/bash
set -e

# H. liu, Mar 6, 2021.
# regression result variable over the years 1979-2019(regression mean, error)

#==========================input (need update)=========================== 
Y=YEAR
NldasOriginFile=ORIGINFILE
TmpFile=TMPFILE
NldasNewFile=NEWFILE

#====================NLDAS data pre-process (no need update)===========================
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
        




