#!/usr/bin/env python
# coding: utf-8

# This script is used to compare ensemble outputs with NLDAS data
import numpy as np
import matplotlib as mpl
import matplotlib.pyplot as plt
import os
import pandas as pd
import xarray as xr
import datetime

def read_stn_regr(out_forc_name_base, start_yr, end_yr):
    for yr in range(start_yr, end_yr+1):        
        
        file = os.path.join(out_forc_name_base + str(yr)+'0101_' + str(yr)+'1231' + '.nc')
        f=xr.open_dataset(file)
        time = f['time'][:]        
        pcp_error = f.variables['pcp_error'][:]
        pcp_error_2 = f.variables['pcp_error_2'][:]
        tmean_error_2 = f.variables['tmean_error_2'][:]
        trange_error_2 = f.variables['trange_error_2'][:]
        
        if yr == start_yr:
            time_concat = time
            pcp_error_concat = pcp_error
            pcp_error_2_concat = pcp_error_2
            tmean_error_2_concat = tmean_error_2
            trange_error_2_concat = trange_error_2
        else:
            time_concat = np.concatenate((time_concat,time), axis=0) # (time)
            pcp_error_concat = np.concatenate((pcp_error_concat, pcp_error), axis=0) # (time,y,x)
            pcp_error_2_concat = np.concatenate((pcp_error_2_concat, pcp_error_2), axis=0) 
            tmean_error_2_concat = np.concatenate((tmean_error_2_concat, tmean_error_2), axis=0)
            trange_error_2_concat = np.concatenate((trange_error_2_concat, trange_error_2), axis=0)
            
    time_concat = pd.DatetimeIndex(time_concat)
        
    return time_concat, pcp_error_concat, pcp_error_2_concat, tmean_error_2_concat, trange_error_2_concat

def read_nldas_regr(out_forc_name_base, start_yr, end_yr):
    for yr in range(start_yr, end_yr+1):        
        
        file = os.path.join(out_forc_name_base + '.' + str(yr) + '.nc')
        f=xr.open_dataset(file)
        time = f['time'][:]
        pcp_error = f.variables['pcp_error'][:] #pcp_error_update
        pcp_error_2 = f.variables['pcp_error_2'][:] #pcp_error_2_update
        tmean_error_2 = f.variables['tmean_error_2'][:]
        trange_error_2 = f.variables['trange_error_2'][:]
        
        if yr == start_yr:
            time_concat = time
            pcp_error_concat = pcp_error
            pcp_error_2_concat = pcp_error_2
            tmean_error_2_concat = tmean_error_2
            trange_error_2_concat = trange_error_2
        else:
            time_concat = np.concatenate((time_concat,time), axis=0) # (time)
            pcp_error_concat = np.concatenate((pcp_error_concat, pcp_error), axis=0) # (time,y,x)
            pcp_error_2_concat = np.concatenate((pcp_error_2_concat, pcp_error_2), axis=0) 
            tmean_error_2_concat = np.concatenate((tmean_error_2_concat, tmean_error_2), axis=0)
            trange_error_2_concat = np.concatenate((trange_error_2_concat, trange_error_2), axis=0)
            
    time_concat = pd.DatetimeIndex(time_concat)
        
    return time_concat, pcp_error_concat, pcp_error_2_concat, tmean_error_2_concat, trange_error_2_concat

#======================================================================================================
# main script
root_dir = '/glade/u/home/hongli/scratch/2020_04_21nldas_gmet'   
nldas_dir = os.path.join(root_dir,'data/nldas_daily_utc_convert')
start_yr = 2013
end_yr = 2016

stn_grid_file = os.path.join(root_dir,'data/nldas_topo/conus_ens_grid_eighth.nc')
nldas_grid_file = os.path.join(root_dir,'data/nldas_topo/conus_ens_grid_eighth_deg_v1p1.nc')
stn_regr_dir = os.path.join(root_dir,'data/stn_regr')

result_dir = os.path.join(root_dir,'test_uniform_perturb')
test_folders = [d for d in os.listdir(result_dir)]
test_folders = sorted(test_folders)

scenarios_ids = range(0,9)  
intervals =  range(10,2,-1) 
scenario_num = len(scenarios_ids)

subforlder = 'gmet_regr'
file_basename = 'regress_ts'

time_format = '%Y-%m-%d'
plot_date_start = '2013-01-01'
plot_date_end = '2016-12-31'
plot_date_start_obj = datetime.datetime.strptime(plot_date_start, time_format)
plot_date_end_obj = datetime.datetime.strptime(plot_date_end, time_format)

