#/bin/bash
echo "type a number"
read choice

if [[ ${choice} == ${choice//[^0-9]/} ]]
then
echo "is a number"
else
echo "not a number"
fi


