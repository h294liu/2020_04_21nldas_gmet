#!/bin/bash
#------------------------------------------------------------
# H. liu, August 6, 2021.
# Compress the all netcdf files of EDN2.
# Reference: http://nco.sourceforge.net/nco.html#Options-specific-to-ncks

inputDir=/glade/u/home/hongli/scratch/2020_04_21nldas_gmet/EDN2
outputDir=/glade/u/home/hongli/scratch/2020_04_21nldas_gmet/EDN2_compress

commandDir=/glade/u/home/hongli/github/2020_04_21nldas_gmet/step39_compress_EDN2_part2_cmds
if [ ! -d $commandDir ]; then mkdir -p $commandDir; fi
ConfigFileTemplate=step39_compress_EDN2_part2_tpl.sh


#------------------------------------------------------------
for yr in $(seq 1979 1 2019); do
# for yr in $(seq 1979 1 1981); do

    echo $yr

    # set up job configuration file
    ConfigFileName=step39_compress_EDN2_part2_${yr}.sh
    ConfigFile=${commandDir}/$ConfigFileName
    if [ -e ${command_file} ]; then rm -rf ${command_file}; fi

    sed "s,YYYY,$yr,g" $ConfigFileTemplate > $ConfigFile
    chmod 740 ${ConfigFile}
    
    # submit job
    cd $commandDir
    qsub $ConfigFileName    
    cd ../
done
