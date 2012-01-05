#!/bin/bash

bye () {
clear
cat <<MENU
-------------------------------------------------------------------------------
Thank you for using ANTSR. If you use ANTSR for your work, please cite:
-

-------------------------------------------------------------------------------
MENU

exit

}

main_menu_nodep () {
clear

while : # Loop forever
do
cat <<MENU
-------------------------------------------------------------------------------
ANTS functional MRI data processing pipeline
-------------------------------------------------------------------------------

1) Configure or test data setup.


2) ANTSR demo suite.
3) Change defaults
4) Exit ANTSR.

NB: run `basename ${0}` /pathto/dependencies.sh (resulting file of 1) to start
(pre)processing data


The ANTSR functional MRI (fMRI) data processing pipeline allows you to perform
common fMRI processing steps, such as motion correction, brain extraction, 
spatial and temporal filtering. 

Using the R statistical framework, advanced analyses can be carried out, such
as resting state fMRI analysis or task fMRI analysis.
-------------------------------------------------------------------------------
Written by Brian Avants & Niels van Strien, 2011/2012
-------------------------------------------------------------------------------
MENU

echo -n " Your choice? : "
read choice

case $choice in
1) source organize_data.sh ;;
2)  ;;
3)  ;;
4)  bye;;
*) echo "\"$choice\" is not valid "; sleep 2 ;;
esac
done
}

main_menu () {
clear

while : # Loop forever
do
cat <<MENU
-------------------------------------------------------------------------------
ANTS functional MRI data processing pipeline
-------------------------------------------------------------------------------

1) Configure or test data setup.
2) FMRI preprocessing.
3) FMRI statistics. (under construction)
4) ANTsR demo suite.
5) Change defaults
6) Exit ANTsR.



The ANTsR functional MRI (fMRI) data processing pipeline allows you to perform
common fMRI processing steps, such as motion correction, brain extraction, 
spatial and temporal filtering. 

Using the R statistical framework, advanced analyses can be carried out, such
as resting state fMRI analysis or task fMRI analysis.


-------------------------------------------------------------------------------
Written by Brian Avants & Niels van Strien, 2011/2012
-------------------------------------------------------------------------------
MENU

echo -n " Your choice? : "
read choice

case $choice in
1) source organize_data.sh ;;
2) source ants_preprocessing.sh ;;
3)  ;;
4)  ;;
5)  ;;
6) bye ;;
*) echo "\"$choice\" is not valid "; sleep 2 ;;
esac
done
}


cfg_file=$1
# main script starts here
if [ $# -lt 1 ] ; then 
main_menu_nodep
elif [ -f ${cfg_file} ] && [[ ${cfg_file} =~ "dependencies" ]]
then
source $1
main_menu
fi 


