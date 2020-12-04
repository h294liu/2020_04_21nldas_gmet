#!/usr/bin/env python
# coding: utf-8

# This script is used to compare ensemble outputs with NLDAS data
import os
import matplotlib as mpl
from matplotlib.colors import ListedColormap, LinearSegmentedColormap
import matplotlib.pyplot as plt

import numpy as np
import pandas as pd
import xarray as xr
import datetime

def read_ens(out_forc_name_base, start_yr, end_yr):
    for yr in range(start_yr, end_yr+1):        
        
        file = os.path.join(out_forc_name_base + '.' + str(yr) + '.nc')
        f=xr.open_dataset(file)
        time = f['time'][:]
        pcp = f.variables['pcp'][:]
        pcp_2 = f.variables['pcp_2'][:]
        tmean_2 = f.variables['tmean_2'][:]
        trange_2 = f.variables['trange_2'][:]
        
        if yr == start_yr:
            time_concat = time
            pcp_concat = pcp
            pcp_2_concat = pcp_2
            tmean_2_concat = tmean_2
            trange_2_concat = trange_2
        else:
            time_concat = np.concatenate((time_concat,time), axis=0) # (time)
            pcp_concat = np.concatenate((pcp_concat, pcp), axis=0) # (time,y,x)
            pcp_2_concat = np.concatenate((pcp_2_concat, pcp_2), axis=0)
            tmean_2_concat = np.concatenate((tmean_2_concat, tmean_2), axis=0)
            trange_2_concat = np.concatenate((trange_2_concat, trange_2), axis=0)
            
    time_concat = pd.DatetimeIndex(time_concat)
        
    return time_concat, pcp_concat, pcp_2_concat, tmean_2_concat, trange_2_concat

#======================================================================================================
# main script
root_dir = '/glade/u/home/hongli/scratch/2020_04_21nldas_gmet'   
nldas_dir = os.path.join(root_dir,'data/nldas_daily_utc_convert')
start_yr = 2015
end_yr = 2016

gridinfo_file = os.path.join(root_dir,'data/nldas_topo/conus_ens_grid_eighth.nc')

result_dir = os.path.join(root_dir,'test_uniform_perturb')
test_folders = [d for d in os.listdir(result_dir)]
test_folders = sorted(test_folders)
scenarios_ids = range(0,9) #[0,1,5,8] 
intervals =  range(10,1,-1) #[10,9,5,2]
scenario_num = len(scenarios_ids)

subforlder = 'gmet_regr'
file_basename = 'regress_ts'
transfm_power = 1/4.0

ens_num = 100
time_format = '%Y-%m-%d'

dpi_value = 600
plot_date_start = '2013-01-01'
plot_date_end = '2016-12-31'
plot_date_start_obj = datetime.datetime.strptime(plot_date_start, time_format)
plot_date_end_obj = datetime.datetime.strptime(plot_date_end, time_format)

output_dir=os.path.join(root_dir, 'scripts/step23_plot_regr_nldas_scatter')
if not os.path.exists(output_dir):
    os.makedirs(output_dir)
output_filename_base = 'step23_plot_regr_nldas_scatter_'
    
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
        t_mean = f_nldas['t_mean'].values[:] # (time, y, x). unit: degC
        t_range = f_nldas['t_range'].values[:]
        time = f_nldas['time'].values[:]
    else:
        pcp = np.concatenate((pcp, f_nldas['pcp'].values[:]), axis = 0)
        t_mean = np.concatenate((t_mean, f_nldas['t_mean'].values[:]), axis = 0)
        t_range = np.concatenate((t_range, f_nldas['t_range'].values[:]), axis = 0)
        time = np.concatenate((time, f_nldas['time'].values[:]), axis = 0)

# get time mask from nldas data
time_obj = pd.to_datetime(time)
mask_t  = (time_obj >= plot_date_start_obj) & (time_obj <= plot_date_end_obj) 
time = time_obj[mask_t]

# time series mean
pcp_transfm = np.power(pcp[mask_t,:,:],transfm_power) #power-law transform P  
prcp_mean = np.nanmean(pcp_transfm, axis=0) #(y, x))
tmean_mean = np.nanmean(t_mean[mask_t,:,:], axis=0) 
trange_mean = np.nanmean(t_range[mask_t,:,:], axis=0)

