#!/bin/bash

VERSION="0.0.01 test"

# trap keyboard interrupt (control-c)
trap control_c SIGINT

nargs=$#

control_c()
# run if user hits control-c
{
  echo -en "\n*** User pressed CTRL + C ***\n"
  cleanup
  exit $?
  echo -en "\n*** Script cancelled by user ***\n"
}

cleanup()
# example cleanup function
{
  
  cd ${currentdir}/

  echo -en "\n*** Performing cleanup, please wait ***\n"

# 1st attempt to kill all remaining processes
# put all related processes in array
  runningANTSpids=( `ps -C ANTS -C N4BiasFieldCorrection -C ImageMath| awk '{ printf "%s\n", $1 ; }'` )

# debug only
  #echo list 1: ${runningANTSpids[@]}

# kill these processes, skip the first since it is text and not a PID  
  for ((i = 1; i < ${#runningANTSpids[@]} ; i++)) 
  do
  echo "killing:  ${runningANTSpids[${i}]}"
  kill ${runningANTSpids[${i}]} 
  done
  
  return $?
}

# The rest should be automatic if you used organize_data.sh to unpack the original kirkby dataset.
time_start=`date +%s`

function setPath {
    cat <<SETPATH

--------------------------------------------------------------------------------------
Error locating ANTS
--------------------------------------------------------------------------------------
It seems that the ANTSPATH environment variable is not set. Please add the ANTSPATH 
variable. This can be achieved by editing the .bash_profile in the home directory. 
Add:

ANTSPATH=/home/yourname/bin/ants/

Or the correct location of the ANTS binaries.

Alternatively, edit this script ( `basename $0` ) to set up this parameter correctly. 

SETPATH
    exit 1
}

# Uncomment the line below in case you have not set the ANTSPATH variable in your environment.
# export ANTSPATH=${ANTSPATH:="$HOME/bin/ants/"} # EDIT THIS

#ANTSPATH=YOURANTSPATH
if [  ${#ANTSPATH} -le 3 ]
    then
    setPath >&2
fi

if [ ! -s ${ANTSPATH}/ANTS ] ; then 
  echo "ANTS program can't be found. Please (re)define \$ANTSPATH in your environment."
  exit
fi 

setFSLPath() {
    cat <<SETFSLPATH
--------------------------------------------------------------------------------------
Error locating FSL
--------------------------------------------------------------------------------------
The FSLDIR environment variable is not set. Please add the FSLDIR variable.

see the FSL website for more information about installation:

http://www.fmrib.ox.ac.uk/fsl/fsl/downloading.html

SETFSLPATH
#    exit 1
}

function Usage {
    cat <<USAGE

Usage: 

`basename $0` -i <input_image> -a <LabelImage> -l <label_value>

Compulsory arguments:

     -i:  input image to create grey matter mask for.
	  
     -o:  output image, i.e. the grey matter mask image.

Optional arguments:

     -a:  use a probabilistic atlas to label a roi in the grey matter mask. These
	  atlases are kindly provided as part of the FMRIB FSL software package.

     -l:  the value of the label in the probabilistic atlas to use for roi labeling.

--------------------------------------------------------------------------------------
ANTS was created by:
--------------------------------------------------------------------------------------
Brian B. Avants, Nick Tustison and Gang Song
Penn Image Computing And Science Laboratory
University of Pennsylvania

Please reference http://www.ncbi.nlm.nih.gov/pubmed/20851191 when employing this script
in your studies. A reproducible evaluation of ANTs similarity metric performance in 
brain image registration: 

* Avants BB, Tustison NJ, Song G, Cook PA, Klein A, Gee JC. Neuroimage, 2011.  

Also see http://www.ncbi.nlm.nih.gov/pubmed/19818860 for more details.  

The script has been updated and improved since this publication. 

--------------------------------------------------------------------------------------
script created by N.M. van Strien, http://www.mri-tutorial.com | NTNU MR-Center
--------------------------------------------------------------------------------------


USAGE
    exit 1
}

function ants_get_gm_mask {

N3BiasFieldCorrection 3 ${INPUT}.nii.gz ${INPUT}_bias.nii.gz 2
N3BiasFieldCorrection 3 ${INPUT}_bias.nii.gz ${INPUT}_bias.nii.gz 1 
ThresholdImage 3 ${INPUT}.nii.gz ${INPUT}_mask.nii.gz 2 999
Atropos -d 3 -i kmeans[5] -a ${INPUT}_bias.nii.gz -o ${INPUT}_seg.nii.gz -c [5,0] -m [0.15,1x1x1] -x ${INPUT}_mask.nii.gz

#generate brain outline mask using bet
bet2 ${INPUT} ${INPUT}_bet -m

#multiply atropos output with bet-brain mask.
ImageMath 3 ${INPUT}_seg.nii.gz m ${INPUT}_seg.nii.gz ${INPUT}_bet_mask.nii.gz

#threshold image 3 is wm and non-interest structures >4 is csf. This is a a bit of a guess.
fslmaths ${INPUT}_seg.nii.gz -thr 3 -uthr 4 ${INPUT}_gm.nii.gz

# make gm all 1
fslmaths ${INPUT}_gm.nii.gz -bin ${INPUT}_gm.nii.gz

#rm ${INPUT}_bet.nii.gz
rm ${INPUT}_bet_mask.nii.gz
rm ${INPUT}_bias.nii.gz
rm ${INPUT}_mask.nii.gz
rm ${INPUT}_seg.nii.gz

}

function fsl_get_gm_mask {

bet2 ${INPUT} ${INPUT}_bet -m

#susan ${INPUT}_bet 0.7 3 3 1 0 ${INPUT}_bet_susan
#mv ${INPUT}_bet_susan.nii.gz ${INPUT}_bet.nii.gz

fast -t 2 -n 3 -H 0.1 -I 4 -l 20.0 -g -O 10 -o ${INPUT}_bet ${INPUT}_bet
# Atropos -d 3 -i kmeans[3] -a ${INPUT}_bias.nii.gz -o ${INPUT}_seg.nii.gz -c [5,0] -m [0.1,1x1x1] -x ${INPUT}_mask.nii.gz

mv ${INPUT}_bet_seg_0.nii.gz ${INPUT}_gm_fast.nii.gz
#rm ${INPUT}_bet.nii.gz
rm ${INPUT}_bet_*.nii.gz

}

function fsl_label_gm_mask {

# Test availability of helper files 
# No need to test this more than once. Can reside outside of the main loop.
MNIEPI=${ANTSPATH}standard/EPI.nii

# for FLE in $MNIEPI
#   do 
#   if [ ! -x $FLE  ] ; 
#       then
#       echo
#       echo "--------------------------------------------------------------------------------------"
#       echo " FILE $FLE DOES NOT EXIST. You can obtain a copy as part of SPM 8.  "
#       echo " Store this file in ${ANTSPATH}standard/EPI.nii or modify this script.  "  
#       echo "--------------------------------------------------------------------------------------"
#       echo ""
#       exit 1
#   fi
# done


# This function labels the gm mask created in a previous step 

# calulate transformation from MNI EPI to SSBT
flirt -in ${ANTSPATH}standard/EPI.nii -ref ${INPUT}_bet.nii.gz -out EPI2SST_flirt.nii.gz -omat EPI2SST_flirt.mat -bins 256 -cost corratio -searchrx -180 180 -searchry -180 180 -searchrz -180 180 -dof 12  -interp trilinear

# cutout acc on from the probabilistic atlas
fslmaths ${PATLAS} -thr ${PATLAS_LABEL} -uthr ${PATLAS_LABEL} roi.nii.gz

# set mask value to 1
fslmaths roi.nii.gz -bin roi.nii.gz

flirt -in roi.nii.gz -ref ${INPUT}_bet.nii.gz -applyxfm -init EPI2SST_flirt.mat -out roi_2_${INPUT}.nii.gz

# set acc mask value to 1
fslmaths roi_2_${INPUT}.nii.gz -bin roi_2_${INPUT}.nii.gz

# set gm mask value to 1
fslmaths ${INPUT}_gm_fast.nii.gz -bin ${INPUT}_gm_fast.nii.gz
fslmaths ${INPUT}_gm_fast.nii.gz -add roi_2_${INPUT}.nii.gz ${INPUT}_gm_fast.nii.gz
fslmaths ${INPUT}_gm_fast.nii.gz -bin ${INPUT}_gm_fast.nii.gz
fslmaths ${INPUT}_gm_fast.nii.gz -add roi_2_${INPUT}.nii.gz ${INPUT}_gm_fast_roi.nii.gz

}

# reading command line arguments 
while getopts "a:i:h:o:l:" OPT 
  do 
  case $OPT in
      h) #help 
	  echo "$USAGE"
	  exit 0 
	  ;;
      i) #input image 
	  INPUT=$OPTARG
	  INPUT=`basename $INPUT | cut -d '.' -f 1 `
	  ;;
      a) #atlas image
	  PATLAS=$OPTARG 
	  ;;
      l) #atlas label
	  PATLAS_LABEL=$OPTARG 
	  ;;
      \?) # getopts issues an error message
      echo "$USAGE" >&2
      exit 1 
      ;;
  esac
done

# Provide different output for Usage and Help 
if [ $nargs -lt 2 ]
    then
    Usage >&2
fi

if [  ${#FSLDIR} -le 0 ]
    then
    setFSLPath >&2
fi

# main part of the script

#ants_get_gm_mask
fsl_get_gm_mask

if [ ${#PATLAS} -gt 0 ] && [ ${#PATLAS_LABEL} -gt 0 ]
    then
    fsl_label_gm_mask
fi


time_end=`date +%s`
time_elapsed=$((time_end - time_start))

echo
echo "--------------------------------------------------------------------------------------"
echo " Done creating: ${INPUT}_gm.nii.gz"
echo " Script executed in $time_elapsed seconds"
echo " $(( time_elapsed / 3600 ))h $(( time_elapsed %3600 / 60 ))m $(( time_elapsed % 60 ))s"
echo "--------------------------------------------------------------------------------------"

exit 0