dpi_value = 150
output_dir=os.path.join(root_dir, 'scripts/step24_plot_regr_error_box_wSTN')
if not os.path.exists(output_dir):
    os.makedirs(output_dir)
output_filename = 'step24_plot_regr_error_box_wSTN.png'
    
#======================================================================================================
print('Read gridinfo mask')
# get xy mask from gridinfo.nc
f_stn_grid = xr.open_dataset(stn_grid_file)
stn_mask_xy = f_stn_grid['mask'].values[:] # (y, x). 1 is valid. 0 is invalid.

f_nldas_grid = xr.open_dataset(nldas_grid_file)
nldas_mask_xy = f_nldas_grid['mask'].values[:] # (y, x). 1 is valid. 0 is invalid.

# commonly available area
mask_xy = (stn_mask_xy!=0) & (nldas_mask_xy!=0) 

#======================================================================================================
# read scenario regression results and save to dictionary
print('Read nldas regression uncertainty')

for k in range(scenario_num):
# for k in range(1):

    test_folder = test_folders[scenarios_ids[k]]
    
    print(test_folder)
    test_dir = os.path.join(result_dir, test_folder)
    fig_title= test_folder

    print(' -- read spatial uncertainty')
    # read regression uncertainty    
    output_namebase = os.path.join(test_dir,subforlder, file_basename)
    time_regr, pcp_error,  pcp_error_2, tmean_error_2, trange_error_2 = read_nldas_regr(output_namebase, start_yr, end_yr)
    
    # define plot mask for nldas ensemble
    mask_ens_t = (time_regr>=plot_date_start_obj) & (time_regr<=plot_date_end_obj)
    
    print(' -- calculate temporal mean')
    # caluclate time series mean(ny,nx)
    pcp_error_mean = np.nanmean(pcp_error[mask_ens_t,:,:],axis=0)     
    pcp_error_2_mean = np.nanmean(pcp_error_2[mask_ens_t,:,:],axis=0)     
    tmean_error_2_mean = np.nanmean(tmean_error_2[mask_ens_t,:,:],axis=0)
    trange_error_2_mean = np.nanmean(trange_error_2[mask_ens_t,:,:],axis=0)
    
    print(' -- extract unmasked values')
    # extract unmasked values
    pcp_error_mean=pcp_error_mean[mask_xy]    
    pcp_error_2_mean=pcp_error_2_mean[mask_xy]    
    tmean_error_2_mean=tmean_error_2_mean[mask_xy] 
    trange_error_2_mean=trange_error_2_mean[mask_xy] 
    
    # save to array
    if k == 0:
        grid_num = len(pcp_error_mean)
        pcp_error_mean_arr = np.zeros((grid_num,scenario_num+1)) #one more column for station regr
        pcp_error_2_mean_arr = np.zeros((grid_num,scenario_num+1))
        tmean_error_2_mean_arr = np.zeros((grid_num,scenario_num+1)) 
        trange_error_2_mean_arr = np.zeros((grid_num,scenario_num+1))
    
    pcp_error_mean_arr[:,k] = pcp_error_mean
    pcp_error_2_mean_arr[:,k] = pcp_error_2_mean
    tmean_error_2_mean_arr[:,k] = tmean_error_2_mean 
    trange_error_2_mean_arr[:,k] = trange_error_2_mean
    
    del pcp_error_mean, pcp_error_2_mean, tmean_error_2_mean, trange_error_2_mean
    del pcp_error, pcp_error_2, tmean_error_2, trange_error_2  

#======================================================================================================
# read station regression results
print('Read station regression uncertainty')
print(' -- read spatial errors')
output_namebase = os.path.join(stn_regr_dir, 'conus_regress_eighth_')
stn_time_regr, stn_pcp_error,  stn_pcp_error_2, stn_tmean_error_2, stn_trange_error_2 = read_stn_regr(output_namebase, start_yr, end_yr)

# define plot mask for stn regr
mask_stn_t = (stn_time_regr>=plot_date_start_obj) & (stn_time_regr<=plot_date_end_obj)

print(' -- calculate temporal mean')
# caluclate time series mean(ny,nx)
stn_pcp_error_mean = np.nanmean(stn_pcp_error[mask_stn_t,:,:],axis=0)     
stn_pcp_error_2_mean = np.nanmean(stn_pcp_error_2[mask_stn_t,:,:],axis=0)     
stn_tmean_error_2_mean = np.nanmean(stn_tmean_error_2[mask_stn_t,:,:],axis=0)
stn_trange_error_2_mean = np.nanmean(stn_trange_error_2[mask_stn_t,:,:],axis=0)

