#!/bin/bash

#############################################################
# testing usage
#############################################################
if [ $# -lt 1 ] ; then 
 echo usage:
 echo `basename $0` path_to_dependencies.sh 
 echo e.g.:
 echo `basename $0` /home/me/kirby/scripts/dependencies.sh 
 exit
fi 

#############################################################
# make control-c work
#############################################################

# trap keyboard interrupt (control-c)
trap control_c SIGINT

control_c() {
# run if user hits control-c
  echo -en "\n*** User pressed CTRL + C ***\n"
  exit $?
  echo -en "\n*** Script cancelled by user ***\n"
}

#############################################################
# setup output directory structure
#############################################################
f_setup_results_dirs () {
pipelinedir=${framework}

# setup neccesary directory structure
if [ ! -d ${resultshome}/${pipelinedir} ] ; then
  mkdir -p ${resultshome}/${pipelinedir}
  cd ${resultshome}/${pipelinedir}/

  mkdir -p 01_singlesub_template/session_01
  mkdir -p 01_singlesub_template/session_02
  mkdir 02_grp_template

  mkdir -p 03_CompCorr/session_01
  mkdir -p 03_CompCorr/session_02


  mkdir -p 04_ImageComparisonStats/DiceOverlap
  mkdir -p 04_ImageComparisonStats/OneSampleT_Test/session_01
  mkdir -p 04_ImageComparisonStats/OneSampleT_Test/session_02
  mkdir -p 04_ImageComparisonStats/PairedSamplesT_Test

fi
} 

#############################################################
# function to download the kirkby data from NITRC using curl
#############################################################
downloadKirkbyData () {
clear
mkdir -p ${datahome}
cd ${datahome}
for ((i = 1; i <= 42 ; i++))
do
  if [ ${i} -lt 10 ] ; then
    if [ ! -f "KKI2009-0${i}.tar.bz2" ] ; then
    echo
    echo "Downloading KKI2009-0${i}.tar.bz2"
    curl -O ftp://www.nitrc.org/multimodal/kki2009/KKI2009-0${i}.tar.bz2
    fi
  else
    if [ ! -f "KKI2009-${i}.tar.bz2" ] ; then
    echo 
    echo "Downloading KKI2009-${i}.tar.bz2"
    curl -O ftp://www.nitrc.org/multimodal/kki2009/KKI2009-${i}.tar.bz2
    fi
  fi
done
}

#############################################################
# function to download atlas and label images using curl
#############################################################
downloadAtlasData () {
clear

if [ ! -s ${FSLDIR}/data/atlases/HarvardOxford/HarvardOxford-cort-maxprob-thr50-2mm.nii.gz ] ; then
  mkdir -p ${resultshome}/atlas
  cd ${resultshome}/atlas
  curl -O http://rad01.homelinux.org/temporallobe/HarvardOxford-cort-maxprob-thr50-2mm.nii.gz
  atlaspath=${resultshome}/atlas/
else
  atlaspath=${FSLDIR}/data/atlases/HarvardOxford/
fi

if [ ! -s ${resultshome}/atlas/EPI.nii ] ; then
  mkdir -p ${resultshome}/atlas
  cd ${resultshome}/atlas
  curl -O http://rad01.homelinux.org/temporallobe/EPI.nii
fi
MNIBOLDatlaspath=${resultshome}/atlas/
}

#############################################################
# f_kirkby_unpack calls unpackKirkbyData to unpack and sort the data
#############################################################

# this function unpacks the data and splits it up in subfolders
unpackKirkbyData () {
	dataset=${1}
	extract_all=0
        if [ $extract_all == 0 ] ; then 
          seqname=fMRI
	  mkdir $seqname
          tar xvjf  ${dataset}.tar.bz2 ${dataset}-fMRI.nii
	  gzip     ${dataset}-fMRI.nii
	  mv ${dataset}-fMRI.nii.gz ${seqname}/
        fi 
        if [ $extract_all == 1 ] ; then 
	  bzip2 -t -d ${dataset}.tar.bz2 
	  tar -vjf  --extract --file=${dataset}.tar.bz2  fMRI
	  rm -f *.par *.tar
	  mkdir MPRAGE FLAIR SURVEY T2w DTI fMRI B08MS B09MS B1MAP ASL ASLM0 VASO MT qT115 qT160 DET2
	  for seqname in MPRAGE FLAIR SURVEY T2w DTI fMRI B08MS B09MS B1MAP ASL ASLM0 VASO MT qT115 qT160 DET2; do
	    gzip     *${seqname}.*
	    mvtarget=`ls *${seqname}.*`
	    mv ${mvtarget} ${seqname}/
	  done
          #	handle exception	
	  if [ -f *MPRAGE_float.nii.gz ]
	  then
	    mv *MPRAGE_float.nii.gz MPRAGE/
	  fi
	fi
}

# this function contains the data definition for the Kirkby dataset 
f_kirkby_unpack () {
clear

# These three arrays contain the information about which subjects ID's are related to which session numbers. S1 holds the first session, s2 the second.
declare -a id=(849 934 679 906 913 142 127 502 422 815 239 916 959 814 505 492 800 656 113 742 346)
declare -a s1=(01 02 03 04 05 06 07 08 09 10 12 13 14 15 16 18 23 28 30 32 39)
declare -a s2=(25 37 22 11 31 20 34 29 42 21 19 24 17 26 35 38 27 40 33 36 41)
echo BUG -- need to fix this reconstruction s.t. we check nsubjects equals to nsessions ... 
echo this information should be in a file 

time_start=`date +%s`
# main
cd ${datahome}
# setting up 21 folders with 2 sessions each; source data will be stored in nifti dir
j=0
nsub=${#id[@]}
for ((i = 1; i <= $nsub ; i++))
do
	echo
	if [[ -s "KKI2009-${s1[${j}]}".tar.bz2  ]] &&  [[ -s "KKI2009-${s2[${j}]}".tar.bz2  ]] ; then 
	echo "Subject ${i} of $nsub. ID = ${id[${j}]}" 	
	mkdir -p ${id[${j}]}/session_01/nifti
 	mkdir -p ${id[${j}]}/session_02/nifti
	echo "KKI2009-${s1[${j}]}"
	echo "KKI2009-${s2[${j}]}"
	cp "KKI2009-${s1[${j}]}".tar.bz2 ${id[${j}]}/session_01/nifti
	cp "KKI2009-${s2[${j}]}".tar.bz2 ${id[${j}]}/session_02/nifti
	cd ${id[${j}]}/session_01/nifti
	echo
	echo "Subject ${i} of $nsub. ID = ${id[${j}]} session 1"
	unpackKirkbyData "KKI2009-${s1[${j}]}"
	cd ../../session_02/nifti
	echo
	echo "Subject ${i} of $nsub. ID = ${id[${j}]} session 2"
	unpackKirkbyData "KKI2009-${s2[${j}]}"
	fi # check if data exists
	cd ${datahome}
	let j++
done	 

time_end=`date +%s`
time_elapsed=$((time_end - time_start))

echo
echo "--------------------------------------------------------------------------------------"
echo " Done unpacking Kirkby dataset"
echo " Script executed in $time_elapsed seconds"
echo " $(( time_elapsed / 3600 ))h $(( time_elapsed %3600 / 60 ))m $(( time_elapsed % 60 ))s"
echo "--------------------------------------------------------------------------------------"

subjects=`ls -d */ | xargs -l basename`

echo
echo "--------------------------------------------------------------------------------------"
echo " Please rerun `basename $0` to continue processing the evaluation dataset"
echo "--------------------------------------------------------------------------------------"
exit 0

}
#############################################################
# FMRIB registration functions
#############################################################

fsl_motion_correct () {
clear
echo "applying motion correction"
}

fsl_brain_extract () {
clear
echo "applying brain extraction"
}

fsl_4D_template () {
clear
echo "creating brain template from time-series"
}

fsl_SSBT () {
clear
echo "creating group brain template from time-series"
}

fsl_SSBT_transform () {
clear
echo "applying transformation to time-series"
}

fsl_ANTSR_stats () {
clear
echo "placeholder for stats options"
}


#############################################################
# ANTS registration functions
#############################################################

ants_motion_correct () {
clear
echo "applying motion correction"
}

ants_brain_extract () {
clear
echo "applying brain extraction"
}

ants_4D_template_moco () {
clear
echo "estimating 4D template using ants_moco"
}

ants_4D_template_btp () {
clear
pipelinedir=${framework}
S1GT=${resultshome}/${pipelinedir}/02_grp_template/session_01
S2GT=${resultshome}/${pipelinedir}/02_grp_template/session_02
mkdir -p $S1GT $S2GT

echo "creating brain template from time-series"
for currentsubject in ${subjects}
do

echo
echo "--------------------------------------------------------------------------------------"
echo " Start to build template(s) for subject: ${currentsubject}"
echo "--------------------------------------------------------------------------------------"

#create func averages
cd ${datahome}/${currentsubject}/session_01/nifti/fMRI/
if [ -s KKI*.nii.gz ]
then
${ANTSPATH}buildtemplateparallel.sh -d 4 -o ${currentsubject} $btp_params *.nii.gz >> ${resultshome}/ants_buildlog.txt
else 
echo "no file present in this directory; skipping to next"
fi

cd ${datahome}/${currentsubject}/session_02/nifti/fMRI/
if [ -s KKI*.nii.gz ]
then
${ANTSPATH}buildtemplateparallel.sh -d 4 -o ${currentsubject} $btp_params *.nii.gz >> ${resultshome}/ants_buildlog.txt
else 
echo "no file present in this directory; skipping to next"
fi
done

# Move individual subject templates to GrpBoldTemplate folders in ${resultshome}
for currentsubject in ${subjects}
do
mv ${datahome}/${currentsubject}/session_01/nifti/fMRI/${currentsubject}template.nii.gz $S1GT
mv ${datahome}/${currentsubject}/session_02/nifti/fMRI/${currentsubject}template.nii.gz $S2GT
cp $S1GT/${currentsubject}template.nii.gz ${resultshome}/${pipelinedir}/01_singlesub_template/session_01/
cp $S2GT/${currentsubject}template.nii.gz ${resultshome}/${pipelinedir}/01_singlesub_template/session_02/
done

}

ants_SSBT () {
clear
pipelinedir=${framework}
S1GT=${resultshome}/${pipelinedir}/02_grp_template/session_01
S2GT=${resultshome}/${pipelinedir}/02_grp_template/session_02
#mkdir -p $S1GT $S2GT

echo
echo "--------------------------------------------------------------------------------------"
echo " Start to build group template(s) for subjects: ${subjects}". 
echo "--------------------------------------------------------------------------------------"

cd $S1GT
buildtemplateparallel.sh -d 3 $btp_params_group -o session_01_  *.nii.gz >> ${resultshome}/ants_buildlog.txt

cd $S2GT
buildtemplateparallel.sh -d 3 $btp_params_group -o session_02_  *.nii.gz >> ${resultshome}/ants_buildlog.txt

}

ants_SSBT_transform () {
clear
pipelinedir=${framework}
S1GT=${resultshome}/${pipelinedir}/02_grp_template/session_01/
S2GT=${resultshome}/${pipelinedir}/02_grp_template/session_02/

echo ${subjects}

echo
echo "--------------------------------------------------------------------------------------"
echo " Applying transformation to time-series data.  "
echo "--------------------------------------------------------------------------------------"

for currentsubject in ${subjects}
do

# need to exclude dirs that contain the group templates. This can be achieved by running WarpTimeSeriesImageMultiTransform only in dirs with 3 charachters as a name, 
# which is true for all subjects dirs and not true for all non-subject dirs.

stringlength=${#currentsubject}
if [ ${stringlength} -eq 3 ]
  then 
  echo
  echo "--------------------------------------------------------------------------------------"
  echo " Session 1, Subject: ${currentsubject}"
  echo "--------------------------------------------------------------------------------------"

  WarpTimeSeriesImageMultiTransform 4 ${datahome}/${currentsubject}/session_01/nifti/fMRI/KKI2009*.nii.gz ${datahome}/${currentsubject}/session_01/nifti/fMRI/${currentsubject}_session_01_2SST.nii.gz -R ${S1GT}session_01_template.nii.gz ${S1GT}*${currentsubject}templateWarp.nii.gz ${S1GT}*${currentsubject}templateAffine.txt >> ${resultshome}/ants_applytransform.txt

  echo
  echo "--------------------------------------------------------------------------------------"
  echo " Transformed data saved as: "
  echo " ${datahome}/${currentsubject}/session_01/nifti/fMRI/${currentsubject}_session_01_2SST.nii.gz"
  echo "--------------------------------------------------------------------------------------"

  echo
  echo "--------------------------------------------------------------------------------------"
  echo " Session 2, Subject: ${currentsubject}"
  echo "--------------------------------------------------------------------------------------"

  if [ -s  ${S2GT}session_02_template.nii.gz ] ; then 
    WarpTimeSeriesImageMultiTransform 4 ${datahome}/${currentsubject}/session_02/nifti/fMRI/KKI2009*.nii.gz ${datahome}/${currentsubject}/session_02/nifti/fMRI/${currentsubject}_session_02_2SST.nii.gz -R  ${S2GT}session_02_template.nii.gz ${S2GT}*${currentsubject}templateWarp.nii.gz ${S2GT}*${currentsubject}templateAffine.txt >> ${resultshome}/ants_applytransform.txt
  fi 
  echo
  echo "--------------------------------------------------------------------------------------"
  echo " Transformed data saved as: "
  echo " ${datahome}/${currentsubject}/session_02/nifti/fMRI/${currentsubject}_session_02_2SST.nii.gz"
  echo "--------------------------------------------------------------------------------------"
fi

done

}

ants_ANTSR_stats () {
clear
pipelinedir=${framework}
echo "placeholder for stats options"
downloadAtlasData
cd ${resultshome}/${pipelinedir}/



# this code is very specific for the KIKBY datset
for ses in 1 2
do
  for currentsubject in ${subjects}
  do
  echo
  echo "--------------------------------------------------------------------------------------"
  echo " Preparing CompCorr for subjects: ${currentsubject}, session ${ses}"
  echo "--------------------------------------------------------------------------------------"
  cp 01_singlesub_template/session_0${ses}/${currentsubject}template.nii.gz 03_CompCorr/session_0${ses}/
  cd ${resultshome}/${pipelinedir}/03_CompCorr/session_0${ses}/
  ants_gm_mask.sh -i ${currentsubject}template.nii.gz -a ${atlaspath}/HarvardOxford-cort-maxprob-thr50-2mm.nii.gz -l 29 
  cd ${resultshome}/${pipelinedir}/
  done
done

cd ${resultshome}/${pipelinedir}/

#Run CompCorr
for ses in 1 2
do
  for currentsubject in ${subjects}
  do  
  echo "--------------------------------------------------------------------------------------"
  echo " Running CompCorr for subjects: ${currentsubject}, session ${ses}"
  echo "--------------------------------------------------------------------------------------"
  ImageMath 4 03_CompCorr/session_0${ses}/${currentsubject}CC.nii.gz CompCorr ${datahome}/${currentsubject}/session_0${ses}/nifti/fMRI/${currentsubject}_session_0${ses}_2SST.nii.gz 03_CompCorr/session_0${ses}/${currentsubject}template_gm_fast_roi.nii.gz 5 >> ${resultshome}/compcorr.txt
  done
done

cd ${resultshome}/${pipelinedir}/

# DiceOverlap
cd 04_ImageComparisonStats/DiceOverlap/
echo -e "ID \t Label_1_DICE \t  RO \t TP1 \t TP2 \t AvgDice " >>test-retest.txt
lo=0.1
for currentsubject in ${subjects}
do
  echo "--------------------------------------------------------------------------------------"
  echo " Subject ${currentsubject}, test-retest analysis  "
  echo "--------------------------------------------------------------------------------------"
  echo
  SmoothImage 3 ${resultshome}/${pipelinedir}/03_CompCorr/session_01/${currentsubject}CCfirst_evec.nii.gz 1. ${currentsubject}CCtemp1.nii.gz
  SmoothImage 3 ${resultshome}/${pipelinedir}/03_CompCorr/session_02/${currentsubject}CCfirst_evec.nii.gz 1. ${currentsubject}CCtemp2.nii.gz

#  antsaffine.sh 3 ${resultshome}/CompCorr_ANTS_testretest/${currentsubject}CCtemp1.nii.gz ${resultshome}/CompCorr_ANTS_testretest/${currentsubject}CCtemp2.nii.gz ${currentsubject}CCtemp2
#  antsIntroduction.sh -d 3 -r ${resultshome}/CompCorr_ANTS_testretest/${currentsubject}CCtemp1.nii.gz -i ${resultshome}/CompCorr_ANTS_testretest/${currentsubject}CCtemp2.nii.gz -o ${currentsubject}CCtemp2 -t RA 
  flirt -in ${resultshome}/${pipelinedir}/01_singlesub_template/session_02/${currentsubject}template.nii.gz -ref ${resultshome}/${pipelinedir}/01_singlesub_template/session_01/${currentsubject}template.nii.gz -out reg_ses2_ses1_${currentsubject}.nii.gz -omat reg_ses2_ses1_${currentsubject}.mat -bins 256 -cost corratio -searchrx 0 0 -searchry 0 0 -searchrz 0 0 -dof 12 -interp trilinear
  flirt -in ${currentsubject}CCtemp2.nii.gz -ref ${currentsubject}CCtemp1.nii.gz -applyxfm -init reg_ses2_ses1_${currentsubject}.mat -out reg_${currentsubject}CCtemp2.nii.gz
  mv reg_${currentsubject}CCtemp2.nii.gz ${currentsubject}CCtemp2.nii.gz

  ImageMath 3 ${currentsubject}CCtemp1b.nii.gz abs ${currentsubject}CCtemp1.nii.gz
  ImageMath 3 ${currentsubject}CCtemp2b.nii.gz abs ${currentsubject}CCtemp2.nii.gz

  ThresholdImage 3 ${currentsubject}CCtemp1b.nii.gz ${currentsubject}CCtemp1b.nii.gz ${lo} 99
  ThresholdImage 3 ${currentsubject}CCtemp2b.nii.gz ${currentsubject}CCtemp2b.nii.gz ${lo} 99

  ImageMath 3 tmp.txt DiceAndMinDistSum ${currentsubject}CCtemp1b.nii.gz ${currentsubject}CCtemp2b.nii.gz
  
  # write DiceAndMinDistSum results to tab delemited file
  DICE=`cat tmp.txt | grep DICE | cut -d " " -f 5`
  RO=`cat tmp.txt | grep DICE | cut -d " " -f 8`
  TP1=`cat tmp.txt | grep DICE | cut -d " " -f 10`
  TP2=`cat tmp.txt | grep DICE | cut -d " " -f 12`
  AvgDice=`cat tmp.txt | grep AvgDice | cut -d " " -f 5`
  echo -e "${currentsubject} \t  ${DICE} \t ${RO} \t ${TP1} \t ${TP2} \t ${AvgDice}" >>test-retest.txt
  rm tmp.txt
#  rm *tmp.*
  rm *tmp*.*
done

cd ${resultshome}/${pipelinedir}/

# run one sample t-test
echo "--------------------------------------------------------------------------------------"
echo " Run a one sample t-test"
echo "--------------------------------------------------------------------------------------"
echo
for ses in 1 2 
do
  cp 02_grp_template/session_0${ses}/session_0${ses}_template.nii.gz 04_ImageComparisonStats/OneSampleT_Test/session_0${ses}/
  cd 04_ImageComparisonStats/OneSampleT_Test/session_0${ses}/
  ants_gm_mask.sh -i session_0${ses}_template.nii.gz -a ${atlaspath}/HarvardOxford-cort-maxprob-thr50-2mm.nii.gz -l 29
  cd ${resultshome}/${pipelinedir}/

  for currentsubject in ${subjects}
  do
  echo "--------------------------------------------------------------------------------------"
  echo " processing ${currentsubject}"
  echo "--------------------------------------------------------------------------------------"
  echo
    cp ${resultshome}/${pipelinedir}/03_CompCorr/session_0${ses}/${currentsubject}CCfirst_evec.nii.gz ${resultshome}/${pipelinedir}/04_ImageComparisonStats/OneSampleT_Test/session_0${ses}/${currentsubject}CCfirst_evec.nii.gz 
    echo -e "${resultshome}/${pipelinedir}/04_ImageComparisonStats/OneSampleT_Test/session_0${ses}/${currentsubject}CCfirst_evec.nii.gz" >> ${resultshome}/${pipelinedir}/04_ImageComparisonStats/OneSampleT_Test/session_0${ses}/subjects.txt
  done

  cd 04_ImageComparisonStats/OneSampleT_Test/session_0${ses}/
  antsr_voxelwise_ttest.R ${ANTSPATH}ImageMath ${resultshome}/${pipelinedir}/04_ImageComparisonStats/OneSampleT_Test/session_0${ses}/session_0${ses}_template_gm_fast.nii.gz TTEST subjects.txt
  cd ${resultshome}/${pipelinedir}/
done

cd ${resultshome}/${pipelinedir}/

# run paired sample t-test
echo "--------------------------------------------------------------------------------------"
echo " Run a paired samples t-test"
echo "--------------------------------------------------------------------------------------"
echo
for ses in 1 2 
do

  for currentsubject in ${subjects}
  do
  cp ${resultshome}/${pipelinedir}/04_ImageComparisonStats/OneSampleT_Test/session_0${ses}/${currentsubject}CCfirst_evec.nii.gz ${resultshome}/${pipelinedir}/04_ImageComparisonStats/PairedSamplesT_Test/session_0${ses}_${currentsubject}CCfirst_evec.nii.gz 
 
  if [ ${ses} -eq 1  ]
  then
  echo -e "${resultshome}/${pipelinedir}/04_ImageComparisonStats/PairedSamplesT_Test/session_0${ses}_${currentsubject}CCfirst_evec.nii.gz" >> ${resultshome}/${pipelinedir}/04_ImageComparisonStats/PairedSamplesT_Test/subjects1.txt
  else
  echo -e "${resultshome}/${pipelinedir}/04_ImageComparisonStats/PairedSamplesT_Test/session_0${ses}_${currentsubject}CCfirst_evec.nii.gz" >> ${resultshome}/${pipelinedir}/04_ImageComparisonStats/PairedSamplesT_Test/subjects2.txt
  fi
  done
done
  
cp 04_ImageComparisonStats/OneSampleT_Test/session_01/session_01_template_gm_fast.nii.gz 04_ImageComparisonStats/PairedSamplesT_Test/
cd 04_ImageComparisonStats/PairedSamplesT_Test/
antsr_voxelwise_ttest.R ${ANTSPATH}ImageMath session_01_template_gm_fast.nii.gz TTEST subjects1.txt subjects2.txt

cd ${resultshome}/${pipelinedir}/


}

#############################################################
# FMRIB registration menu
#############################################################
fsl_menu () {
clear
framework=fsl
f_setup_results_dirs ${framework}

while : # Loop forever
do
cat <<MENU
-------------------------------------------------------------
ANTS Study Specific BOLD Template Evaluation Suite
-------------------------------------------------------------
This is the FSL image procssing framework. The steps below 
should all be performed in the indicated order. Some optional 
steps may be skipped.

1. Motion Correct time-series (optional)
2. Brain Extract time-series (optional)
3. Create template from time-series per session
4. Create Group templates per session
5. Apply step 4 transformation to time-series data
6. Demo Statistics
7. Back to Main Menu

-------------------------------------------------------------
Written by Brian Avants & Niels van Strien, 2011
-------------------------------------------------------------
MENU

echo -n " Your choice? : "
read choice

case $choice in
1) fsl_motion_correct ;;
2) fsl_brain_extract ;;
3) fsl_4D_template ;;
4) fsl_SSBT ;;
5) fsl_SSBT_transform ;;
6) fsl_ANTSR_stats ;;
7) main_menu ;;
*) echo "\"$choice\" is not valid "; sleep 2 ;;
esac
done
}

