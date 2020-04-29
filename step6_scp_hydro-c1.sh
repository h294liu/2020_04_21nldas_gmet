#!/bin/bash
set -e

src_dir=/home/hongli/work/2020_04_21nldas_gmet
dst_dir=/glade/u/home/hongli/work/2020_04_21nldas_gmet
result_folder=test_uniform
# result_subfolders=(00822grids 00986grids 01633grids 03225grids \
# 09000grids 00822grids_test 01240grids 02282grids 05016grids 20162grids)

result_subfolders=(00822grids_test)

for result_subfolder in $result_subfolders; do
    echo ${folder}
    if [ ! -d ${dst_dir}/${result_folder} ]; then mkdir ${dst_dir}/${result_folder}; fi
    if [ ! -d ${dst_dir}/${result_folder}/${result_subfolder} ]; then mkdir ${dst_dir}/${result_folder}/${result_subfolder}; fi
    scp -r hongli@hydro-c1.rap.ucar.edu:${src_dir}/${result_folder}/${result_subfolder}/outputs \
    ${dst_dir}/${result_folder}/${result_subfolder}/outputs
done



