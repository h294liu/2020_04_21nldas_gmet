#!/bin/bash
#PBS -N dfl_ens
#PBS -A P48500028
#PBS -q regular
#PBS -l select=1:ncpus=1:mpiprocs=1
#PBS -l walltime=12:00:00
#PBS -o compress.o
#PBS -e compress.e

#------------------------------------------------------------
# H. liu, August 6, 2021.
# Compress the all netcdf files of EDN2.
# Reference: http://nco.sourceforge.net/nco.html#Options-specific-to-ncks

inputDir=/glade/u/home/hongli/scratch/2020_04_21nldas_gmet/EDN2
outputDir=/glade/u/home/hongli/scratch/2020_04_21nldas_gmet/EDN2_compress

#------------------------------------------------------------
for folder in regression ensemble_summary; do
# for folder in regression; do
    
    # make output folder if it does not exist.
    if [ ! -d $outputDir/$folder ]; then mkdir -p $outputDir/$folder; fi
    
    # compress nc file by loop.
    for filePath in $inputDir/$folder/*.nc; do
        filename="$(basename ${filePath})"
        echo $filename
        ncks -h -4 -O -L 4 $filePath $outputDir/$folder/$filename
    done
done
