#!/usr/bin/env python
# coding: utf-8

# This script is used to compare ensemble outputs with NLDAS data
import numpy as np
import os,scipy
import pandas as pd
import xarray as xr
import datetime
from scipy.stats import gamma
import multiprocessing as mp

def ppf(p,a,b):
    
    q = gamma.ppf(p, a, loc=0, scale=b)
    return q

def read_ens(out_forc_name_base, metric, start_yr, end_yr):
    for yr in range(start_yr, end_yr+1):        
        
        file = os.path.join(out_forc_name_base + '.' + str(yr) + '.'+metric+'.nc')
        f=xr.open_dataset(file)
        time = f['time'][:]
        pcp = f.variables['pcp'][:]
        tmean = f.variables['t_mean'][:]
        tmin = f.variables['t_min'][:]
        tmax = f.variables['t_max'][:]
        trange = f.variables['t_range'][:]
        
        if yr == start_yr:
            time_concat = time
            pcp_concat = pcp
            tmean_concat = tmean
            tmin_concat = tmin
            tmax_concat = tmax
            trange_concat = trange
        else:
            time_concat = np.concatenate((time_concat,time), axis=0) # (time)
            pcp_concat = np.concatenate((pcp_concat, pcp), axis=0) # (time,y,x)
            tmean_concat = np.concatenate((tmean_concat, tmean), axis=0)
            tmin_concat = np.concatenate((tmin_concat, tmin), axis=0)
            tmax_concat = np.concatenate((tmax_concat, tmax), axis=0)
            trange_concat = np.concatenate((trange_concat, trange), axis=0)
            
    time_concat = pd.DatetimeIndex(time_concat)
        
    return time_concat, pcp_concat, tmean_concat, tmin_concat, tmax_concat, trange_concat

#======================================================================================================
# main script
root_dir = '/glade/u/home/hongli/scratch/2020_04_21nldas_gmet'   
nldas_dir = os.path.join(root_dir,'data/nldas_daily_utc_convert')
start_yr = 2015
end_yr = 2016

gridinfo_file = os.path.join(root_dir,'data/nldas_topo/conus_ens_grid_eighth.nc')

time_format = '%Y-%m-%d'
plot_date_start = '2015-01-01'
plot_date_end = '2016-12-31'
plot_date_start_obj = datetime.datetime.strptime(plot_date_start, time_format)
plot_date_end_obj = datetime.datetime.strptime(plot_date_end, time_format)

output_dir=os.path.join(root_dir, 'scripts/step21_nldas_gamma_IQR_DOY_pcp')
if not os.path.exists(output_dir):
    os.makedirs(output_dir)
output_file1 = 'ppf25_pcp.txt'
output_file2 = 'ppf75_pcp.txt'
output_file3 = 'IQR_pcp.txt'
   
#======================================================================================================
print('Read gridinfo mask')
# get xy mask from gridinfo.nc
f_gridinfo = xr.open_dataset(gridinfo_file)
mask_xy = f_gridinfo['mask'].values[:] # (y, x). 1 is valid. 0 is invalid.
#data_mask = f_gridinfo['data_mask'].values[:] # (y, x). 1 is valid. 0 is invalid.

#======================================================================================================
# read historical nldas data
print('Read nldas data')
for yr in range(start_yr, end_yr+1):
    
    nldas_file = 'NLDAS_'+str(yr)+'.nc'
    nldas_path = os.path.join(nldas_dir, nldas_file)
    
    f_nldas = xr.open_dataset(nldas_path)
    if yr == start_yr:
        pcp = f_nldas['pcp'].values[:] # (time, y, x). unit: mm/day
        time = f_nldas['time'].values[:]
    else:
        pcp = np.concatenate((pcp, f_nldas['pcp'].values[:]), axis = 0)
        time = np.concatenate((time, f_nldas['time'].values[:]), axis = 0)

# get time mask from nldas data
time_obj = pd.to_datetime(time)
mask_t  = (time_obj >= plot_date_start_obj) & (time_obj <= plot_date_end_obj) 
time = time_obj[mask_t]

nt_nldas = len(time)
mask_xy_3d_nldas = np.repeat(mask_xy[np.newaxis,:,:],nt_nldas,axis=0)

pcp = pcp[mask_xy_3d_nldas!=0]    
pcp = pcp.reshape((nt_nldas,-1))

# calculate DOY (day of year) mean IQR    
df_nlds = pd.DataFrame(pcp)    
time_month = [t.month for t in time]
time_day = [t.day for t in time]
df_nlds['month']=time_month
df_nlds['date']=time_day  
df_nlds2 = df_nlds.groupby(['month','date']).mean()

del pcp

##======================================================================================================    
# calculate Gamma distribution IQR
df_nldas3 = df_nlds2[df_nlds2!=0]
nldas_arr = df_nldas3.to_numpy()
mu = nldas_arr 
std = nldas_arr*0.25

alpha = np.power(mu,2)/np.power(std,2)
beta = np.power(std,2)/mu

(ny,nx) = np.shape(nldas_arr)
q25 = np.zeros((ny,nx))
q75 = np.zeros((ny,nx))

# Step 1: Init multiprocessing.Pool()
pool = mp.Pool(mp.cpu_count())

# Step 2: `pool.apply` the `howmany_within_range()`

for i in range(ny):
    print('row ',i)
    q25[i,:] = [pool.apply(ppf, args=(0.25, alpha[i,j], beta[i,j])) for j in range(nx)]
    q75[i,:] = [pool.apply(ppf, args=(0.75, alpha[i,j], beta[i,j])) for j in range(nx)]

# Step 3: Don't forget to close
pool.close()    

# post-process
q25_update = np.where(np.isnan(q25),-999,q25)
q75_update = np.where(np.isnan(q75),-999,q75)
iqr = q75-q25
iqr_update = np.where(np.isnan(iqr),-999,iqr)

# save
np.savetxt(os.path.join(output_dir,output_file1),q25_update,delimiter=',',fmt='%f',header='# Row:DOY. Col:grids.')
np.savetxt(os.path.join(output_dir,output_file2),q75_update,delimiter=',',fmt='%f',header='# Row:DOY. Col:grids.')
np.savetxt(os.path.join(output_dir,output_file3),iqr_update,delimiter=',',fmt='%f',header='# Row:DOY. Col:grids.')

print('Done')

