#!/bin/bash
#SBATCH --job-name=step24
#SBATCH --account=P48500028
#SBATCH --partition=dav
#SBATCH --ntasks=1
#SBATCH --time=01:00:00
#SBATCH --output=%j.step24
mkdir -p /glade/scratch/hongli/temp
export TMPDIR=/glade/scratch/hongli/temp

module load python
ncar_pylib

python step24_plot_regr_error_box_wSTN.py

#module load gnu
#module load netcdf
#/glade/u/home/hongli/tools/GMET-1/downscale/downscale_bc.exe /glade/u/home/hongli/scratch/2020_04_21nldas_gmet/test_uniform_perturb/00818grids/tmp/config.2013
