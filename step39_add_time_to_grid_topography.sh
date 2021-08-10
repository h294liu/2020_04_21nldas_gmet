#!/bin/bash

ncap2 -h -O -s 'defdim("time",1);time[time]=283996800.0;time@units="seconds since 1970-01-01 00:00:00.0 0:00"' grid_topography.nc grid_topography.nc
ncwa -h -O -a time grid_topography.nc grid_topography.nc
ncecat -h -O -u time grid_topography.nc grid_topography.nc
ncap2 -O -h -s 'time=time;latitude=latitude;longitude=longitude' grid_topography.nc grid_topography.nc

#Reference: 
#1. https://sourceforge.net/p/nco/discussion/9830/thread/cee4e1ad/
#2. https://sourceforge.net/p/nco/discussion/9830/thread/0851525d/
