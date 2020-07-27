# Update setup
RootDir=/glade/u/home/hongli/scratch/2020_04_21nldas_gmet
SampleMode=uniform #uniform random

SourceDir=${RootDir}/scripts
StnlistDir=${SourceDir}/step1_sample_stnlist_${SampleMode}_perturb

WorkDirBase=${RootDir}/test_${SampleMode}_perturb
if [ ! -d ${WorkDirBase} ]; then mkdir -p ${WorkDirBase}; fi

pyfigFileName=step29_rank_sum_test_ens.py
pyfigFileNameShort="${pyfigFileName/.py/}"
pyPath=/glade/u/home/hongli/github/2020_04_21nldas_gmet/$pyfigFileName

stn_vars=('pcp_std' 'tmean_std' 'tmin_std' 'tmax_std' 'trange_std')
nldas_vars=('pcp' 't_mean' 't_min' 't_max' 't_range')

#------------------------------------------------------------
# loop through all stnlist files
FILES=( $(ls ${StnlistDir}/*.txt) )
FILE_NUM=${#FILES[@]}
var_num=${#nldas_vars[@]}

for i in $(seq 0 $(($FILE_NUM -1))); do
# for i in $(seq 0 0); do

    FileName=${FILES[${i}]} 
    FileName=${FileName##*/} # get basename of filename
    FileNameShort="${FileName/.txt/}" # remove suffix ".txt"
    GridNum=$(echo $FileNameShort| cut -d'_' -f 2) # extract substring "012grids"    
    CaseID=${GridNum}
    echo ${CaseID}

    # work folders
    WorkDir=${WorkDirBase}/${CaseID}
    if [ ! -d ${WorkDir}/tmp ]; then mkdir ${WorkDir}/tmp; fi
    
    # loop through all variables (p',p_2',tmean_2,trange_2)
    for j in $(seq 0 $var_num); do
        stn_var=${stn_vars[$j]}
        nldas_var=${nldas_vars[$j]}
        echo ${stn_var} ${nldas_var}

        # create job submission file
        CommandFile=${WorkDir}/tmp/qsub.$pyfigFileNameShort.${nldas_var}.sh
        if [ -e ${command_file} ]; then rm -rf ${command_file}; fi
        
        LogFile=${WorkDir}/tmp/log.$pyfigFileNameShort.${nldas_var}
        rm -f $LogFile.*

        echo '#!/bin/bash' > ${CommandFile}
        echo "#PBS -N HpTest.${CaseID}" >> ${CommandFile}
        echo '#PBS -A P48500028' >> ${CommandFile}
        echo '#PBS -q regular' >> ${CommandFile}
        echo '#PBS -l select=10:ncpus=36:mpiprocs=36' >> ${CommandFile}
        echo '#PBS -l walltime=00:30:00' >> ${CommandFile}
        echo "#PBS -o ${LogFile}.o" >> ${CommandFile}
        echo "#PBS -e ${LogFile}.e" >> ${CommandFile}
        
        echo "mkdir -p /glade/scratch/hongli/temp" >> ${CommandFile}
        echo "export TMPDIR=/glade/scratch/hongli/temp" >> ${CommandFile}

        echo "python ${pyPath} ${i} ${stn_var} ${nldas_var}" >> ${CommandFile}
        chmod 740 ${CommandFile}
        
        qsub ${CommandFile}
     done
done
