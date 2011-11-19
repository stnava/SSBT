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
# trap keyboard interrupt (control-c)
trap control_c SIGINT

control_c()
# run if user hits control-c
{
  echo -en "\n*** User pressed CTRL + C ***\n"
  exit $?
  echo -en "\n*** Script cancelled by user ***\n"
}

# this function unpacks the data and splits it up in subfolders
function unpackKirkbyData
{
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
for ((i = 1; i < 22 ; i++))
do
	echo
	echo "Subject ${i} of 21. ID = ${id[${j}]}"
	if [[ -s "KKI2009-${s1[${j}]}".tar.bz2  ]] &&  [[ -s "KKI2009-${s2[${j}]}".tar.bz2  ]] ; then 
	mkdir ${id[${j}]}
 	mkdir ${id[${j}]}/session_01
 	mkdir ${id[${j}]}/session_01/nifti
 	mkdir ${id[${j}]}/session_02
 	mkdir ${id[${j}]}/session_02/nifti
	echo "KKI2009-${s1[${j}]}"
	echo "KKI2009-${s2[${j}]}"
	cp "KKI2009-${s1[${j}]}".tar.bz2 ${id[${j}]}/session_01/nifti
	cp "KKI2009-${s2[${j}]}".tar.bz2 ${id[${j}]}/session_02/nifti
	cd ${id[${j}]}/session_01/nifti
	echo
	echo "Subject ${i} of 21. ID = ${id[${j}]} session 1"
	unpackKirkbyData "KKI2009-${s1[${j}]}"
	cd ../../session_02/nifti
	echo
	echo "Subject ${i} of 21. ID = ${id[${j}]} session 2"
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

echo " `basename $0` executed in: $time_elapsed seconds; $(( time_elapsed / 3600 ))h $(( time_elapsed %3600 / 60 ))m $(( time_elapsed % 60 ))s" >> ${datahome}/benchmark.txt
