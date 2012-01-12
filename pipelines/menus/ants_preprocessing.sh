#!/bin/bash

preprocessing_config_01 () {  # run motion correction yes/no?
clear
mc_setup_chk=`cat ${exp_path}/scripts/dependencies.sh | grep mc`

if [ ${#mc_setup_chk} == 0 ]
then
# add variable to dependencies.sh to indicate if motion correction should be run
echo "" >> ${exp_path}/scripts/dependencies.sh 
echo "# Run motion correction (0=no; 1=yes)" >> ${exp_path}/scripts/dependencies.sh 
echo "mc=0" >> ${exp_path}/scripts/dependencies.sh 
current=`cat ${exp_path}/scripts/dependencies.sh | grep mc`

# add variable to dependencies.sh to indicate if motion correction was completed
echo "" >> ${exp_path}/scripts/dependencies.sh 
echo "# Motion correction complete (0=no; 1=yes)" >> ${exp_path}/scripts/dependencies.sh 
echo "mc_pass=0" >> ${exp_path}/scripts/dependencies.sh 

else
current=`cat ${exp_path}/scripts/dependencies.sh | grep mc`
fi

while : # Loop forever
do
cat <<MENU
Run Motion correction?

1) No
2) Yes

MENU

echo -n " Your choice? : "
read choice

case $choice in
1) sed s/"${current}"/"mc=0"/g ${exp_path}/scripts/dependencies.sh > ${exp_path}/scripts/dependencies_tmp.sh; 
   mv ${exp_path}/scripts/dependencies_tmp.sh ${exp_path}/scripts/dependencies.sh; 
   preprocessing_config_02;;
2) sed s/"${current}"/"mc=1"/g ${exp_path}/scripts/dependencies.sh > ${exp_path}/scripts/dependencies_tmp.sh; 
   mv ${exp_path}/scripts/dependencies_tmp.sh ${exp_path}/scripts/dependencies.sh; 
   preprocessing_config_02;;
*) echo "\"$choice\" is not valid "; sleep 2 ;;
esac
done
}

preprocessing_config_02 () { # run brain extraction yes/no?
clear
bxt_setup_chk=`cat ${exp_path}/scripts/dependencies.sh | grep bxt`

if [ ${#bxt_setup_chk} == 0 ]
then
echo "" >> ${exp_path}/scripts/dependencies.sh 
echo "# Run Brain Extraction (0=no; 1=yes)" >> ${exp_path}/scripts/dependencies.sh 
echo "bxt=0" >> ${exp_path}/scripts/dependencies.sh 
current=`cat ${exp_path}/scripts/dependencies.sh | grep bxt`

# add variable to dependencies.sh to indicate if brain extraction was completed
echo "" >> ${exp_path}/scripts/dependencies.sh 
echo "# Motion correction complete (0=no; 1=yes)" >> ${exp_path}/scripts/dependencies.sh 
echo "bxt_pass=0" >> ${exp_path}/scripts/dependencies.sh 
else
current=`cat ${exp_path}/scripts/dependencies.sh | grep bxt`
fi

while : # Loop forever
do
cat <<MENU
Run Brain Extraction? Currently not recommended for partial field of view data.

1) No
2) Yes

MENU

echo -n " Your choice? : "
read choice

case $choice in
1) sed s/"${current}"/"bxt=0"/g ${exp_path}/scripts/dependencies.sh > ${exp_path}/scripts/dependencies_tmp.sh; 
   mv ${exp_path}/scripts/dependencies_tmp.sh ${exp_path}/scripts/dependencies.sh; 
   preprocessing_config_03;;
2) sed s/"${current}"/"bxt=1"/g ${exp_path}/scripts/dependencies.sh > ${exp_path}/scripts/dependencies_tmp.sh; 
   mv ${exp_path}/scripts/dependencies_tmp.sh ${exp_path}/scripts/dependencies.sh; 
   preprocessing_config_03;;
*) echo "\"$choice\" is not valid "; sleep 2 ;;
esac
done
}

