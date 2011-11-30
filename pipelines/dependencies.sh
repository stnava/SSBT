#!/bin/bash
# set this dir to the path where the input (e.g. test_data) data is stored (bzip files)
analysishome=/Users/stnava/data/kirby/
datahome=${analysishome}test_data
#  set this dir to the location of the 4D single subject and group template & other results 
resultshome=/Users/stnava/data/kirby/data_organized
#  set this dir to the ants output within the resultshome directory
pipelinedir=ants_ssbt

# path to sccan code ---  move to ants ?
SCCAN=${ANTSPATH}sccan
# path to ANTs binaries 
#ANTSPATH=/Users/brianavants/code/bin/ants/

# you need to copy the buildtemplateparallel and antsIntroduction scripts to your ants bin directory 
# 
# parallelization parameters --- see buildtemplate parallel help section
# these parameters are from niels original script --- uses defaults for -m options
btp_params=" -c 0 -j 1 -i 2 -m 100x50 " 

# parameters for testing 
btp_params=" -c 0 -j 1 -i 1 -m 10x1 " 

# parameters for testing group template creation 
btp_params_group=" -c 0 -j 1 -i 2 -m 30x5x1 " 
