#!/bin/bash
if [ $# -lt 1 ] ; then 
 echo usage:
 echo $0 path_to_dependencies.sh 
 echo e.g.:
 echo $0 /home/me/kirby/scripts/dependencies.sh 
 exit
fi 
# set this dir to the path where the data is stored (bzip files) and where it will be sorted and unpacked.
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
subjects=`find * -prune -type d`

mkdir ${datahome}/session_01_GrpBoldTemplate
mkdir ${datahome}/session_02_GrpBoldTemplate

echo
echo "--------------------------------------------------------------------------------------"
echo " Copying individual subject templates to GrpBoldTemplate folders in ${datahome}  "
echo "--------------------------------------------------------------------------------------"

for currentsubject in ${subjects}
do

cp ${datahome}/${currentsubject}/session_01/nifti/fMRI/${currentsubject}template.nii.gz ${datahome}/session_01_GrpBoldTemplate/
cp ${datahome}/${currentsubject}/session_02/nifti/fMRI/${currentsubject}template.nii.gz ${datahome}/session_02_GrpBoldTemplate/

done

echo
echo "--------------------------------------------------------------------------------------"
echo " Start to build group template for subjects: ${subjects}"
echo "--------------------------------------------------------------------------------------"

cd ${datahome}/session_01_GrpBoldTemplate
buildtemplateparallel.sh -d 3 -o session_01_ $btp_params_group *.nii.gz

cd ${datahome}/session_02_GrpBoldTemplate
buildtemplateparallel.sh -d 3 -o session_02_ $btp_params_group *.nii.gz

time_end=`date +%s`
time_elapsed=$((time_end - time_start))

echo
echo "--------------------------------------------------------------------------------------"
echo " Done creating group templates of session 01 and 02 of the fMRI Kirkby dataset"
echo " Script executed in $time_elapsed seconds"
echo " $(( time_elapsed / 3600 ))h $(( time_elapsed %3600 / 60 ))m $(( time_elapsed % 60 ))s"
echo "--------------------------------------------------------------------------------------"


echo " `basename $0` executed in: $time_elapsed seconds; $(( time_elapsed / 3600 ))h $(( time_elapsed %3600 / 60 ))m $(( time_elapsed % 60 ))s" >> ${datahome}/benchmark.txt