preprocessing_config_03 () { # configure buildtemplateparallel
clear
btp_setup_chk=`cat ${exp_path}/scripts/dependencies.sh | grep btp_params`

if [ ${#btp_setup_chk} == 0 ]
then
echo "" >> ${exp_path}/scripts/dependencies.sh 
echo "# Parameters for buildtemplateparallel.sh script" >> ${exp_path}/scripts/dependencies.sh 
echo "btp_params=0" >> ${exp_path}/scripts/dependencies.sh 
current=`cat ${exp_path}/scripts/dependencies.sh | grep btp_params`

# add variable to dependencies.sh to indicate if group template creation was completed
echo "" >> ${exp_path}/scripts/dependencies.sh 
echo "# Template creation complete (0=no; 1=yes)" >> ${exp_path}/scripts/dependencies.sh 
echo "btp_pass=0" >> ${exp_path}/scripts/dependencies.sh 

else
current=`cat ${exp_path}/scripts/dependencies.sh | grep bxt`
fi

while : # Loop forever
do
cat <<MENU
Configuration options for group template estimation.

0) Use defaults for serial job execution (local pc, one cpu core)
1) Use Sun Grid Engine qsub (SGE, only when available)
2) Use defaults for parallel job execution (local pc, multiple cpu cores; min 2)
3) Use Apple XGrid (only when available)
4) Use Portable Batch System (PBS, only when available)
5) Advanced configuration

MENU

echo -n " Your choice? : "
read choice

case $choice in
0) sed s/"${current}"/"btp_params=-c 0 -j 1"/g ${exp_path}/scripts/dependencies.sh > ${exp_path}/scripts/dependencies_tmp.sh; 
   mv ${exp_path}/scripts/dependencies_tmp.sh ${exp_path}/scripts/dependencies.sh; 
   preprocessing_config_04;;
1) sed s/"${current}"/"btp_params=-c 1 "/g ${exp_path}/scripts/dependencies.sh > ${exp_path}/scripts/dependencies_tmp.sh; 
   mv ${exp_path}/scripts/dependencies_tmp.sh ${exp_path}/scripts/dependencies.sh; 
   preprocessing_config_04;;
2) proc_pp3_option2;;
3) sed s/"${current}"/"btp_params= "/g ${exp_path}/scripts/dependencies.sh > ${exp_path}/scripts/dependencies_tmp.sh; 
   mv ${exp_path}/scripts/dependencies_tmp.sh ${exp_path}/scripts/dependencies.sh; 
   preprocessing_config_04;;
4) sed s/"${current}"/"btp_params= "/g ${exp_path}/scripts/dependencies.sh > ${exp_path}/scripts/dependencies_tmp.sh; 
   mv ${exp_path}/scripts/dependencies_tmp.sh ${exp_path}/scripts/dependencies.sh; 
   preprocessing_config_04;;
5) echo "currently not implemented. Please choose a default"; preprocessing_config_03 ;;
*) echo "\"$choice\" is not valid "; sleep 2 ;;
esac
done
}

proc_pp3_option2 () 
{
clear
if [ ${OSTYPE:0:6} == 'darwin' ]
then
  cpu_count=`sysctl -n hw.physicalcpu`
else
  ##Getting system info from linux can be done with these variables.
#  RAM=`cat /proc/meminfo | sed -n -e '/MemTotal/p' | awk '{ printf "%s %s\n", $2, $3 ; }' | cut -d " " -f 1`
#  RAMfree=`cat /proc/meminfo | sed -n -e '/MemFree/p' | awk '{ printf "%s %s\n", $2, $3 ; }' | cut -d " " -f 1`
#  cpu_free_ram=$((${RAMfree}/${cpu_count}))
  cpu_count=`cat /proc/cpuinfo | grep processor | wc -l`
fi

while : # Loop forever
do
cat <<MENU
This computer has ${cpu_count} cores available for analysis.

Depending on the amount of free RAM memory and the resolution of
the images for template estimation, you can use all cores for 
processing. For fMRI, 1GB RAM per core should be enough in most 
scenarios.

MENU

echo -n " Your choice? : "
read choice

if [[ $choice == ?(+|-)+([0-9]) ]] && [ ${choice} -le ${cpu_count} ] && [ ${choice} -gt 1 ]
then 
sed s/"${current}"/"btp_params=\"-c 2 -j ${choice}\""/g ${exp_path}/scripts/dependencies.sh > ${exp_path}/scripts/dependencies_tmp.sh; 
mv ${exp_path}/scripts/dependencies_tmp.sh ${exp_path}/scripts/dependencies.sh; 
preprocessing_config_04;
else
echo " "
echo "Please enter a valid number less than or equal to ${cpu_count} and greater than 1"
sleep 2
proc_pp3_option2
fi
done 
}