print(' -- extract unmasked values')
# extract unmasked values
stn_pcp_error_mean=stn_pcp_error_mean[mask_xy]    
stn_pcp_error_2_mean=stn_pcp_error_2_mean[mask_xy]    
stn_tmean_error_2_mean=stn_tmean_error_2_mean[mask_xy] 
stn_trange_error_2_mean=stn_trange_error_2_mean[mask_xy] 

pcp_error_mean_arr[:,-1] = stn_pcp_error_mean
pcp_error_2_mean_arr[:,-1] = stn_pcp_error_2_mean
tmean_error_2_mean_arr[:,-1] = stn_tmean_error_2_mean 
trange_error_2_mean_arr[:,-1] = stn_trange_error_2_mean

del stn_pcp_error_mean, stn_pcp_error_2_mean, stn_tmean_error_2_mean, stn_trange_error_2_mean
del stn_pcp_error, stn_pcp_error_2, stn_tmean_error_2, stn_trange_error_2  
 
#======================================================================================================    
# plot
print('Plot')
var_list = ["Precp'", "Precp_2'", 'Tmean_2', 'Trange_2']

nrow = len(var_list) # prcp, tmean, tmin, tmax, trange
ncol = 1 
fig, ax = plt.subplots(nrow, ncol, figsize=(6.5,5.5*1.2))#, constrained_layout=True)

for i in range(nrow):
        print(var_list[i])
        
        # select data for each subplot
        if i == 0:
            data=pcp_error_mean_arr
            top=2
        elif i == 1:
            data=pcp_error_2_mean_arr
            top=0.7
        elif i == 2:
            data=tmean_error_2_mean_arr
            top=18
        elif i == 3:
            data=trange_error_2_mean_arr
            top=15
            
        # save time-series mean uncertainty of all valid grids and all scenarios (once for all)
        np.savetxt(os.path.join(output_dir, output_filename_txt), data, delimiter=',',
                    fmt='%f',header='Col is sample scenario. Row is the time-series mean uncertainty of flatten valid grids. The last col is for stn_regr.')
        
        # boxplot
        # reference: https://matplotlib.org/3.1.1/gallery/statistics/boxplot_demo.html
        bp = ax[i].boxplot(data, sym='o')#, labels=labels)
        plt.setp(bp['boxes'], color='black')
        plt.setp(bp['whiskers'], color='black')
        plt.setp(bp['fliers'], color='red', marker='o',markersize=1.2)
        
        # Add a horizontal grid to the plot, but make it very light in color
        # so we can use it for reading data values but not be distracting
        ax[i].yaxis.grid(True, linestyle='-', which='major', color='lightgrey',alpha=0.5)
        ax[i].set_axisbelow(True)
        
        # y_lim
#         bottom=np.nanmin(data)-0.05*(np.nanmax(data)-np.nanmin(data))
#         top=np.nanmax(data)*1.05
#         ax[i].set_ylim(bottom=0, top=top)

        # Due to the Y-axis scale being different across samples, it can be
        # hard to compare differences in medians across the samples. Add upper
        # X-axis tick labels with the sample medians to aid in comparison
        # (just use two decimal places of precision)
        pos = np.arange(scenario_num+1) 
        medians = [(bp['medians'][k]).get_ydata()[0] for k in range(scenario_num+1)]
        upper_labels = [str(np.round(s, 2)) for s in medians]
        for tick, label in zip(range(scenario_num+1), ax[i].get_xticklabels()):
            k = tick % 2
            ax[i].text(pos[tick]+1.2, 0.9, upper_labels[tick],
                     transform=ax[i].get_xaxis_transform(),
                     horizontalalignment='center', size='xx-small',
                     fontstyle='italic', color='b') #pos[tick], 1.02

        # set y-axis label
        y_lable = 'Regression uncertainty'
        ax[i].set_ylabel(y_lable, fontsize='xx-small')
        if i == nrow-1:
            ax[i].set_xlabel('Sampling Scenario', fontsize='xx-small')
        
        x_ticks = [str(x) for x in range(1,10)]
        x_ticks.append('stn_regr')
        ax[i].set_xticklabels(x_ticks)
        ax[i].tick_params(axis='both', direction='out',labelsize = 'xx-small',
                          length=1.5, width=0.5, pad=1.5)       
        # title
        alpha = chr(ord('a') + i)
        ax[i].set_title('('+alpha+') '+var_list[i], pad=4, 
                        fontsize='xx-small', fontweight='semibold') #pad=9
        
# save plot
fig.tight_layout(pad=0.1, h_pad=0.5) #h_pad=0.7
fig.savefig(os.path.join(output_dir, output_filename), dpi=dpi_value, bbox_inches = 'tight', pad_inches = 0.05)
plt.close(fig)

print('Done')

