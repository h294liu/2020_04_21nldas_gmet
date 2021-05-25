#!/usr/bin/env python
# coding: utf-8

# This code is used to sample grids from a given grid netcdf. 
# The given grid netcdf has the complete distribution of all the grids.
# Author: Hongli Liu

import os
import numpy as np
import xarray as xr
import argparse

def process_command_line():
    '''Parse the commandline'''
    parser = argparse.ArgumentParser(description='Script to sample grids from a given grid network.')
    parser.add_argument('grid_info_file', help='path of the given grid netcdf file.')
    parser.add_argument('output_path', help='output path to store sample results.')
    args = parser.parse_args()
    return(args)

# ===============================================================================
# main
if __name__ == '__main__':

    # --- process command line --- 
    args = process_command_line()    
    grid_info_file = args.grid_info_file
    output_path = args.output_path

    if not os.path.exists(output_path):
        os.makedirs(output_path)
    ofile_name_base = 'stnlist'
    np.random.seed(seed=123456)

    # ============================================================================
    # 1. read the given grid info (netcdf)
    # Note: users need to change the coordinate and attribute filed names based on their grid_info_file.
    print('read given grid netcdf.')
    f = xr.open_dataset(grid_info_file)
    mask = f['mask'].values[:]                 # 1 is valid. 0 is invalid. 
    latitude = f['latitude'].values[:]         # latitude field name
    longitude = f['longitude'].values[:]       # longitude field name
    elev = f['elev'].values[:]                 # elevation field name
    gradient_n_s = f['gradient_n_s'].values[:] # north-south slope field name
    gradient_w_e = f['gradient_w_e'].values[:] # west-east slope field name

    (ny,nx)=np.shape(mask)                     # entire grid network size
    (y_ids,x_ids)=np.where(mask==1)            # valid grid locations
    total_stn_num = len(y_ids)                 # total number of valid grids

    # =============================================================================
    # 2. sample grids basde on grid intervals
    index_intervals=[2,3,4,5,6,7,8,9,10]  

    sample_num_previous = 0
    for index_interval in index_intervals:    

        # 2.1 uniform sample
        sample_indexes = np.where((y_ids%index_interval==0) & (x_ids%index_interval==0))[0]
        sample_num = len(sample_indexes)
        rnds=np.random.randint(low=0, high=8+1, size=np.shape(sample_indexes))
        record = []

        # 2.2 perturb in eight directions
        if sample_num!=sample_num_previous:
            print('index interval = '+str(index_interval)+', choice num = '+str(sample_num))

            for i in range(sample_num):
                choice_index = sample_indexes[i]
                rnd = rnds[i]
                y_id_origin = y_ids[choice_index]
                x_id_origin = x_ids[choice_index]

                if rnd in [1,2,8]:
                    y_id=y_id_origin+1    
                elif rnd in [4,5,6]:
                    y_id=y_id_origin-1
                else:
                    y_id=y_id_origin
                if y_id<0 or y_id>ny or mask[y_id,x_id_origin]!=1:
                    y_id=y_id_origin

                if rnd in [2,3,4]:
                    x_id=x_id_origin+1
                elif rnd in [6,7,8]:
                    x_id=x_id_origin-1  
                else:
                    x_id=x_id_origin
                if x_id<0 or x_id>nx or mask[y_id,x_id]!=1:
                    x_id=x_id_origin

                if [y_id,x_id] not in record:
                    record.append([y_id,x_id])

        # 2.3 record the perturbed samples
        sample_num = len(record)        
        ofile = ofile_name_base +'_'+str('%05d' %(sample_num))+'grids'+ '_interval'+str(index_interval)+'.txt'
        f_out = open(os.path.join(output_path, ofile), 'w')
        
        f_out.write('NSITES\t'+str(sample_num)+'\n') # total number line
        f_out.write('STA_ID LAT LON ELEV SLP_N SLP_E STA_NAME\n') # title line

        for i in range(sample_num):
            y_id = record[i][0]
            x_id = record[i][1]
            sta_id = 'Row'+str('%03d' %(y_id))+'Col'+str('%03d' %(x_id))

            lat_i=latitude[y_id,x_id]
            lon_i=longitude[y_id,x_id]

            ele_i=elev[y_id,x_id]
            gradient_n_s_i=gradient_n_s[y_id,x_id]
            gradient_w_e_i=gradient_w_e[y_id,x_id]

            stn_name = '"'+sta_id+'"'
            f_out.write('%s, %f, %f, %f, %f, %f, %s\n' \
                        % (sta_id, lat_i, lon_i, ele_i, gradient_n_s_i, gradient_w_e_i, stn_name)) 

        f_out.close()
        sample_num_previous=sample_num        
