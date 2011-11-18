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
# subjects=`ls -d */ | xargs -l basename` # did not work for me -- the -l option , not sure why
 subjects=`find * -prune -type d`

# debug
#echo $subjects
#exit

for currentsubject in ${subjects}
do

echo
echo "--------------------------------------------------------------------------------------"
echo " Start to build template fo subject: ${currentsubject}"
echo "--------------------------------------------------------------------------------------"

#create func averages
cd ${datahome}/${currentsubject}/session_01/nifti/fMRI/
if [ -f *.nii.gz ]
then
${ANTSPATH}/buildtemplateparallel.sh -d 4 -o ${currentsubject} $btp_params *.nii.gz 
else 
echo "no file present in this directory; skipping to next"
fi

cd ${datahome}/${currentsubject}/session_02/nifti/fMRI/
if [ -f *.nii.gz ]
then
${ANTSPATH}buildtemplateparallel.sh -d 4 -o ${currentsubject} $btp_params *.nii.gz
else 
echo "no file present in this directory; skipping to next"
fi

done

time_end=`date +%s`
time_elapsed=$((time_end - time_start))

echo
echo "--------------------------------------------------------------------------------------"
echo " Done creating templates of 4D timeseries Kirkby dataset"
echo " Script executed in $time_elapsed seconds"
echo " $(( time_elapsed / 3600 ))h $(( time_elapsed %3600 / 60 ))m $(( time_elapsed % 60 ))s"
echo "--------------------------------------------------------------------------------------"


echo " `basename $0` executed in: $time_elapsed seconds; $(( time_elapsed / 3600 ))h $(( time_elapsed %3600 / 60 ))m $(( time_elapsed % 60 ))s" >> ${datahome}/benchmark.txt
