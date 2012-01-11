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

# add variable to dependencies.sh to indicate if motion correction was completed
echo "" >> ${exp_path}/scripts/dependencies.sh 
echo "# Motion correction complete (0=no; 1=yes)" >> ${exp_path}/scripts/dependencies.sh 
echo "mc_pass=0" >> ${exp_path}/scripts/dependencies.sh 
current=`cat ${exp_path}/scripts/dependencies.sh | grep mc`
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

# add variable to dependencies.sh to indicate if brain extraction was completed
echo "" >> ${exp_path}/scripts/dependencies.sh 
echo "# Motion correction complete (0=no; 1=yes)" >> ${exp_path}/scripts/dependencies.sh 
echo "bxt_pass=0" >> ${exp_path}/scripts/dependencies.sh 

current=`cat ${exp_path}/scripts/dependencies.sh | grep bxt`
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
   review_start;;
2) sed s/"${current}"/"bxt=1"/g ${exp_path}/scripts/dependencies.sh > ${exp_path}/scripts/dependencies_tmp.sh; 
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

Review your choices and create the datastructure

experiment root: 	${exp_path}
data root:		${exp_path}/data
results:		${resultshome}

no sessions:		${ses}
no runs:		${runs}

run motion correction:	${mc}
run brain extraction:	${bxt}



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
      if [ ${i} -lt 10 ] # dealing with leading zero in session dirname 
      then
	
	for ((j = 1; j <= ${runs} ; j++)) # looping through runs
	do
	
	if [ ${j} -lt 10 ] # dealing with leading zero in run dirname
	then
	subarray=(`find ${exp_path}/data/session_0${i}/run_0${j}/* -prune -type f | tr " " "\n"`) # a real bash array with subject names

	# create average images of time series; needed for SSBT if no other processing options are used
	# Question: create these files regardless of preprocessing choices?
	if [ ! -d ${exp_path}/data/session_0${i}/run_0${j}/avg ]; then mkdir ${exp_path}/data/session_0${i}/run_0${j}/avg; fi

	for ((k = 0; k <= ${#subarray[@]}-1 ; k++))
	do
	outfname=$(basename $(echo ${subarray[k]} | cut -d '.' -f 1 )) # nested command execution; neat!
	OUT="${exp_path}/data/session_0${i}/run_0${j}/avg/${outfname}"

	if [ ! -f ${OUT}_avg.nii.gz ]
	then
	time_start=`date +%s`
	Procedure="Creating time-series average session_0${i} run_0${j} subject: ${outfname}"
	ants_moco -d 3 -a ${subarray[k]} -o ${OUT}_avg.nii.gz >> ${exp_path}/logs/std.out
	echo "${exp_path}/data/session_0${i}/run_0${j}/avg/${outfname}_avg.nii.gz" >> ${resultshome}/preprocessing/SSBT_corrected/SSBT_creation/subjects.txt
	showBar ${k} ${#subarray[@]} ${time_start} ${Procedure} # show progress bar
	fi
	done

	  if [ ${mc} -eq 1 ] # run motion correction if mc=1
	  then

	      if [ -f ${resultshome}/preprocessing/SSBT_corrected/SSBT_creation/subjects.txt ]
	      then
	      rm ${resultshome}/preprocessing/SSBT_corrected/SSBT_creation/subjects.txt # will be replaced by motion corrected fnames
	      fi

	      mkdir -p ${resultshome}/preprocessing/motion_correction/data/session_0${i}/run_0${j}/
	      for ((k = 0; k <= ${#subarray[@]}-1 ; k++))
	      do
	
		outfname=$(basename $(echo ${subarray[k]} | cut -d '.' -f 1 )) # nested command execution; neat!
		OUT="${resultshome}/preprocessing/motion_correction/data/session_0${i}/run_0${j}/${outfname}"
		infname=${subarray[k]}

		Procedure="Motion correction session_0${i} run_0${j} subject: ${outfname}"
		
		if [ ${k} -eq 0 ] # test needed to show progress bar for 1st subject
		then
		time_start=0
		fi

		showBar ${k} ${#subarray[@]}  ${time_start}

	        time_start=`date +%s`
		mc_ants_rigid ${infname} ${OUT} >> ${exp_path}/logs/std.out # run motion correction

		echo "${resultshome}/preprocessing/motion_correction/data/session_0${i}/run_0${j}/${outfname}_avg.nii.gz" >> ${resultshome}/preprocessing/SSBT_corrected/SSBT_creation/subjects_mc.txt
		
		oldtimestart=${time_start}
		  
	      done

	      # change variable in dependencies.sh to indicate that motion correction was completed
	      sed s/"mc_pass=0"/"mc_pass=1"/g ${exp_path}/scripts/dependencies.sh > ${exp_path}/scripts/dependencies_tmp.sh; 
	      mv ${exp_path}/scripts/dependencies_tmp.sh ${exp_path}/scripts/dependencies.sh; 
	      source ${exp_path}/scripts/dependencies.sh; 
	      clear

	  fi

	  if [ ${bxt} -eq 1 ] # run brain extraction if bxt=1; currently only makes a mask image, but needs to make 4D masked files as well.
	  then

	      mkdir -p ${resultshome}/preprocessing/brain_extraction/data/session_0${i}/run_0${j}/

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
		  
		  infname="${resultshome}/preprocessing/motion_correction/data/session_0${i}/run_0${j}/${outfname}_avg.nii.gz"
		  OUT="${resultshome}/preprocessing/brain_extraction/data/session_0${i}/run_0${j}/${outfname}"
		  ants_bxt ${infname} ${OUT}

		  echo "${resultshome}/preprocessing/brain_extraction/data/session_0${i}/run_0${j}/${outfname}_avg.nii.gz" >> ${resultshome}/preprocessing/SSBT_corrected/SSBT_creation/subjects_bxt.txt
		  showBar ${k} ${#subarray[@]} ${time_start} ${Procedure} # show progress bar

		else # use original data 
		
		  OUT="${resultshome}/preprocessing/brain_extraction/data/session_0${i}/run_0${j}/${outfname}"		
		  ants_moco -d 3 -a ${subarray[k]} -o ${OUT}_avg.nii.gz 
		  infname="${resultshome}/preprocessing/brain_extraction/data/session_0${i}/run_0${j}/${outfname}_avg.nii.gz"
		  ants_bxt ${infname} ${OUT}

		  echo "${resultshome}/preprocessing/brain_extraction/data/session_0${i}/run_0${j}/${outfname}_avg.nii.gz" >> ${resultshome}/preprocessing/SSBT_corrected/SSBT_creation/subjects_bxt.txt
		  showBar ${k} ${#subarray[@]} ${time_start} ${Procedure} # show progress bar

		fi	      
	      
	      Procedure="Brain Extraction session_0${i} run_0${j} subject: ${outfname}"
	      showBar ${k} ${#subarray[@]} ${Procedure}

	    done

	  # change variable in dependencies.sh to indicate that motion correction was completed
	  sed s/"bxt_pass=0"/"bxt_pass=1"/g ${exp_path}/scripts/dependencies.sh > ${exp_path}/scripts/dependencies_tmp.sh; 
	  mv ${exp_path}/scripts/dependencies_tmp.sh ${exp_path}/scripts/dependencies.sh; 
	  source ${exp_path}/scripts/dependencies.sh; 

	  clear
	  fi

	else # condition where leading zero in run dirname is removed (more than 10 runs!)
	echo "mkdir -p ${exp_path}/data/session_0${i}/run_${j}"

	# would need repeat of the above code; needs fix 

	fi
	done
      else # dealing with leading 0 in session number; would need repeat of the above code; needs fix 
	for ((j = 1; j <= ${runs} ; j++))
	do
	if [ ${j} -lt 10 ]
	then
	echo "mkdir -p ${exp_path}/data/session_${i}/run_0${j}"
	else
	echo "mkdir -p ${exp_path}/data/session_${i}/run_${j}"
	fi
	done
      fi
    done

# Using buildtemplateparallel.sh to create template. Need to break out of control loop to estimate template.
btplist=`ls ${resultshome}/preprocessing/SSBT_corrected/SSBT_creation/subjects*.txt`
if [ ! -f ${btplist} ] # this will 
then
echo "missing subjects list"
else
echo "run btp"
exe="buildtemplateparallel.sh -d 3 -o ${resultshome}/preprocessing/SSBT_corrected/SSBT_creation/mean `cat ${btplist}` "
$exe
exit
fi

}



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


