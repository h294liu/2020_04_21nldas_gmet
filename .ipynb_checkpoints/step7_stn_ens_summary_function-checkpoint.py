#!/usr/bin/env python
# coding: utf-8

# This script is used to calculate some summary statistics of yearly ensemble.

import numpy as np
import argparse, os
import xarray as xr
import datetime
import netCDF4 as nc

startTime = datetime.datetime.now()

def process_command_line():
    '''Parse the commandline'''
    parser = argparse.ArgumentParser(description='Script to subset a netcdf file based on a list of IDs.')
    parser.add_argument('EnsDirBase', help='parent path of ens data.')
    parser.add_argument('EnsFolder',help='ens folder name.')
    parser.add_argument('yr',help='year.')
    parser.add_argument('startEns',help='start ensemble member id.')
    parser.add_argument('stopEns',help='end ensemble member id.')
    parser.add_argument('lb_perct',help='percentile value for lower bound.')
    parser.add_argument('ub_perct',help='percentile value for upper bound.')
    args = parser.parse_args()
    return(args)

#======================================================================================================
# main script
# process command line
args = process_command_line()
EnsDirBase = args.EnsDirBase
EnsFolder = args.EnsFolder

yr=int(args.yr)
startEns=int(args.startEns)   
stopEns=int(args.stopEns)  
ens_num = (stopEns-startEns+1)

lb_perct=int(args.lb_perct)
ub_perct=int(args.ub_perct)
lb_perct_str = str(lb_perct)
ub_perct_str = str(ub_perct)

EnsDir = os.path.join(EnsDirBase, EnsFolder)
outdir = os.path.join(EnsDirBase, EnsFolder+'_summary')
if not os.path.exists(outdir):
    os.makedirs(outdir)

#=================================================================================
# read ensemble data
print('read ensemble data')
for i in range(ens_num):
    NUM = startEns+i
    ens_file = os.path.join(EnsDir, 'conus_daily_eighth_'+ str(yr) + '0101_' + str(yr) + '1231_'+ str('%03d' % (NUM)) +'.nc4')

    f=xr.open_dataset(ens_file)
    time = f['time'][:]
    pcp = f.variables['pcp'][:]
    tmean = f.variables['t_mean'][:]
    tmin = f.variables['t_min'][:]
    tmax = f.variables['t_max'][:]
    trange = f.variables['t_range'][:]

    if NUM == startEns: # create ens array for one member
        (nt,ny,nx) = np.shape(pcp)
        pcp_ens = np.zeros((nt,ny,nx,ens_num))
        tmean_ens = np.zeros((nt,ny,nx,ens_num))
        tmin_ens = np.zeros((nt,ny,nx,ens_num))
        tmax_ens = np.zeros((nt,ny,nx,ens_num))
        trange_ens = np.zeros((nt,ny,nx,ens_num))

    pcp_ens[:,:,:,i] = pcp
    tmean_ens[:,:,:,i] = tmean
    tmin_ens[:,:,:,i] = tmin
    tmax_ens[:,:,:,i] = tmax
    trange_ens[:,:,:,i] = trange

#=================================================================================
# calculate ensemble statistics. (time,y,x)
print('calculate ensemble statistics')
print('pcp')
pcp_ens_mean = np.nanmean(pcp_ens, axis = 3)
pcp_ens_median = np.nanmedian(pcp_ens, axis = 3)
pcp_ens_std = np.std(pcp_ens, axis = 3)
pcp_ens_lb = np.percentile(pcp_ens, lb_perct, axis = 3)
pcp_ens_ub = np.percentile(pcp_ens, ub_perct, axis = 3)

pcp_ens_median_4d = np.repeat(pcp_ens_median[:,:,:,np.newaxis], ens_num, axis = 3)
y = np.absolute(pcp_ens - pcp_ens_median_4d)
pcp_ens_mad = np.nanmedian(y, axis = 3)
del pcp_ens,pcp_ens_median_4d,y

print('tmean')
tmean_ens_mean = np.nanmean(tmean_ens, axis = 3)
tmean_ens_median = np.nanmedian(tmean_ens, axis = 3)
tmean_ens_std = np.std(tmean_ens, axis = 3)
tmean_ens_lb = np.percentile(tmean_ens, lb_perct, axis = 3)
tmean_ens_ub = np.percentile(tmean_ens, ub_perct, axis = 3)