preprocessing_config_04 () {  # run bandpass temporal filtering
clear
bandpass_setup_chk=`cat ${exp_path}/scripts/dependencies.sh | grep "bandpass="`

if [ ${#bandpass_setup_chk} == 0 ]
then
# add variable to dependencies.sh to indicate if motion correction should be run
echo "" >> ${exp_path}/scripts/dependencies.sh 
echo "# Run temporal filtering (0=no; 1=yes)" >> ${exp_path}/scripts/dependencies.sh 
echo "bandpass=0" >> ${exp_path}/scripts/dependencies.sh 
current=`cat ${exp_path}/scripts/dependencies.sh | grep "bandpass="`

# add variable to dependencies.sh to indicate if motion correction was completed
echo "" >> ${exp_path}/scripts/dependencies.sh 
echo "# Temporal filtering complete (0=no; 1=yes)" >> ${exp_path}/scripts/dependencies.sh 
echo "bandpass_pass=0" >> ${exp_path}/scripts/dependencies.sh 

else
current=`cat ${exp_path}/scripts/dependencies.sh | grep "bandpass="`
fi

while : # Loop forever
do
cat <<MENU
Run temporal filtering (recommended)?

1) No
2) Yes

MENU

echo -n " Your choice? : "
read choice

case $choice in
1) sed s/"${current}"/"bandpass=0"/g ${exp_path}/scripts/dependencies.sh > ${exp_path}/scripts/dependencies_tmp.sh; 
   mv ${exp_path}/scripts/dependencies_tmp.sh ${exp_path}/scripts/dependencies.sh; 
   preprocessing_config_05;;
2) sed s/"${current}"/"bandpass=1"/g ${exp_path}/scripts/dependencies.sh > ${exp_path}/scripts/dependencies_tmp.sh; 
   mv ${exp_path}/scripts/dependencies_tmp.sh ${exp_path}/scripts/dependencies.sh; 
   preprocessing_config_05;;
*) echo "\"$choice\" is not valid "; sleep 2 ;;
esac
done
}

preprocessing_config_05 () {  # run spatial smoothing
clear
FWHM_setup_chk=`cat ${exp_path}/scripts/dependencies.sh | grep "run_FWHM="`

if [ ${#FWHM_setup_chk} == 0 ]
then
# add variable to dependencies.sh to indicate if motion correction should be run
echo "" >> ${exp_path}/scripts/dependencies.sh 
echo "# Run spatial smooting (0=no; 1=yes)" >> ${exp_path}/scripts/dependencies.sh 
echo "run_FWHM=0" >> ${exp_path}/scripts/dependencies.sh 
current=`cat ${exp_path}/scripts/dependencies.sh | grep "run_FWHM="`

# add variable to dependencies.sh to indicate if motion correction was completed
echo "" >> ${exp_path}/scripts/dependencies.sh 
echo "# Spatial smooting complete (0=no; 1=yes)" >> ${exp_path}/scripts/dependencies.sh 
echo "FWHM_pass=0" >> ${exp_path}/scripts/dependencies.sh 
else
current=`cat ${exp_path}/scripts/dependencies.sh | grep "run_FWHM="`
fi

while : # Loop forever
do
cat <<MENU
Run spatial smooting?

1) No
2) Yes

MENU

echo -n " Your choice? : "
read choice

case $choice in
1) sed s/"${current}"/"run_FWHM=0"/g ${exp_path}/scripts/dependencies.sh > ${exp_path}/scripts/dependencies_tmp.sh; 
   mv ${exp_path}/scripts/dependencies_tmp.sh ${exp_path}/scripts/dependencies.sh; 
   preprocessing_config_06;;
2) sed s/"${current}"/"run_FWHM=1"/g ${exp_path}/scripts/dependencies.sh > ${exp_path}/scripts/dependencies_tmp.sh; 
   mv ${exp_path}/scripts/dependencies_tmp.sh ${exp_path}/scripts/dependencies.sh; 
   preprocessing_config_06;;
*) echo "\"$choice\" is not valid "; sleep 2 ;;
esac
done
}

