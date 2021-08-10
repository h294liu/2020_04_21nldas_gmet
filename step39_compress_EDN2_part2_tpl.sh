#!/bin/bash
#PBS -N dfl_YYYY
#PBS -A P48500028
#PBS -q regular
#PBS -l select=1:ncpus=1:mpiprocs=1
#PBS -l walltime=12:00:00
#PBS -o compress_YYYY.o
#PBS -e compress_YYYY.e

#------------------------------------------------------------
# H. liu, August 6, 2021.
# Compress the all netcdf files of EDN2.
# Reference: http://nco.sourceforge.net/nco.html#Options-specific-to-ncks

inputDir=/glade/u/home/hongli/scratch/2020_04_21nldas_gmet/EDN2
outputDir=/glade/u/home/hongli/scratch/2020_04_21nldas_gmet/EDN2_compress
folder=ensemble
yr=YYYY
#------------------------------------------------------------

# compress nc file by loop.
for filePath in $inputDir/$folder/ens_forc.${yr}.*.nc; do
    filename="$(basename ${filePath})"
    echo $filename
    if [ -e $outputDir/$folder/$filename ]; then rm -rf $outputDir/$folder/$filename; fi
    ncks -h -4 -O -L 4 $filePath $outputDir/$folder/$filename
done