tmean_ens_median_4d = np.repeat(tmean_ens_median[:,:,:,np.newaxis], ens_num, axis = 3)
y = np.absolute(tmean_ens - tmean_ens_median_4d)
tmean_ens_mad = np.nanmedian(y, axis = 3)
del tmean_ens,tmean_ens_median_4d,y

print('tmin')
tmin_ens_mean = np.nanmean(tmin_ens, axis = 3)
tmin_ens_median = np.nanmedian(tmin_ens, axis = 3)
tmin_ens_std = np.std(tmin_ens, axis = 3)
tmin_ens_lb = np.percentile(tmin_ens, lb_perct, axis = 3)
tmin_ens_ub = np.percentile(tmin_ens, ub_perct, axis = 3)

tmin_ens_median_4d = np.repeat(tmin_ens_median[:,:,:,np.newaxis], ens_num, axis = 3)
y = np.absolute(tmin_ens - tmin_ens_median_4d)
tmin_ens_mad = np.nanmedian(y, axis = 3)
del tmin_ens,tmin_ens_median_4d,y

print('tmax')
tmax_ens_mean = np.nanmean(tmax_ens, axis = 3)
tmax_ens_median = np.nanmedian(tmax_ens, axis = 3)
tmax_ens_std = np.std(tmax_ens, axis = 3)
tmax_ens_lb = np.percentile(tmax_ens, lb_perct, axis = 3)
tmax_ens_ub = np.percentile(tmax_ens, ub_perct, axis = 3)

tmax_ens_median_4d = np.repeat(tmax_ens_median[:,:,:,np.newaxis], ens_num, axis = 3)
y = np.absolute(tmax_ens - tmax_ens_median_4d)
tmax_ens_mad = np.nanmedian(y, axis = 3)
del tmax_ens,tmax_ens_median_4d,y

print('trange')
trange_ens_mean = np.nanmean(trange_ens, axis = 3)
trange_ens_median = np.nanmedian(trange_ens, axis = 3)
trange_ens_std = np.std(trange_ens, axis = 3)
trange_ens_lb = np.percentile(trange_ens, lb_perct, axis = 3)
trange_ens_ub = np.percentile(trange_ens, ub_perct, axis = 3)

trange_ens_median_4d = np.repeat(trange_ens_median[:,:,:,np.newaxis], ens_num, axis = 3)
y = np.absolute(trange_ens - trange_ens_median_4d)
trange_ens_mad = np.nanmedian(y, axis = 3)
del trange_ens,trange_ens_median_4d,y

