#!/bin/bash

test_path () {
test_loc=`dirname ${choice}`
if [ ! -w ${test_loc} ]
then
echo "\"$test_loc\" is not a writable location "
sleep 1 
return 0
fi
}

test_path_exist () {
echo "test path"

if [ -d ${choice} ]
then
  clear
  echo "${choice}"
  echo "This folder exists already. Overwrite (y/n)? This will destroy all data."
  read overwrite
    if [ ${overwrite} == "y" ]
    then
    echo " "
    echo "Are you sure you want to delete this folder and all of its contents (y/n)?"
    read overwrite
      if [ ${overwrite} == "y" ]
      then
	rm -rf ${choice}
	return 1
      else
      return 0
      fi
    else
    return 0
    fi
else 
return 1
fi
}

cfg_check () {
cfgtmp=~/.antsr

if [ -d ${cfgtmp} ]; 
then
  if [ -f ${cfgtmp}/antsr_cfg.sh ]; 
  then
  echo "An old configuration file exists. Overwrite (y/n)?"
  read overwrite
    if [ ${overwrite} == "y" ]
    then
    rm -f ${cfgtmp}/antsr_cfg.sh
    elif [ ${overwrite} == "n" ]
    then
    echo "Script exited. Manually (re)move ${cfgtmp}/antsr_cfg.sh"
    exit
    fi
  fi
else
    mkdir ${cfgtmp}
fi
}

wiz_01_proc (){
echo " ">> ${cfgtmp}/antsr_cfg.sh
echo "# experiment path" >> ${cfgtmp}/antsr_cfg.sh
echo "exp_path=${choice}" >> ${cfgtmp}/antsr_cfg.sh
wiz_02
}

wiz_02_proc (){
echo " ">> ${cfgtmp}/antsr_cfg.sh
echo "# number of sessions" >> ${cfgtmp}/antsr_cfg.sh
echo "ses=${choice}" >> ${cfgtmp}/antsr_cfg.sh
wiz_03
}

wiz_03_proc (){
echo " ">> ${cfgtmp}/antsr_cfg.sh
echo "# number of runs" >> ${cfgtmp}/antsr_cfg.sh
echo "runs=${choice}" >> ${cfgtmp}/antsr_cfg.sh
wiz_04
}

wiz_04_proc (){
echo " ">> ${cfgtmp}/antsr_cfg.sh
chmod + x ${cfgtmp}/antsr_cfg.sh
source ${cfgtmp}/antsr_cfg.sh

if [ ${choice} == "y" ]
    then
    echo "# resultshome" >> ${cfgtmp}/antsr_cfg.sh
    echo "resultshome=${exp_path}/results" >> ${cfgtmp}/antsr_cfg.sh
    else
    echo "# resultshome" >> ${cfgtmp}/antsr_cfg.sh
    echo "resultshome=${choice}" >> ${cfgtmp}/antsr_cfg.sh
fi
wiz_05
}

wiz_05_proc (){
if [ ${choice} == "y" ]
    then
    mkdir -p ${resultshome}
    mkdir -p ${exp_path}/scripts
    cp ${cfgtmp}/antsr_cfg.sh ${exp_path}/scripts/dependencies.sh
    chmod +x ${exp_path}/scripts/dependencies.sh 
    source ${exp_path}/scripts/dependencies.sh
    for ((i = 1; i <= ${ses} ; i++))
    do
      if [ ${i} -lt 10 ]
      then
	for ((j = 1; j <= ${runs} ; j++))
	do
	if [ ${j} -lt 10 ]
	then
	mkdir -p ${exp_path}/data/session_0${i}/run_0${j}
	else
	mkdir -p ${exp_path}/data/session_0${i}/run_${j}
	fi
	done
      else 
	for ((j = 1; j <= ${runs} ; j++))
	do
	if [ ${j} -lt 10 ]
	then
	mkdir -p ${exp_path}/data/session_${i}/run_0${j}
	else
	mkdir -p ${exp_path}/data/session_${i}/run_${j}
	fi
	done
      fi
    done

    rm -rf ${cfgtmp}/
    store_instructions
    else
    rm -rf ${cfgtmp}/
    data_menu
fi
}

wiz_01 () {
clear

while : # Loop forever
do
cat <<MENU
-------------------------------------------------------------------------------
ANTS functional MRI data processing pipeline - Data wizard 1/5
-------------------------------------------------------------------------------

This script will create a new folder structure to store the data and results of 
an experiment. Please type the full path of the location where the data will
be stored. Make sure to check if sufficient space is available on the file
system. 

Example: /home/myname/my_experiments/new_experiment_name
Example: ~/my_experiments/new_experiment_name

- Instead of /home/myname most users can use ~
- Do not use / at the end of path






-------------------------------------------------------------------------------
Written by Brian Avants & Niels van Strien, 2011/2012
-------------------------------------------------------------------------------
MENU

echo -n " Please type the datapath : "
read choice

# testing for valid user input
test_path_wr ${choice}

if [ $? -eq 0  ]
then
    wiz_01
else

    test_path_exist ${choice}

    if [ $? -eq 0  ]
    then
	wiz_01
    elif [ $? -eq 1  ]
    then
	wiz_01_proc ${choice}
    fi

fi



done

}