# convert masked values to nan
prcp_mean=np.where(mask_xy==0,np.nan,prcp_mean)
tmean_mean=np.where(mask_xy==0,np.nan,tmean_mean)
trange_mean=np.where(mask_xy==0,np.nan,trange_mean)

del pcp,t_mean,t_range

#======================================================================================================
# read scenario ensemble results and save to dictionary
print('Read regression result')
pcp_regr_dict = {} # empty dictionary. will have 9 integer keys for 9 scenarios
pcp_2_regr_dict = {} 
tmean_2_regr_dict = {} 
trange_2_regr_dict = {} 

for k in range(scenario_num):

    test_folder = test_folders[scenarios_ids[k]]
    
    print(test_folder)
    test_dir = os.path.join(result_dir, test_folder)
    fig_title= test_folder

    print(' -- read spatial ensemble mean')
    # read ensemble mean    
    output_namebase = os.path.join(test_dir,subforlder,file_basename)
    time_regr, pcp_regr, pcp_2_regr, tmean_2_regr, trange_2_regr = read_ens(output_namebase, start_yr, end_yr)

    # define plot mask for nldas ensemble
    mask_ens_t = (time_regr>=plot_date_start_obj) & (time_regr<=plot_date_end_obj)
    
    print(' -- calculate temporal mean')
    # caluclate time series mean(ny,nx)
    pcp_regr = np.nanmean(pcp_regr[mask_ens_t,:,:],axis=0)     
    pcp_2_regr = np.nanmean(pcp_2_regr[mask_ens_t,:,:],axis=0)     
    tmean_2_regr = np.nanmean(tmean_2_regr[mask_ens_t,:,:],axis=0)
    trange_2_regr = np.nanmean(trange_2_regr[mask_ens_t,:,:],axis=0)
    
    # convert masked values to nan
    pcp_regr=np.where(mask_xy==0,np.nan,pcp_regr)    
    pcp_2_regr=np.where(mask_xy==0,np.nan,pcp_2_regr)    
    tmean_2_regr=np.where(mask_xy==0,np.nan,tmean_2_regr)    
    trange_2_regr=np.where(mask_xy==0,np.nan,trange_2_regr)
    
    # save Ensemble - NLDAS to dictionaries
    pcp_regr_dict[k] = pcp_regr # empty dictionary. will have 3 integer keys for 3 scenarios
    pcp_2_regr_dict[k] = pcp_2_regr 
    tmean_2_regr_dict[k] = tmean_2_regr 
    trange_2_regr_dict[k] = trange_2_regr    

    del time_regr, pcp_regr, pcp_2_regr, tmean_2_regr, trange_2_regr 

#======================================================================================================    
# create a white-blue linear colormap
print('create colormap')

# reference: https://stackoverflow.com/questions/25408393/getting-individual-colors-from-a-color-map-in-matplotlib
cmap = mpl.cm.get_cmap('jet') # get the blue color of jet 
c0 = cmap(0.0)
top = mpl.colors.LinearSegmentedColormap.from_list("", ["white",c0])

# combine two liner colormaps to create a
# reference: https://matplotlib.org/3.1.0/tutorials/colors/colormap-manipulation.html
bottom = mpl.cm.get_cmap('jet')
newcolors = np.vstack((top(np.linspace(0, 1, int(256*0.1))),bottom(np.linspace(0, 1, int(256*0.9)))))
newcmp = mpl.colors.LinearSegmentedColormap.from_list("WhiteJet", newcolors)

#======================================================================================================    
# plot
print('Plot')
var_list = ["Precp'", "Precp_2'", 'Tmean_2', 'Trange_2']
# var_units = ['(mm/d)','(mm/d)','($^\circ$C)','($^\circ$C)']
# var_list = ["Precp'"]
for m in range(len(var_list)): # loop all variables
    var = var_list[m]
    output_filename = output_filename_base+var+'.png'
    print(var)
    
    # data selection
    if m == 0:
        mean = prcp_mean
        ensmean_dict = pcp_regr_dict
    elif m == 1:
        mean = prcp_mean
        ensmean_dict = pcp_2_regr_dict
    elif m == 2:
        mean = tmean_mean
        ensmean_dict = tmean_2_regr_dict
    elif m == 3:
        mean = trange_mean
        ensmean_dict = trange_2_regr_dict
    
    # xy aixs range
    vmin_regr=np.nanmin([np.nanmin(ensmean_dict[k]) for k in range(scenario_num)])
    vmax_regr=np.nanmax([np.nanmax(ensmean_dict[k]) for k in range(scenario_num)])