preprocessing_config_06 () {  # run CompCorr
clear
CompCorr_setup_chk=`cat ${exp_path}/scripts/dependencies.sh | grep "run_CompCorr="`

if [ ${#CompCorr_setup_chk} == 0 ]
then
# add variable to dependencies.sh to indicate if motion correction should be run
echo "" >> ${exp_path}/scripts/dependencies.sh 
echo "# Run CompCorr (0=no; 1=yes)" >> ${exp_path}/scripts/dependencies.sh 
echo "run_CompCorr=0" >> ${exp_path}/scripts/dependencies.sh 
current=`cat ${exp_path}/scripts/dependencies.sh | grep "run_CompCorr="`

# add variable to dependencies.sh to indicate if motion correction was completed
echo "" >> ${exp_path}/scripts/dependencies.sh 
echo "# CompCorr complete (0=no; 1=yes)" >> ${exp_path}/scripts/dependencies.sh 
echo "CompCorr_pass=0" >> ${exp_path}/scripts/dependencies.sh 

else
current=`cat ${exp_path}/scripts/dependencies.sh | grep "run_CompCorr="`
fi

while : # Loop forever
do
cat <<MENU
Run CompCorr physological noise removal?

1) No
2) Yes

MENU

echo -n " Your choice? : "
read choice

case $choice in
1) sed s/"${current}"/"run_CompCorr=0"/g ${exp_path}/scripts/dependencies.sh > ${exp_path}/scripts/dependencies_tmp.sh; 
   mv ${exp_path}/scripts/dependencies_tmp.sh ${exp_path}/scripts/dependencies.sh; 
   review_start;;
2) sed s/"${current}"/"run_CompCorr=1"/g ${exp_path}/scripts/dependencies.sh > ${exp_path}/scripts/dependencies_tmp.sh; 
   mv ${exp_path}/scripts/dependencies_tmp.sh ${exp_path}/scripts/dependencies.sh; 
   review_start;;
*) echo "\"$choice\" is not valid "; sleep 2 ;;
esac
done
} 

review_start () { # review preprocessing choices and start batch
clear
source ${exp_path}/scripts/dependencies.sh
while : # Loop forever
do
cat <<MENU
-------------------------------------------------------------------------------
ANTS functional MRI data processing pipeline - Review preprocessing & run
-------------------------------------------------------------------------------

experiment root: 		${exp_path}
data root:			${exp_path}/data
results:			${resultshome}

no sessions:			${ses}
no runs:			${runs}
run motion correction:		${mc}
run brain extraction:		${bxt}
template estimation parameters:	${btp_params}
run temporal filtering:		${bandpass}
run spatial filtering:		${run_FWHM}
run CompCorr:			${run_CompCorr}

Start pre-processing (y/n)?

-------------------------------------------------------------------------------
Written by Brian Avants & Niels van Strien, 2011/2012
-------------------------------------------------------------------------------
MENU

echo -n " Your choice? : "
read choice

case $choice in
y) run_preprocessing ;;
n) preprocessing_menu ;;
*) echo "\"$choice\" is not valid "; sleep 2 ;;
esac

done
}

