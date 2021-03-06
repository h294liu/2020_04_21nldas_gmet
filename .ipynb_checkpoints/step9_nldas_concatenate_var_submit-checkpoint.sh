#!/bin/bash
set -e

# H. liu, April 28, 2020.
# Run ensemble forcing generation year by year by generate_ensemble.exe.
# Depending on the existence of regression file generated by GMET downscaling code.
# Reference: /home/hydrofcst/otl_support/forcings/GMET/run/run_ens_forc.RETRO.csh
 
# #------------------------------------------------------------
# # Update setup
# RootDir=/glade/u/home/hongli/scratch/2020_04_21nldas_gmet
# configFileName=nldas_concatenate.sh
# configFileNameShort="${configFileName/.sh/}"
# Template=/glade/u/home/hongli/github/2020_04_21nldas_gmet/config/$configFileName
# #------------------------------------------------------------

# # create work folders
# WorkDir=/glade/u/home/hongli/scratch/2020_04_21nldas_gmet/data
# if [ ! -d ${WorkDir} ]; then mkdir ${WorkDir}; fi
# if [ ! -d ${WorkDir}/tmp ]; then mkdir ${WorkDir}/tmp; fi
# if [ ! -d ${WorkDir}/nldas_daily_utc_convert_summary ]; then mkdir ${WorkDir}/nldas_daily_utc_convert_summary; fi     

# for Var in pcp t_mean t_range; do 
 
#     # configure config, output and log files
#     ConfigFileName=$configFileNameShort.$Var.sh
#     ConfigFile=${WorkDir}/tmp/$ConfigFileName

#     RegrInDir=${WorkDir}/nldas_daily_utc_convert           # NLDAS directory
#     RegrOutDir=${WorkDir}/nldas_daily_utc_convert_summary  # ncrcat output directory

#     sed "s,INDIR,$RegrInDir,g" $Template |\
#     sed "s,VAR,$Var,g" |\
#     sed "s,OUTDIR,$RegrOutDir,g" > $ConfigFile
#     chmod 740 ${ConfigFile}

#      # create job submission file
#     CommandFile=${WorkDir}/tmp/qsub.$configFileNameShort.$Var.sh
#     if [ -e ${command_file} ]; then rm -rf ${command_file}; fi

#     LogFile=${WorkDir}/tmp/log.$configFileNameShort.$Var
#     rm -f $LogFile.*

#     echo '#!/bin/bash' > ${CommandFile}
#     echo "#PBS -N ${Var}" >> ${CommandFile}
#     echo '#PBS -A P48500028' >> ${CommandFile}
#     echo '#PBS -q regular' >> ${CommandFile}
#     echo '#PBS -l select=1:ncpus=1:mpiprocs=1' >> ${CommandFile}
#     echo '#PBS -l walltime=01:00:00' >> ${CommandFile}
#     echo "#PBS -o ${LogFile}.o" >> ${CommandFile}
#     echo "#PBS -e ${LogFile}.e" >> ${CommandFile}

#     echo "mkdir -p /glade/scratch/hongli/temp" >> ${CommandFile}
#     echo "export TMPDIR=/glade/scratch/hongli/temp" >> ${CommandFile}

#     echo "cd ${WorkDir}/tmp/" >> ${CommandFile}
#     echo "./${ConfigFileName}" >> ${CommandFile}
#     chmod 740 ${CommandFile}

#     qsub ${CommandFile}
# done

cd /glade/u/home/hongli/scratch/2020_04_21nldas_gmet/data/nldas_daily_utc_convert_summary
ncrcat -h -O -n 41,4,1 -v pcp ../nldas_daily_utc_convert/NLDAS_1979.nc NLDAS_1979_2019_pcp.nc
ncrcat -h -O -n 41,4,1 -v t_mean ../nldas_daily_utc_convert/NLDAS_1979.nc NLDAS_1979_2019_t_mean.nc
ncrcat -h -O -n 41,4,1 -v t_range ../nldas_daily_utc_convert/NLDAS_1979.nc NLDAS_1979_2019_t_range.nc

