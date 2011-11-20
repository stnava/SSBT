#!/usr/bin/env Rscript
Args <- commandArgs()
#
if ( length(Args) < 8  ){
fnm<-Args[4]
fnm<-substring(fnm,8,nchar(as.character(fnm)))
print(paste("Usage - RScript PathToSCCAN mask id   "))
print(paste(" .... assumes existence of the files idout_compcorr.csv and idroi_compcorr.csv " ))
print(paste(" correlation of a time series image stored in a csv file with a roi defined in a mask  " ))
q()
}
ARGIND<-6
sccan<-c(as.character(Args[ARGIND]))
ARGIND<-ARGIND+1
mask<-c(as.character(Args[ARGIND]))
ARGIND<-ARGIND+1
id<-c(as.character(Args[ARGIND]))
ARGIND<-ARGIND+1
OUTNAME<-c(as.character(Args[ARGIND]))
ARGIND<-ARGIND+1
FNLISTG1<-c(as.character(Args[ARGIND]))
ARGIND<-ARGIND+1
FNLISTG2<-c("")
cortex<-read.csv(paste(id,'.csv',sep=''))
 acc<-read.csv(paste(id,'_roi_compcorr.csv',sep=''))
 nuis<-read.csv(paste(id,'out_compcorr.csv',sep=''))
 print("done reading")
 nvox<-dim(cortex)[2]
 statform<-formula( vals ~ 1 + acc$GlobalSignal + as.matrix(nuis) )
 pvals<-rep(1,nvox)
 betav<-rep(0,nvox)
 print("start stats")
 for ( x in c(1:nvox) ) 
 { 
   vals<-cortex[,x]
# pvalue of relationship with the ROI 
   modelresults<-(summary(lm(statform)))
   pvals[x]<-modelresults$coeff[2,4]
   betav[x]<-modelresults$coeff[2,3]
 }
 print("done stats")
 qv<-p.adjust(pvals)
 betav<-betav*(qv <= 0.05) 
 dfm<-data.frame(betas=betav,qvals=1-qv,pvals=1-pvals)
 write.csv(dfm,paste(id,'qvals.csv',sep=''),row.names = F,q=T)
 cmd<-paste(sccan," --vector-to-image [",id,"qvals.csv, ",mask,"] -o ",id,"qvals.nii.gz",sep='')
 print(cmd)
 system(cmd)