run_preprocessing () { # main control structure for looping through data and running preprocessing

clear
source ants_functionlib # a textfile with ants-functions that are used in different scripts
source ${exp_path}/scripts/dependencies.sh # the user configuration file
mkdir -p ${resultshome}/preprocessing/SSBT_corrected/SSBT_creation # make a dir for template creation
    
for ((i = 1; i <= ${ses} ; i++)) # looping through sessions
do
    for ((j = 1; j <= ${runs} ; j++)) # looping through runs
    do
	determine_session_run # required call to determine the current session and run
	
	subarray=(`find ${exp_path}/data/${session}/${run}/* -prune -type f | tr " " "\n"`) # a real bash array with subject names

	# create average images of time series; needed for SSBT if no other processing options are used
	# Question: create these files regardless of preprocessing choices?
	if [ ! -d ${exp_path}/data/${session}/${run}/avg ]; then mkdir ${exp_path}/data/${session}/${run}/avg; fi

######################################################################################################################################
	for ((k = 0; k <= ${#subarray[@]}-1 ; k++)) # creating average images needed for analysis
	do
	  outfname=$(basename $(echo ${subarray[k]} | cut -d '.' -f 1 )) # nested command execution; neat!
	  OUT="${exp_path}/data/${session}/${run}/avg/${outfname}"
	  if [ ! -f ${OUT}_avg.nii.gz ]
	  then
	    time_start=`date +%s`
	    Procedure="Creating time-series average ${session} ${run} subject: ${outfname}"
	    ants_moco -d 3 -a ${subarray[k]} -o ${OUT}_avg.nii.gz >> ${exp_path}/logs/std.out
	    echo "${exp_path}/data/${session}/${run}/avg/${outfname}_avg.nii.gz" >> ${resultshome}/preprocessing/SSBT_corrected/SSBT_creation/subjects.txt
	    showBar ${k} ${#subarray[@]} ${time_start} ${Procedure} # show progress bar
	  fi
	done

######################################################################################################################################
	  if [ ${mc} -eq 1 ] # run motion correction if mc=1
	  then

	    if [ -f ${resultshome}/preprocessing/SSBT_corrected/SSBT_creation/subjects.txt ]
	    then
	      rm ${resultshome}/preprocessing/SSBT_corrected/SSBT_creation/subjects.txt # will be replaced by motion corrected fnames
	    fi

	    mkdir -p ${resultshome}/preprocessing/motion_correction/data/${session}/${run}/

	    for ((k = 0; k <= ${#subarray[@]}-1 ; k++))
	    do
	      outfname=$(basename $(echo ${subarray[k]} | cut -d '.' -f 1 )) # nested command execution; neat!
	      OUT="${resultshome}/preprocessing/motion_correction/data/${session}/${run}/${outfname}"
	      infname=${subarray[k]}

	      Procedure="Motion correction ${session} ${run} subject: ${outfname}"
	      
	      if [ ${k} -eq 0 ] # test needed to show progress bar for 1st subject
	      then
		time_start=0
	      fi

	      showBar ${k} ${#subarray[@]}  ${time_start}

	      time_start=`date +%s`
		mc_ants_rigid ${infname} ${OUT} >> ${exp_path}/logs/std.out # run motion correction

	      echo "${resultshome}/preprocessing/motion_correction/data/${session}/${run}/${outfname}_avg.nii.gz" >> ${resultshome}/preprocessing/SSBT_corrected/SSBT_creation/subjects_mc.txt
	      
	      sleep 1 # debug only
		
	    done

	    # change variable in dependencies.sh to indicate that motion correction was completed
	    sed s/"mc_pass=0"/"mc_pass=1"/g ${exp_path}/scripts/dependencies.sh > ${exp_path}/scripts/dependencies_tmp.sh; 
	    mv ${exp_path}/scripts/dependencies_tmp.sh ${exp_path}/scripts/dependencies.sh; 
	    source ${exp_path}/scripts/dependencies.sh; 
	    clear
	  fi

######################################################################################################################################
	  if [ ${bxt} -eq 1 ] # run brain extraction if bxt=1; currently only makes a mask image, but needs to make 4D masked files as well.
	  then

	    mkdir -p ${resultshome}/preprocessing/brain_extraction/data/${session}/${run}/

	    if [ -f ${resultshome}/preprocessing/SSBT_corrected/SSBT_creation/subjects.txt ] || [ -f ${resultshome}/preprocessing/SSBT_corrected/SSBT_creation/subjects_mc.txt ] 
	    then
	      rm ${resultshome}/preprocessing/SSBT_corrected/SSBT_creation/subjects*.txt # will be replaced by brain extracted corrected fnames
	    fi

	    for ((k = 0; k <= ${#subarray[@]}-1 ; k++))
	    do
	      time_start=`date +%s`
	      outfname=$(basename $(echo ${subarray[k]} | cut -d '.' -f 1 )) # nested command execution; neat!
	      if [ ${mc} -eq 1 ] && [ ${mc_pass} -eq 1 ] # use motion corrected results if motion correction was run
	      then 
		
		infname="${resultshome}/preprocessing/motion_correction/data/${session}/${run}/${outfname}_avg.nii.gz"
		OUT="${resultshome}/preprocessing/brain_extraction/data/${session}/${run}/${outfname}"
		ants_bxt ${infname} ${OUT}

		echo "${resultshome}/preprocessing/brain_extraction/data/${session}/${run}/${outfname}_avg.nii.gz" >> ${resultshome}/preprocessing/SSBT_corrected/SSBT_creation/subjects_bxt.txt
		showBar ${k} ${#subarray[@]} ${time_start} ${Procedure} # show progress bar

	      else # use original data 
	      
		OUT="${resultshome}/preprocessing/brain_extraction/data/${session}/${run}/${outfname}"		
		ants_moco -d 3 -a ${subarray[k]} -o ${OUT}_avg.nii.gz 
		infname="${resultshome}/preprocessing/brain_extraction/data/${session}/${run}/${outfname}_avg.nii.gz"
		ants_bxt ${infname} ${OUT}

		echo "${resultshome}/preprocessing/brain_extraction/data/${session}/${run}/${outfname}_avg.nii.gz" >> ${resultshome}/preprocessing/SSBT_corrected/SSBT_creation/subjects_bxt.txt
		showBar ${k} ${#subarray[@]} ${time_start} ${Procedure} # show progress bar

	      fi	      
	    
	    Procedure="Brain Extraction ${session} ${run} subject: ${outfname}"
	    showBar ${k} ${#subarray[@]} ${Procedure}

	  done

	  # change variable in dependencies.sh to indicate that motion correction was completed
	  sed s/"bxt_pass=0"/"bxt_pass=1"/g ${exp_path}/scripts/dependencies.sh > ${exp_path}/scripts/dependencies_tmp.sh; 
	  mv ${exp_path}/scripts/dependencies_tmp.sh ${exp_path}/scripts/dependencies.sh; 
	  source ${exp_path}/scripts/dependencies.sh; 

	  clear
	  fi
    done
done

######################################################################################################################################
# Using buildtemplateparallel.sh to create template. Need to break out of control loop to estimate template.
btplist=`ls ${resultshome}/preprocessing/SSBT_corrected/SSBT_creation/subjects*.txt`
if [ ! -f ${btplist} ] # this will 
then
echo "missing subjects list"
else
echo "run btp"
exe=buildtemplateparallel.sh -d 3 -o ${resultshome}/preprocessing/SSBT_corrected/SSBT_creation/mean ${btp_params} `cat ${btplist}`
$exe
sed s/"btp_pass=0"/"btp_pass=1"/g ${exp_path}/scripts/dependencies.sh > ${exp_path}/scripts/dependencies_tmp.sh; 
mv ${exp_path}/scripts/dependencies_tmp.sh ${exp_path}/scripts/dependencies.sh; 
fi

######################################################################################################################################
# continue pre-processing using R
for ((i = 1; i <= ${ses} ; i++)) # looping through sessions
do
    for ((j = 1; j <= ${runs} ; j++)) # looping through runs
    do
      clear
      determine_session_run # required call to determine the current session and run
      
      subarray=(`find ${exp_path}/data/${session}/${run}/* -prune -type f | tr " " "\n"`) # a real bash array with subject names

      if [ ${bandpass} -eq 1 ] # run band pass temporal filtering
      then
      echo "Temporal filtering"
      fi

      if [ ${run_FWHM} -eq 1 ] # run spatial smoothing
      then
      echo "Spatial smoothing"
      fi

      if [ ${run_CompCorr} -eq 1 ] # run CompCorr removal of physiological noise
      then
      echo "CompCorr"
      fi

    done
done

} #end of preprocessing function

preprocessing_menu () {
clear

while : # Loop forever
do
cat <<MENU
-------------------------------------------------------------------------------
ANTS functional MRI data processing pipeline - Preprocessing
-------------------------------------------------------------------------------
Preprocessing involves the following steps:

- Motion correction.
- Brain extraction.
- BOLD study template estimation 
- Transformation of time-series to study space
- Band pass temporal filtering (high pass / low pass).
- Spatial smoothing.
- Compcorr (removal of physiological noise)

These processing steps are run for the entire group.

Options 
1) Configure & run preprocessing on group
2) Return to main menu.
3) Exit.

-------------------------------------------------------------------------------
Written by Brian Avants & Niels van Strien, 2011/2012
-------------------------------------------------------------------------------
MENU

echo -n " Your choice? : "
read choice

case $choice in
1) preprocessing_config_01 ;;
2) main_menu ;;
3) bye ;;
*) echo "\"$choice\" is not valid "; sleep 2 ;;
esac
done
}

# main script starts here
clear
preprocessing_menu