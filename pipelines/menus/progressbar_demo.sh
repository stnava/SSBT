#!/bin/bash

function showBar {
 percDone=$(echo 'scale=2;'$1/$2*100 | bc)
 barLen=$(echo ${percDone%'.00'})
 bar=''
 fills=''
 for (( b=0; b<$barLen; b++ ))
 do
  bar=$bar"="
 done
 blankSpaces=$(echo $((100-$barLen)))
 for (( f=0; f<$blankSpaces; f++ ))
 do
  fills=$fills"_"
 done
 clear
 echo '['$bar'>'$fills'] - '$barLen'%'
}

for (( i=0; i<=100; i++ ))
do
 showBar $i 100
done