#=================================================================================
#save statistics summary
print('save statistics')
SrcFile=os.path.join(EnsDir, 'conus_daily_eighth_'+ str(yr) + '0101_' + str(yr) + '1231_001.nc4')
with nc.Dataset(SrcFile) as src:   
    DstFile = os.path.join(outdir, 'ens_forc.sumamry.'+ str(yr)+'.nc')
    with nc.Dataset(DstFile, "w") as dst:

        # copy dimensions
        for name, dimension in src.dimensions.items():
             dst.createDimension(
                name, (len(dimension) if not dimension.isunlimited() else None))

        # copy variable attributes all at once via dictionary (for the included variables)
        include = ['latitude', 'longitude', 'time']
        for name, variable in src.variables.items():
            if name in include:
                x = dst.createVariable(name, variable.datatype, variable.dimensions)               
                dst[name].setncatts(src[name].__dict__)
                dst[name][:]=src[name][:]                

        # create summary variables 
        vars_short = ['pcp_mean','pcp_median','pcp_std',
                      'pcp_lb','pcp_ub','pcp_mad',
                      'tmean_mean','tmean_median','tmean_std',
                      'tmean_lb','tmean_ub','tmean_mad',
                      'tmin_mean','tmin_median','tmin_std',
                      'tmin_lb','tmin_ub','tmin_mad',
                      'tmax_mean','tmax_median','tmax_std',
                      'tmax_lb','tmax_ub','tmax_mad',
                      'trange_mean','trange_median','trange_std',
                      'trange_lb','trange_ub','trange_mad']
        vars_long = ['Mean of daily precipitation','Median of daily precipitation',
                     'Standard deviation of daily precipitation',
                     lb_perct_str+'th percentile of daily precipitation',
                     ub_perct_str+'th percentile of daily precipitation',
                     'Median absolute deviation of daily precipitation',
                     'Mean of daily mean temperature', 'Median of daily mean temperature',
                     'Standard deviation of daily mean temperature',
                     lb_perct_str+'th percentile of daily mean temperature',
                     ub_perct_str+'th percentile of daily mean temperature',
                     'Median absolute deviation of daily mean temperature',
                     'Mean of daily min temperature', 'Median of daily min temperature',
                     'Standard deviation of daily min temperature',
                     lb_perct_str+'th percentile of daily min temperature',
                     ub_perct_str+'th percentile of daily min temperature',
                     'Median absolute deviation of daily min temperature',
                     'Mean of daily max temperature', 'Median of daily max temperature',
                     'Standard deviation of daily max temperature',
                     lb_perct_str+'th percentile of daily max temperature',
                     ub_perct_str+'th percentile of daily max temperature',
                     'Median absolute deviation of daily max temperature',
                     'Mean of daily temperature range', 'Median of daily temperature range',
                     'Standard deviation of daily temperature range',
                     lb_perct_str+'th percentile of daily temperature range',
                     ub_perct_str+'th percentile of daily temperature range',
                     'Median absolute deviation of daily temperature range']
        units = ['mm/day', 'mm/day', 'mm/day', 'mm/day','mm/day','mm/day',
                 'degC', 'degC', 'degC', 'degC', 'degC', 'degC',
                 'degC', 'degC', 'degC', 'degC', 'degC', 'degC',
                 'degC', 'degC', 'degC', 'degC', 'degC', 'degC',
                 'degC', 'degC', 'degC', 'degC','degC', 'degC']

        for i, var in enumerate(vars_short):
            var_i = dst.createVariable(var,np.float64,('time','lat','lon')) # note: unlimited dimension is leftmost
            var_i.long_name = vars_long[i]
            var_i.units = units[i] 

        dst.variables['pcp_mean'][:] = pcp_ens_mean
        dst.variables['pcp_median'][:] = pcp_ens_median
        dst.variables['pcp_std'][:] = pcp_ens_std 
        dst.variables['pcp_lb'][:] = pcp_ens_lb
        dst.variables['pcp_ub'][:] = pcp_ens_ub 
        dst.variables['pcp_mad'][:] = pcp_ens_mad 

        dst.variables['tmean_mean'][:] = tmean_ens_mean
        dst.variables['tmean_median'][:] = tmean_ens_median
        dst.variables['tmean_std'][:] = tmean_ens_std 
        dst.variables['tmean_lb'][:] = tmean_ens_lb
        dst.variables['tmean_ub'][:] = tmean_ens_ub 
        dst.variables['tmean_mad'][:] = tmean_ens_mad 

        dst.variables['tmin_mean'][:] = tmin_ens_mean
        dst.variables['tmin_median'][:] = tmin_ens_median
        dst.variables['tmin_std'][:] = tmin_ens_std 
        dst.variables['tmin_lb'][:] = tmin_ens_lb
        dst.variables['tmin_ub'][:] = tmin_ens_ub 
        dst.variables['tmin_mad'][:] = tmin_ens_mad 

        dst.variables['tmax_mean'][:] = tmax_ens_mean
        dst.variables['tmax_median'][:] = tmax_ens_median
        dst.variables['tmax_std'][:] = tmax_ens_std 
        dst.variables['tmax_lb'][:] = tmax_ens_lb
        dst.variables['tmax_ub'][:] = tmax_ens_ub 
        dst.variables['tmax_mad'][:] = tmax_ens_mad 

        dst.variables['trange_mean'][:] = trange_ens_mean
        dst.variables['trange_median'][:] = trange_ens_median
        dst.variables['trange_std'][:] = trange_ens_std 
        dst.variables['trange_lb'][:] = trange_ens_lb
        dst.variables['trange_ub'][:] = trange_ens_ub 
        dst.variables['trange_mad'][:] = trange_ens_mad 
            
        dst.fillna(-999)
        
print('Done')
print(datetime.datetime.now()-startTime)