wiz_02 () {
clear
while : # Loop forever
do
cat <<MENU
-------------------------------------------------------------------------------
ANTS functional MRI data processing pipeline - Data wizard 2/5
-------------------------------------------------------------------------------

MRI data is sometimes collected in multiple sessions. A session is defined 
here as the number of times that a subject was moved inside the MRI scanner 
for a particular experiment. A single sesion can have multiple runs (next  
step).












-------------------------------------------------------------------------------
Written by Brian Avants & Niels van Strien, 2011/2012
-------------------------------------------------------------------------------
MENU

echo -n " Please type number of sessions : "
read choice

if [[ ${choice} == ${choice//[^0-9]/} ]]
then
wiz_02_proc $choice
else
echo "not a valid number"
sleep 1
wiz_02
fi

done
}

wiz_03 () {
clear

while : # Loop forever
do
cat <<MENU
-------------------------------------------------------------------------------
ANTS functional MRI data processing pipeline - Data wizard 3/5
-------------------------------------------------------------------------------

A single sesion can have multiple runs. A run is defined as single collection
of time-series data. For example, if a person is scanned twice for 10 min 
on a cognitive task without leaving the scanner, but with a break in-between,   
there are 2 runs.












-------------------------------------------------------------------------------
Written by Brian Avants & Niels van Strien, 2011/2012
-------------------------------------------------------------------------------
MENU

echo -n " Please type number of runs : "
read choice

if [[ ${choice} == ${choice//[^0-9]/} ]]
then
wiz_03_proc $choice
else
echo "not a valid number"
sleep 1
wiz_03
fi

done
}

wiz_04 () {
clear

while : # Loop forever
do
cat <<MENU
-------------------------------------------------------------------------------
ANTS functional MRI data processing pipeline - Data wizard 4/5
-------------------------------------------------------------------------------

ANTSR keeps data and processed data separate. Therefore an output directory is
needed. Based on your choices the following directory would be a good choice.

$exp_path/results

If you agree, type y [ENTER]

If you would like to use another directory for results, please type the full
path.








-------------------------------------------------------------------------------
Written by Brian Avants & Niels van Strien, 2011/2012
-------------------------------------------------------------------------------
MENU

echo -n " Agree or type path : "
read choice

# testing for valid user input
if [ ${choice} == "y" ]
then
    wiz_04_proc ${choice}
elif [ ${#choice} -ne 0 ]
then
    test_path_wr ${choice}
else
    echo "\"$choice\" is not valid "
    sleep 1 
    wiz_04
fi

if [ $? -eq 0  ]
then
    wiz_04
else
    wiz_04_proc ${choice}
fi

test_path_exist ${choice}

if [ $? -eq 0  ]
then
    wiz_04
elif [ $? -eq 1  ]
then
    wiz_04_proc ${choice}
fi


done
}

wiz_05 () {
clear
chmod a+x ${cfgtmp}/antsr_cfg.sh
source ${cfgtmp}/antsr_cfg.sh
while : # Loop forever
do
cat <<MENU
-------------------------------------------------------------------------------
ANTS functional MRI data processing pipeline - Data wizard 5/5
-------------------------------------------------------------------------------

Review your choices and create the datastructure

experiment root: 	${exp_path}
data root:		${exp_path}/data
results:		${resultshome}

no sessions:		${ses}
no runs:		${runs}

Create folder structure (y/n).

Selecting no (n) will return you to the Configure data setup menu.





-------------------------------------------------------------------------------
Written by Brian Avants & Niels van Strien, 2011/2012
-------------------------------------------------------------------------------
MENU

echo -n " Agree or start over : "
read choice

case $choice in
y) wiz_05_proc $choice ;;
n) data_menu ;;
*) echo "\"$choice\" is not valid "; sleep 2 ;;
esac

done
}

store_instructions () {
clear

echo "the created data structure is"
echo " "
tree ${exp_path} | more
sleep 7
clear

cat <<MENU
-------------------------------------------------------------------------------
ANTS functional MRI data processing pipeline - Store your data
-------------------------------------------------------------------------------

The folder structure for you data is now set up. Please store your nifti files 
in the appropriate folders, i.e. 

${exp_path}/data/session_01/run_01
    ├── subject_01.nii.gz
    ├── subject_02.nii.gz
    ├── etc...

Files in scanner source format can often be converted with dcm2nii (part of 
MRICron): http://www.mccauslandcenter.sc.edu/CRNL/tools

Name your subject time-series files in a systematic way, so that they can be 
batch processed. A subjectID should only have numeric or alphabetic characters 
or underscore and should never include characters such as @ ! # space etc.

Once your are done, continue the analysis by restarting: 
antsmain.sh ${exp_path}/scripts/dependencies.sh
-------------------------------------------------------------------------------
Written by Brian Avants & Niels van Strien, 2011/2012
-------------------------------------------------------------------------------
MENU
exit
}

data_menu () {
clear

while : # Loop forever
do
cat <<MENU
-------------------------------------------------------------------------------
ANTS functional MRI data processing pipeline - Configure data setup
-------------------------------------------------------------------------------

To be able to automate the analysis of functional imaging data, the data needs 
to be stored in systematic way. This script will create a set of folders based
on your preferences. In addition a configuration file will be written that is
needed by ANTS for data processing.

1) Run data structure and configuration file wizard.
2) Test data structure and configuration file.
3) Return to main menu.
4) Exit.







-------------------------------------------------------------------------------
Written by Brian Avants & Niels van Strien, 2011/2012
-------------------------------------------------------------------------------
MENU

echo -n " Your choice? : "
read choice

case $choice in
1) wiz_01 ;;
2) echo "not implemented yet"; sleep 2 ;;
3) main_menu ;;
4) bye ;;
*) echo "\"$choice\" is not valid "; sleep 2 ;;
esac
done
}




# main script starts here
clear
cfg_check
data_menu