#############################################################
# Ants registration menu
#############################################################
ants_menu () {
clear
framework=ants
f_setup_results_dirs ${framework}

while : # Loop forever
do
cat <<MENU
-------------------------------------------------------------
ANTS Study Specific BOLD Template Evaluation Suite
-------------------------------------------------------------
This is the ANTS image procssing framework. The steps below 
should all be performed in the indicated order. Some optional 
steps may be skipped.

1. Motion Correct time-series (optional)
2. Brain Extract time-series (optional)
3. Create template from time-series per session
4. Create Group templates per session
5. Apply step 4 transformation to time-series data
6. Demo Statistics
7. Back to Main Menu

-------------------------------------------------------------
Written by Brian Avants & Niels van Strien, 2011
-------------------------------------------------------------
MENU

echo -n " Your choice? : "
read choice

case $choice in
1) ants_motion_correct ;;
2) ants_brain_extract  ;;
3) ants_4D_template_btp ${framework} ;;
4) ants_SSBT ${framework} ;;
5) ants_SSBT_transform ${framework} ;;
6) ants_ANTSR_stats ${framework} ;;
7) main_menu ;;
*) echo "\"$choice\" is not valid "; sleep 2 ;;
esac
done
}

#############################################################
# Data download and unpack menu
#############################################################
unpack_menu () {
clear
while : # Loop forever
do
cat <<MENU
-------------------------------------------------------------
ANTS Study Specific BOLD Template Evaluation Suite
-------------------------------------------------------------
The unpacked Kirkby dataset is not available in: 
${datahome} 

In case you did not download the Kirkby dataset yet, run 
option 1 first. In case you downloaded the dataset, but did 
not unpack it yet, run option 2. If you already unpacked 
the dataset, check your dependencies.sh file to see if the 
datahome variable points to the correct location.

1. Download Kirkby dataset from NITRC using curl
2. Unpack and organize Kirkby data
3. Exit

NB: Downloading and unpacking 8.5 GB of data may take a while. 
Make sure to have sufficient disk space and patience.
-------------------------------------------------------------
Written by Brian Avants & Niels van Strien, 2011
-------------------------------------------------------------

MENU

echo -n " Your choice? : "
read choice

case $choice in
1) downloadKirkbyData ;;
2) f_kirkby_unpack ;;
3) exit ;;
*) echo "\"$choice\" is not valid "; sleep 2 ;;
esac
done
}

