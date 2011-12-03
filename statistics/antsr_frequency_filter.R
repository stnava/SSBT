#!/usr/bin/env Rscript
Args <- commandArgs()
# library("signal")
library("timeSeries")
library(mFilter)
# print(paste("length of args is ", length(Args)))
if ( length(Args) < 8  ){
fnm<-Args[4]
fnm<-substring(fnm,8,nchar(as.character(fnm)))
print(paste("Usage - RScript values_in.csv values_out.csv TR freq_lo freq_hi nuis.csv "))
print(paste(" ... band pass filter and residualize the time series if nuis is  passed in " ))
print(paste(" freq_lo --- throw away signal below this frequency " ))
print(paste(" freq_hi --- throw away signal above this frequency " ))
q()
}
ARGIND<-6
valuesIn<-c(as.character(Args[ARGIND]))
ARGIND<-ARGIND+1
valuesOut<-c(as.character(Args[ARGIND]))
ARGIND<-ARGIND+1
tr<-c(as.numeric(Args[ARGIND]))
ARGIND<-ARGIND+1
freqLow<-c(as.numeric(Args[ARGIND]))
ARGIND<-ARGIND+1
freqHi<-c(as.numeric(Args[ARGIND]))
ARGIND<-ARGIND+1
nuis<-NA
if ( length(args) > 10 )
{
  nuiscsv<-c(as.character(Args[ARGIND]))
  nuis<-read.csv(nuiscsv)
}
print(paste('read data',valuesIn))
values<-read.csv(valuesIn)
nvox1<-dim(values)[2]
# first calculate the filter width for the butterworth based on TR and the desired frequency
voxLo=round((1/freqLow)/tr) # remove anything below this (high-pass)
voxHi=round((1/freqHi)/tr)   # keep anything above this
print(paste("start filtering smoothing by",voxHi," and ",voxLo))
progvals<-round(nvox1/100)
for ( x in c(1:nvox1) ) 
{
  modval<-(x %% progvals)
  if ( modval == 1 )
  {
    print(paste('progress',x/nvox1*100,'%'))
  }  
  vals1<-values[,x]
  if ( !is.na(nuis) )
  {
    vals1<-residuals(lm(values[,x]~1+as.matrix(nuis)))
  }
  vals1<-ts(vals1,frequency=1/tr)
  # butterworth low pass filter
  getridoflow<-bwfilter(vals1, freq=voxLo,drift=TRUE)$cy 
  getridofhi<-bwfilter(getridoflow, freq=voxHi,drift=TRUE)$tr
  filtered<-bwfilter(getridofhi, freq=voxLo,drift=TRUE)$cy 
  values[,x]<-filtered
}
write.csv(values,valuesOut,row.names = F,q=T)
