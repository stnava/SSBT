#!/usr/bin/env Rscript
Args <- commandArgs()
#
library("signal")
library("timeSeries")
if ( length(Args) < 8  ){
fnm<-Args[4]
fnm<-substring(fnm,8,nchar(as.character(fnm)))
print(paste("Usage - RScript subject_id  values_1.csv values_2.csv nuis.csv   "))
print(paste(" ... " ))
print(paste(" pairwise regression of data stored in a csv file  " ))
print(paste(" will compute a model of the form ::  " ))
print(paste(" lm( values_1.csv ~ 1 + values_2.csv + nuis.csv  " ))
print(paste(" and will return the value of the vector values2~values1 for every pair of v1,v2 values "))
print(paste(" you can use this to do a voxelwise regression "))
q()
}
ARGIND<-6
id<-c(as.character(Args[ARGIND]))
ARGIND<-ARGIND+1
cvecs1<-c(as.character(Args[ARGIND]))
ARGIND<-ARGIND+1
cvecs2<-c(as.character(Args[ARGIND]))
ARGIND<-ARGIND+1
nuiscsv<-c(as.character(Args[ARGIND]))
ARGIND<-ARGIND+1
 vecs1<-read.csv(cvecs1)
 vecs2<-read.csv(cvecs2)
 nuis<-read.csv(nuiscsv)
 nvox1<-dim(vecs1)[2]
 nvox2<-dim(vecs2)[2]
 statform<-formula( vals1 ~ 1 + vals2 + as.matrix(nuis) )
 statform<-formula( vals1 ~ 1 + vals2 )
 pvals<-matrix(rep(NA,nvox1*nvox2),nrow=nvox1,ncol=nvox2)
 betav<-matrix(rep(NA,nvox1*nvox2),nrow=nvox1,ncol=nvox2)
 print("start stats")
 for ( x in c(1:nvox1) ) 
 { 
   vals1<-residuals(lm(vecs1[,x]~1+as.matrix(nuis)))
   for ( y in c(1:nvox2) ) 
   { 
     vals2<-residuals(lm(vecs2[,y]~1+as.matrix(nuis)))
#  pvalue of relationship with the ROI 
     modelresults<-(summary(lm(statform)))
#     print(paste("x",x,"y",y,"pval",modelresults$coeff[2,4]))
     pvals[x,y]<-modelresults$coeff[2,4]
     betav[x,y]<-modelresults$coeff[2,3]
   }
 }
 print("done stats")
 qv<-matrix(p.adjust(pvals),nrow=nvox1,ncol=nvox2)
# qv<-pvals*(nvox1*nvox2)
for ( x in c(1:nvox1) ) 
 { 
   ntw<-c("")
   ntwq<-c("")
   for ( y in c(1:nvox2) ) 
   { 
     if ( x != y & qv[x,y] < 0.01  ) # & betav[x,y] < 0.0 )
     {
       ntw<-paste(ntw,y-1)
       ntwq<-paste(ntwq, qv[x,y] )
     }
   }
   print(paste("Network_for_variate_",x-1,"includes variates:",ntw))
   print(paste("Network_for_variate_",x-1,"qvals:",ntwq))
 }
 betav<-betav*(qv <= 0.05) 
 dfm<-data.frame(betas=betav,qvals=1-qv,pvals=1-pvals)
 write.csv(dfm,paste(id,'qvals.csv',sep=''),row.names = F,q=T)
 
