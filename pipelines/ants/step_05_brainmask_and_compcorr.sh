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

function persubjectscompcorr {
usage=" $0  subject_id session "
if [[ ${#1} -lt 1 ]] || [[ ${#2} -lt 1 ]] ; then 
 echo usage 
 echo $usage
 echo your arg 1 is $1 
 echo your arg 2 is $2
 exit 1
fi 
ID=$2
session=$3
IMG=${ID}template.nii.gz
SST=${ID}_${session}_2SST.nii.gz
if [[ ! -s $IMG ]] || [[ ! -s $SST ]] ; then 
  echo $IMG or $SST does not exist, exiting
  exit 1
fi 
BM=${ID}_${session}brainmask.nii.gz
if [ ! -s $BM ] ; then 
  ThresholdImage 3 $IMG $BM 2 9999   
  ImageMath 3 $BM ME $BM 1 
  ImageMath 3 $BM GetLargestComponent $BM 
  ImageMath 3 $BM MD $BM  1
fi  
if [ ! -s ${ID}out_corrected.nii.gz ] ; then 
  ImageMath 4 ${ID}out.nii.gz CompCorrAuto $SST $BM 6
fi 
if [ ! -s ${ID}seg.nii.gz ] ; then 
  Atropos -d 3 -a $IMG -a ${ID}out_variance.nii.gz -m [0.1,1x1x0] -o ${ID}seg.nii.gz -c [5,0] -i kmeans[3] -x $BM
  ThresholdImage 3 ${ID}seg.nii.gz ${ID}cortmask.nii.gz 2 2
fi 
if [[ -s ${ID}cortmask.nii.gz ]] && [[ -s ${ID}out_corrected.nii.gz ]] ; then 
  $SCCAN --timeseriesimage-to-matrix [$SST,${ID}cortmask.nii.gz, 1.5 , 10.0 ] -o ${ID}.csv
  if [[ -s roimask.nii.gz ]] ; then 
    ImageMath 4 ${ID}_roi.nii.gz CompCorrAuto $SST roimask.nii.gz 1
    rm ${ID}_roi_corrected.nii.gz ${ID}_roi_variance.nii.gz
  fi 
# you could also use svd 
  $SCCAN --sparse-svd [${ID}.csv,${ID}cortmask.nii.gz,-0.5] -n 5 -i 30 --PClusterThresh 50  -o ${ID}RSF_Networks.nii.gz 
fi 

}


# begin main functionality 
#
cd ${datahome}
# create a list of subjects takes into account all directory names, so don't make custom dirs in datahome
subjects=`find * -prune -type d`
for sess in session_01 session_02 ; do 
  for sub in $subjects ; do 
    cd ${datahome}
    cd ${datahome}/$sub/$sess/nifti/fMRI/
    persubjectscompcorr $1 $sub $sess
  done 
done
