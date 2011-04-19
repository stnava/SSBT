#!/bin/bash
if [ $# -lt 1 ] ; then 
 echo usage:
 echo $0 path_to_dependencies.sh 
 echo e.g.:
 echo $0 /home/me/kirby/scripts/dependencies.sh 
 exit
fi 

# set this dir to the path where the dependencies.sh script is stored.
source $1

# The rest should be automatic if you used organize_data.sh to unpack the original kirkby dataset.
time_start=`date +%s`

# trap keyboard interrupt (control-c)
trap control_c SIGINT

control_c()
# run if user hits control-c
{
  echo -en "\n*** User pressed CTRL + C ***\n"
  exit $?
  echo -en "\n*** Script cancelled by user ***\n"
}

cd ${datahome}

# create a list of subjects takes into account all directory names, so don't make custom dirs in datahome
# subjects=`ls -d */ | xargs -l basename` # did not work for me -- the -l option , not sure why
# for me, it doesn't work without -l. What are linux are you running? I am at CentOS 5.6. 
# subjects=`ls -d */ | xargs -l basename`
# Alternatives for the command above.
subjects=`find * -prune -type d`
echo $subjects 
echo
echo "--------------------------------------------------------------------------------------"
echo " Applying transformation to time-series data.  "
echo "--------------------------------------------------------------------------------------"

for currentsubject in ${subjects}
do

# need to exclude dirs that contain the group templates. This can be achieved by running WarpTimeSeriesImageMultiTransform only in dirs with 3 charachters as a name, which is true for all subjects dirs and not true for all non-subject dirs.

stringlength=${#currentsubject}
if [ ${stringlength} -eq 3 ] ; then 
echo
echo "--------------------------------------------------------------------------------------"
echo " Session 1, Subject: ${currentsubject}"
echo "--------------------------------------------------------------------------------------"

${ANTSPATH}WarpTimeSeriesImageMultiTransform 4 ${datahome}/${currentsubject}/session_01/nifti/fMRI/KKI2009*.nii.gz ${datahome}/${currentsubject}/session_01/nifti/fMRI/${currentsubject}_session_01_2SST.nii.gz -R ${datahome}/session_01_GrpBoldTemplate/session_01_template.nii.gz ${datahome}/session_01_GrpBoldTemplate/*${currentsubject}templateWarp.nii.gz ${datahome}/session_01_GrpBoldTemplate/*${currentsubject}templateAffine.txt

if [ -s ${datahome}/session_01_GrpBoldTemplate/session_01_group_template_rsfmri_mask.nii.gz ] ; then
${ANTSPATH}ImageMath 4 ${datahome}/${currentsubject}/session_01/nifti/fMRI/${currentsubject}_session_01_2SST.nii.gz CompCorr ${datahome}/${currentsubject}/session_01/nifti/fMRI/${currentsubject}_session_01_2SST.nii.gz  ${datahome}/session_01_GrpBoldTemplate/session_01_group_template_rsfmri_mask.nii.gz
fi 

echo
echo "--------------------------------------------------------------------------------------"
echo " Transformed data saved as: "
echo " ${datahome}/${currentsubject}/session_01/nifti/fMRI/${currentsubject}_session_01_2SST.nii.gz"
echo "--------------------------------------------------------------------------------------"

echo
echo "--------------------------------------------------------------------------------------"
echo " Session 2, Subject: ${currentsubject}"
echo "--------------------------------------------------------------------------------------"

WarpTimeSeriesImageMultiTransform 4 ${datahome}/${currentsubject}/session_02/nifti/fMRI/KKI2009*.nii.gz ${datahome}/${currentsubject}/session_02/nifti/fMRI/${currentsubject}_session_02_2SST.nii.gz -R ${datahome}/session_02_GrpBoldTemplate/session_02_template.nii.gz ${datahome}/session_02_GrpBoldTemplate/*${currentsubject}templateWarp.nii.gz ${datahome}/session_02_GrpBoldTemplate/*${currentsubject}templateAffine.txt

if [ -s ${datahome}/session_02_GrpBoldTemplate/session_02_group_template_rsfmri_mask.nii.gz  ] ; then
${ANTSPATH}ImageMath 4 ${datahome}/${currentsubject}/session_02/nifti/fMRI/${currentsubject}_session_02_2SST.nii.gz CompCorr ${datahome}/${currentsubject}/session_02/nifti/fMRI/${currentsubject}_session_02_2SST.nii.gz  ${datahome}/session_02_GrpBoldTemplate/session_02_group_template_rsfmri_mask.nii.gz
fi

echo
echo "--------------------------------------------------------------------------------------"
echo " Transformed data saved as: "
echo " ${datahome}/${currentsubject}/session_02/nifti/fMRI/${currentsubject}_session_02_2SST.nii.gz"
echo "--------------------------------------------------------------------------------------"
fi

done

time_end=`date +%s`
time_elapsed=$((time_end - time_start))

echo
echo "--------------------------------------------------------------------------------------"
echo " Done applying transformations to time-series data.  "
echo " Script executed in $time_elapsed seconds "
echo " $(( time_elapsed / 3600 ))h $(( time_elapsed %3600 / 60 ))m $(( time_elapsed % 60 ))s"
echo "--------------------------------------------------------------------------------------"


echo " `basename $0` executed in: $time_elapsed seconds; $(( time_elapsed / 3600 ))h $(( time_elapsed %3600 / 60 ))m $(( time_elapsed % 60 ))s" >> ${datahome}/benchmark.txt
