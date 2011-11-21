#!/usr/bin/env Rscript
Args <- commandArgs()
#
if ( length(Args) < 8  ){
fnm<-Args[4]
fnm<-substring(fnm,8,nchar(as.character(fnm)))
print(paste("Usage - RScript  evecs.csv nuis.csv subject_id   "))
print(paste(" ... " ))
print(paste(" pairwise correlation of time series projections stored in a csv file  " ))
q()
}
ARGIND<-6
evecs<-c(as.character(Args[ARGIND]))
ARGIND<-ARGIND+1
nuiscsv<-c(as.character(Args[ARGIND]))
ARGIND<-ARGIND+1
id<-c(as.character(Args[ARGIND]))
ARGIND<-ARGIND+1
 evecs<-read.csv(evecs)
 nuis<-read.csv(nuiscsv)
 print(dim(nuis))
 print(dim(evecs))
 nvox<-dim(evecs)[2]
 statform<-formula( vals1 ~ 1 + vals2 + as.matrix(nuis) )
 pvals<-matrix(rep(NA,nvox*nvox),nrow=nvox,ncol=nvox)
 betav<-matrix(rep(NA,nvox*nvox),nrow=nvox,ncol=nvox)
 print("start stats")
 for ( x in c(1:nvox) ) 
 { 
   vals1<-evecs[,x]
   for ( y in c(1:nvox) ) 
   { 
     if ( x != y )
     {
     vals2<-evecs[,y]
#  pvalue of relationship with the ROI 
     modelresults<-(summary(lm(statform)))
#     print(paste("x",x,"y",y,"pval",modelresults$coeff[2,4]))
     pvals[x,y]<-modelresults$coeff[2,4]
     betav[x,y]<-modelresults$coeff[2,3]
     }
   }
 }
 print("done stats")
 qv<-matrix(p.adjust(pvals),nrow=nvox,ncol=nvox)
 for ( x in c(1:nvox) ) 
 { 
   ntw<-c("")
   ntwq<-c("")
   for ( y in c(1:nvox) ) 
   { 
     if ( x != y & qv[x,y] < 0.001 )
     {
       ntw<-paste(ntw,y-1)
       ntwq<-paste(ntwq, qv[x,y] )
     }
   }
   print(paste("Network_for_variate_",x-1,"includes variates:",ntw))
#   print(paste("Network_for_variate_",x-1,"qvals:",ntwq))
 }
 betav<-betav*(qv <= 0.05) 
 dfm<-data.frame(betas=betav,qvals=1-qv,pvals=1-pvals)
 write.csv(dfm,paste(id,'qvals.csv',sep=''),row.names = F,q=T)