#     vmin = np.nanmin([vmin_regr,np.nanmin(mean)])
#     vmax = np.nanmax([vmax_regr,np.nanmax(mean)])
    vmin = np.nanmin(mean)
    vmax = np.nanmax(mean)
    
    # MAE
    mae=[np.nanmean(np.absolute(ensmean_dict[k]-mean)) for k in range(scenario_num)]    
    
    # plot each varaiable seperately
    nrow = 3 # totally 9 sampling scenarios
    ncol = 3
            
    fig, ax = plt.subplots(nrow, ncol, figsize=(4.5,4.5*1.0))

    for i in range(nrow):
        for j in range(ncol):
            k = i*ncol+j
            
#             print('sample scenario '+str(k+1))

            # 2D histograms
            # https://python-graph-gallery.com/83-basic-2d-histograms-with-matplotlib/
            x = mean[mask_xy!=0]
            y = ensmean_dict[k]
            y = y[mask_xy!=0]
            hist = ax[i,j].hist2d(x, y, bins=(200, 200),cmap=newcmp, 
                                  range=[[vmin, vmax], [vmin, vmax]]) # return (counts, xedges, yedges, Image)
    
            # diagonal
            ax[i,j].plot([vmin, vmax],[vmin, vmax],color='grey',linewidth=0.5, alpha=0.6)
            
            # MAE text
            ax[i,j].annotate((r'$\overline{MAE}$=%.2f') %(mae[k]), xy=(0.05, 0.87), 
                             xycoords='axes fraction',fontsize='xx-small',fontstyle='italic')

            # limit
            ax[i,j].set_xlim(vmin, vmax)
            ax[i,j].set_ylim(vmin, vmax)

            # label
            if i == nrow-1:
                xlabel = 'NLDAS '+var_list[m]#+' '+var_units[m]
                ax[i,j].set_xlabel(xlabel, fontsize='xx-small')
            if j == 0:
                ylabel = 'Estimated '+var_list[m]#+' '+var_units[m]
                ax[i,j].set_ylabel(ylabel, fontsize='xx-small')
             
            # tick
            ax[i,j].tick_params(axis='both', direction='out',labelsize = 'xx-small', 
                                length=2, width=0.5, pad=1.2)
            if j == 0:
                ax[i,j].tick_params(axis='both',labelleft = True)
            else:
                ax[i,j].tick_params(axis='both',labelleft = False)
            if i == nrow-1:
                ax[i,j].tick_params(axis='both',labelbottom = True)
            else:
                ax[i,j].tick_params(axis='both',labelbottom = False)
                
            # title
            title_str = 'Scenario '+str(k+1) +' (interval = '+str(intervals[k])+')'
            ax[i,j].set_title(title_str, fontsize='xx-small', fontweight='semibold')

           # change subplot border width
            for axis in ['top','bottom','left','right']:
                ax[i,j].spines[axis].set_linewidth(0.5)
    
    # colorbar    
    fig.subplots_adjust(bottom=0.15, top=1, left = 0, right=1, wspace = 0.07, hspace = 0.25)
    cax = fig.add_axes([0.25, 0.05, 0.5, 0.02]) #[left, bottom, width, height]
    cbar = fig.colorbar(hist[3], cax=cax, orientation='horizontal')

    tick1 = hist[0].max()*0.5
    tick2 = hist[0].max()
    cbar.set_ticks([0, tick1, tick2]) 
    cbar.set_ticklabels(['Low', 'Medium', 'High'])  
    cbar.ax.tick_params(labelsize='xx-small', length=2, width=1)

    # set the colorbar ticks and tick labels
    cbar.set_label(label='Number of grids per pixel',size='xx-small')    

    # save plot
    fig.savefig(os.path.join(output_dir, output_filename), dpi=dpi_value, 
                bbox_inches = 'tight', pad_inches = 0.05)
    plt.close(fig)

print('Done')

