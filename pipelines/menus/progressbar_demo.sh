#!/bin/bash

showBar () {
 percDone=$(echo 'scale=2;'$1/$2*100 | bc)
 barLen=$(echo ${percDone%'.00'})
 barLen2=$(echo ${percDone%'.00'}/2 | bc)
 bar=''
 fills=''
 for (( b=0; b<$barLen2; b++ ))
 do
  bar=$bar"*"
 done
 blankSpaces=$(echo $((50-$barLen2)))
 for (( f=0; f<$blankSpaces; f++ ))
 do
  fills=$fills"_"
 done
 clear

if [ ${1} -eq 0  ] # loop from which function is called has to start at 0
then
 echo "-------------------------------------------------------------------------------"
 echo ${Procedure}
 echo "-------------------------------------------------------------------------------"
 echo "Overall progress: "
 echo '['$bar'>'$fills'] - '$barLen'%' 
 echo "-------------------------------------------------------------------------------" 
 echo 'Time remaining: estimating on basis of 1st iteration; please wait' 
 echo "-------------------------------------------------------------------------------" 

sum_time_elapsed=0

else
# calculating ETA
 time_end=`date +%s`
 time_elapsed=$(( time_end - $3 ))
 sum_time_elapsed=$(( sum_time_elapsed + time_elapsed ))
 mean_time_elapsed=$(( sum_time_elapsed / $1 ))
 remaining_time=$(( mean_time_elapsed * $2 - mean_time_elapsed * $1 ))
 eta=$(( time_end + remaining_time ))
 eta2=`date -d @$eta`

# debug only
# echo $3
# echo $time_end
# echo $time_elapsed
 #echo $sum_time_elapsed
 #echo $mean_time_elapsed
# echo $remaining_time

 echo "-------------------------------------------------------------------------------"
 echo ${Procedure}
 echo "-------------------------------------------------------------------------------"
 echo "Overall progress: "
 echo '['$bar'>'$fills'] - '$barLen'%' 
 echo "-------------------------------------------------------------------------------" 
 echo 'Time remaining: ' $(( remaining_time / 3600 ))h $(( remaining_time %3600 / 60 ))m $(( remaining_time % 60 ))s "; ETA: " ${eta2}
 echo "-------------------------------------------------------------------------------" 
fi

}


for (( i=0; i<=100; i++ ))
do

showBar ${i} 100 ${time_start}
time_start=`date +%s`

let R=$RANDOM%10+1;# to make the process not have a constant time
echo $R
sleep $R # simulating some procss

done