#############################################################
# Main Menu
#############################################################
main_menu () {
clear
while : # Loop forever
do
cat <<MENU
-------------------------------------------------------------
ANTS Study Specific BOLD Template (SSBT) Evaluation Suite
-------------------------------------------------------------
You can create a SSBT using ANTS or using the FSL toolsuite.
If you calculate both approaches, option 3 allows you to 
statistically compare the results.

1. Select ANTS registration Framework
2. Select FMRIB (FSL) registration Framework
3. Compare approach 1 and 2.
4. Autorun steps 1 - 3 (can take more than 48 h to complete).
5. Exit

-------------------------------------------------------------
Written by Brian Avants & Niels van Strien, 2011
-------------------------------------------------------------
MENU

echo -n " Your choice? : "
read choice

case $choice in
1) ants_menu ;;
2) fsl_menu ;;
3) echo "Option under development" ;;
4) echo "Option under development" ;;
5) exit ;;
*) echo "\"$choice\" is not valid "; sleep 2 ;;
esac
done
}

#############################################################
# Script starts running below this point
#############################################################
source $1

# create a list of subjects takes into account all directory names, so don't make custom dirs in datahome
if [ -d ${datahome}/ ]; then
cd ${datahome}
#subjects=`ls -d */ | xargs -l basename`
subjects=`find * -prune -type d`
subarray=(`echo $subjects | tr " " "\n"`) # now it is a real array
fi

# if no subject data exists in datahome, then show a menu to download and unpack the kirkby data
# otherwise show the main processing menu
if [ ${#subarray[@]} == 0 ]
then
unpack_menu
else
main_menu
fi
