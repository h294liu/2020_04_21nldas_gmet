# Update setup
RootDir=/glade/u/home/hongli/scratch/2020_04_21nldas_gmet
SampleMode=uniform #uniform random

SourceDir=${RootDir}/scripts
StnlistDir=${SourceDir}/step1_sample_stnlist_${SampleMode}_perturb

WorkDirBase=${RootDir}/test_${SampleMode}_perturb
if [ ! -d ${WorkDirBase} ]; then mkdir -p ${WorkDirBase}; fi

pyfigFileName=step25_rank_sum_test.py
pyfigFileNameShort="${pyfigFileName/.py/}"
pyPath=/glade/u/home/hongli/github/2020_04_21nldas_gmet/step25_rank_sum_test.py

stn_vars=('pcp_error' 'pcp_error_2' 'tmean_error_2' 'trange_error_2')
#nldas_vars=('pcp_error_update' 'pcp_error_2_update' 'tmean_error_2' 'trange_error_2')
nldas_vars=('pcp_error' 'pcp_error_2' 'tmean_error_2' 'trange_error_2')

#------------------------------------------------------------
# loop through all stnlist files
FILES=( $(ls ${StnlistDir}/*.txt) )
FILE_NUM=${#FILES[@]}
var_num=${#nldas_vars[@]}

#for i in $(seq 0 $(($FILE_NUM -1))); do
for i in $(seq 0 0); do

    FileName=${FILES[${i}]} 
    FileName=${FileName##*/} # get basename of filename
    FileNameShort="${FileName/.txt/}" # remove suffix ".txt"
    GridNum=$(echo $FileNameShort| cut -d'_' -f 2) # extract substring "012grids"    
    CaseID=${GridNum}
    echo ${CaseID}

    # work folders
    WorkDir=${WorkDirBase}/${CaseID}
    if [ ! -d ${WorkDir}/tmp ]; then mkdir ${WorkDir}/tmp; fi
    
    # loop through all variables
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
        echo "#SBATCH --job-name=HP.${CaseID}.${stn_var}" >> ${CommandFile}
        echo '#SBATCH --account=P48500028' >> ${CommandFile}
        echo '#SBATCH --partition=dav' >> ${CommandFile}
        echo '#SBATCH --ntasks=10' >> ${CommandFile}
	echo '#SBATCH --ntasks-per-node=36' >> ${CommandFile}
        echo '#SBATCH --time=01:00:00' >> ${CommandFile}
        echo "#SBATCH --output=$LogFile.%j" >> ${CommandFile}
        
        echo "mkdir -p /glade/scratch/hongli/temp" >> ${CommandFile}
        echo "export TMPDIR=/glade/scratch/hongli/temp" >> ${CommandFile}

	#echo "module load python/3.7.5" >> $CommandFile
	#echo "ncar_pylib" >> $CommandFile

        echo "python ${pyPath} ${i} ${stn_var} ${nldas_var}" >> ${CommandFile}
        chmod 744 ${CommandFile}
        
        sbatch ${CommandFile}
     done
done
