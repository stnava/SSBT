#!/bin/bash
# set this dir to the path where the data is stored (bzip files) and where it will be sorted and unpacked.
datahome=/home/niels/experiments/kirkby/
datahome=/Users/brianavants/Data/Kirby/
# path to ANTs binaries 
ANTSPATH=/Users/brianavants/code/bin/ants/
# you need to copy the buildtemplateparallel and antsIntroduction scripts to your ants bin directory 
# 
# parallelization parameters --- see buildtemplate parallel help section
# these parameters are from niels original script --- uses defaults for -m options
btp_params=" -c 2 -j 8 -i 2  " 
# these parameters are updated to do a (mostly) affine space template and use serial registrations
btp_params=" -c 0  -i 2 -m 1 " 
