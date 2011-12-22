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

main_menu () {
clear

while : # Loop forever
do
cat <<MENU
-------------------------------------------------------------------------------
ANTS functional MRI data processing pipeline
-------------------------------------------------------------------------------

1) Test ANTSR software requirements
2) Configure or test data setup.
3) FMRI preprocessing.
4) FMRI statistics.
5) ANTSR demo suite.
6) Exit ANTSR.



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
1)  ;;
2) source organize_data.sh ;;
3)  ;;
4)  ;;
5)  ;;
6) bye ;;
*) echo "\"$choice\" is not valid "; sleep 2 ;;
esac
done
}

# main script starts here
if [ $# -lt 1 ] ; then 
main_menu
elif [ -f ${1} ] && [[ ${1} =~ "dependencies" ]]
then
source $1
main_menu
fi 


