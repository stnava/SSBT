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
freqLo<-c(as.numeric(Args[ARGIND]))
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
ntimeseries<-dim(values)[1]
# first calculate the filter width for the butterworth based on TR and the desired frequency
voxLo=round((1/freqLo)/tr) # remove anything below this (high-pass)
voxHi=round((1/freqHi)/tr)   # keep anything above this
# voxLo=round((1/freqLo)) # remove anything below this (high-pass)
# voxHi=round((1/freqHi))   # keep anything above this
print(paste("start filtering smoothing by",voxHi," and ",voxLo))
progvals<-round(nvox1/100)
if ( progvals < 100 ) progvals<-1
for ( x in c(1:nvox1) ) 
{
  modval<-(x %% progvals)
  if ( modval == 1 )
  {
    print(paste('progress',round(x/nvox1*100),'%'))
  }  
  vals1<-values[,x]
  if ( !is.na(nuis) )
  {
    vals1<-residuals(lm(values[,x]~1+as.matrix(nuis)))
  }
  vals1<-ts(vals1,frequency=1/tr)
  # butterworth low pass filter
#  getridoflow<-bwfilter(vals1, freq=voxLo,drift=TRUE)$cy 
#  getridofhi<-bwfilter(getridoflow, freq=voxHi,drift=TRUE)$tr
# filtered<-bwfilter(getridofhi, freq=voxLo,drift=TRUE)$cy 
# band-pass filter
#  filtered<-bkfilter(vals1,pl=voxLo,pu=voxHi,nfix=NULL,type=c("fixed","variable"),drift=FALSE)
#  filtered<-cffilter(vals1,pl=voxHi,pu=voxLo,drift=FALSE)$tr
#  filtered<-residuals(cffilter(vals1,pl=voxHi,pu=voxLo,drift=T,type="f"))
  filtered<-residuals(cffilter(vals1,pl=voxHi,pu=voxLo,drift=T,type="t"))
  #  could also use a boxcar filter: for band-pass filtering - a low-pass filter is applied and then a high-pass filter is applied to the resulting time-series.
  filtered[1,]<-filtered[3,]
  filtered[2,]<-filtered[3,]
  filtered[ntimeseries-1,]<-filtered[ntimeseries-2,]
  filtered[ntimeseries,]<-filtered[ntimeseries-2,]
#  plot(filtered)
#  spec.ar(filtered[5:ntimeseries-5,])
  values[,x]<-filtered
  if ( x == 5 )
  {
    pdf(gsub('.csv','VisualizeTimeSeriesFiltering.pdf',valuesOut))
    par(mfrow=c(2,2))
    plot(vals1,type='l')
    spec.pgram( vals1, taper=0, fast=FALSE, detrend=F,demean=F, log="n")
    plot(filtered,type='l')
    spec.pgram( filtered, taper=0, fast=FALSE, detrend=F,demean=F, log="n")
    dev.off()
  }
}
write.csv(values,valuesOut,row.names = F,q=T)
