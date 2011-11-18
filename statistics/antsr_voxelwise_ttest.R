#!/usr/bin/Rscript
Args <- commandArgs()
#
if ( length(Args) < 9  ){
fnm<-Args[4]
fnm<-substring(fnm,8,nchar(as.character(fnm)))
print(paste("Usage - RScript PathToAntsImageMath mask OutputPrefix ListOfFiles_Group1  ListOfFiles_Group2  "))
print(paste(" .... " ))
print(paste(" if you do not pass in ListOfFiles_Group2 , then a one sample t-test will be performed " ))
q()
}
ARGIND<-6
AntsImageMath<-c(as.character(Args[ARGIND]))
ARGIND<-ARGIND+1
MASK<-c(as.character(Args[ARGIND]))
ARGIND<-ARGIND+1
OUTNAME<-c(as.character(Args[ARGIND]))
ARGIND<-ARGIND+1
FNLISTG1<-c(as.character(Args[ARGIND]))
ARGIND<-ARGIND+1
FNLISTG2<-c("")
if ( length(Args) == 10  )
  {
  FNLISTG2<-c(as.character(Args[ARGIND]))
  }
filereadable<-file.access(AntsImageMath,mode=4)
if ( filereadable == -1 ) {
  print(paste(" Cannot find the program ",AntsImageMath," quitting. "))
  q()
} else {
AntsImageMath<-paste(AntsImageMath," 3 ")
print(paste("you have ",AntsImageMath))
}
filereadable<-file.access(MASK,mode=4)
if ( filereadable == -1 ) {
  print(paste(" Cannot find the mask ",MASK," quitting. "))
  q()
} 

cmd<-paste("cat",FNLISTG1)
IMGLISTG1<-try(system(cmd, intern = TRUE, ignore.stderr = TRUE))
filereadable<-file.access(IMGLISTG1[1],mode=4)
if ( filereadable == -1 ) {
  print(paste(" Cannot find the first image ",IMGLISTG1[1]," quitting. "))
  q()
} 

IMGLISTG2<-""
if (length(FNLISTG2) > 0 )
  {
  cmd<-paste("cat",FNLISTG2)
  IMGLISTG2<-try(system(cmd, intern = TRUE, ignore.stderr = TRUE))
  filereadable<-file.access(IMGLISTG2[1],mode=4)
  if ( filereadable == -1 )
    {
    print(paste(" Cannot find the first image in list 2 --- will do one sample t-test ",IMGLISTG2[1]," . "))
    }
  }
NG1<-length(IMGLISTG1)
NG2<-length(IMGLISTG2)
if (length(IMGLISTG1) < 1) {
print(" you passed in a short image list for group 1." )
q() 
}
if (length(IMGLISTG2) < 1) {
print(" you passed in a short image list for group 2." )
}
print(paste(" n-group-1-images: ",length(IMGLISTG1)," n-group-2-images: ",length(IMGLISTG2)))
IMAGELISTFORTHISSTUDY<-c(IMGLISTG1,IMGLISTG2)
# then set up all your imaging variables -- vectors and matrices for input and output 
EXT=".mhd"
EXTR=".raw"
EXTN=".nii.gz"
OUTMAT=paste(OUTNAME,"mat",EXT,sep='')
OUTMATR=paste(OUTNAME,"mat",EXTR,sep='')
VECOUTPUTSMHD<-""
VECOUTPUTSRAW<-""
VECOUTPUTSNII<-""
NAMES<-""
for ( i in c(1:length(NAMES)) ) {
  VECOUTPUTSMHD<-c( VECOUTPUTSMHD, paste(OUTNAME,NAMES[i],"pvals",EXT,sep='') ,  paste(OUTNAME,NAMES[i],"tstat",EXT,sep='') , paste(OUTNAME,NAMES[i],"fdr",EXT,sep='')   )
  VECOUTPUTSRAW<-c( VECOUTPUTSRAW, paste(OUTNAME,NAMES[i],"pvals",EXTR,sep='') ,  paste(OUTNAME,NAMES[i],"tstat",EXTR,sep='') , paste(OUTNAME,NAMES[i],"fdr",EXTR,sep='')   )
  VECOUTPUTSNII<-c( VECOUTPUTSNII, paste(OUTNAME,NAMES[i],"pvals",EXTN,sep='') ,  paste(OUTNAME,NAMES[i],"tstat",EXTN,sep='') , paste(OUTNAME,NAMES[i],"fdr",EXTN,sep='')   )
}
VECOUTPUTSMHD<-VECOUTPUTSMHD[2:length(VECOUTPUTSMHD)]
VECOUTPUTSRAW<-VECOUTPUTSRAW[2:length(VECOUTPUTSRAW)]
VECOUTPUTSNII<-VECOUTPUTSNII[2:length(VECOUTPUTSNII)]
print(VECOUTPUTSMHD) 
print(VECOUTPUTSRAW) 
print("You will output images : ")
 print(VECOUTPUTSNII) 

neededimages<-c(MASK,VECOUTPUTSMHD,OUTMAT)
for ( img in neededimages ) {
cmd<-paste("ls",img)
bb<-try(system(cmd, intern = TRUE, ignore.stderr = TRUE))
     if ( length(bb) > 0 ) {
      print(paste("you have",img)) 
     } else {
     print(paste("you do not have",img)) 
     if ( img != MASK && img != OUTMAT  ) {
        cmd<-c( paste(AntsImageMath,img," ConvertImageSetToMatrix 1 ",MASK,IMAGELISTFORTHISSTUDY[1]) ) 
        bb<-try(system(cmd, intern = TRUE, ignore.stderr = TRUE))
      } 
      if ( img == MASK ) {
        print("the mask is not a readable file -- exiting! ") 
	q()
      }
      if ( img == OUTMAT ) {
	# probably a better way to do this but we need all the entries to be in a single string
	CIMAGELISTFORTHISSTUDY<-" " 
	for ( my_entry in IMAGELISTFORTHISSTUDY ) {
          CIMAGELISTFORTHISSTUDY<-paste(CIMAGELISTFORTHISSTUDY,my_entry)
        }
        
        cmd<-paste(AntsImageMath,OUTMAT,"ConvertImageSetToMatrix 1 ",MASK,CIMAGELISTFORTHISSTUDY)
	print(cmd)
        bb<-try(system(cmd, intern = TRUE, ignore.stderr = TRUE))
      }
      }
}

# read the mhd for the matrix OUTMAT 
print(paste("reading " , OUTMAT) )
header<-read.delim(OUTMAT, header=FALSE,sep=" ")
 print(header)
 print(names(header))
NSUBJ<-as.numeric(as.character(header$V3[14])) # convert to number
NUMVOX<-as.numeric(as.character(header$V1[15]))
print(paste("N-Subjects",NSUBJ,"N-Voxels",NUMVOX))

# GROUP1
TTLTH<-NUMVOX*NSUBJ
print(paste("TotalElements",TTLTH))
x<-c(readBin(OUTMATR,what=numeric(),n=TTLTH,size = 4, endian = .Platform$endian))
x<-matrix(c(x), nrow=NSUBJ,ncol=NUMVOX,byrow=FALSE) 
print(paste("Done reading",NSUBJ,NUMVOX))
print(dim(x)) 

# http://www.statmethods.net/management/subset.html
# correlation values 
# should be newline separated, one for each subject

print(paste("Begin Regression ",NUMVOX))
# correlation-values 
  pvals1<-c(1:NUMVOX)*0+1
  qq<-pvals1*0+1 
  cvals1<-c(1:NUMVOX)*0
  didvals<-c(1:NUMVOX)*0
  totaldid<-0
NT<-NUMVOX
statlist<-c("StudentsT","Rank")
WhichStat<-"StudentsT"
for(i in 1:NT) {
	StatVals<-x[,i]
        g1range<-1:NG1
        g2range<-((NG1+1):(NG1+NG2))
	if ( sd(StatVals) > 0.  ) {
        if ( WhichStat == "StudentsT" ) {
          if ( NG2 > 1 )
            {
              statreport<-t.test( StatVals[g1range] , StatVals[g2range] , alternative="g",paired=TRUE)
            }
          else
            { 
              statreport<-t.test( StatVals[g1range] )
            }
          pvals1[i]<-statreport$p.value
          cvals1[i]<-statreport$stat
        }
        else if ( WhichStat == "Rank" ) 
        {
          statreport<-wilcox.test( StatVals[g1range] , StatVals[g2range] , alternative="g",paired=FALSE)
          pvals1[i]<-statreport$p.value
          cvals1[i]<-statreport$stat
        }
        else { print(paste("must choose from these statistics",statlist,"and put in variable called WhichStat")) }

	 if (   i %% 5000 == 0) {
	   print(paste(i / NUMVOX * 100," % Complete "))
	   qq[ didvals == 1 ]<-p.adjust(pvals1[ didvals == 1],method="BH")
	   print(paste(NAMES[1],"BH fdr1",max(1-qq),totaldid))
	   print(statreport)
	   print(paste( " t-value ",	 cvals1[i]	 ))
         }   
	didvals[i]<-1
	totaldid<-totaldid+1
   } # SD of thickness 
} # NUMVOX 
print(paste(" did ",totaldid/NUMVOX)) 


# FDR params 

FCT<-1
# 1st regressor
print(VECOUTPUTSRAW[FCT])
writeBin(1-pvals1, VECOUTPUTSRAW[FCT], size = 4, endian = .Platform$endian)
FCT<-FCT+1
writeBin(cvals1, VECOUTPUTSRAW[FCT], size = 4, endian = .Platform$endian)
 print(paste(" write T ",  VECOUTPUTSRAW[FCT] ," FCT",FCT," mx ",max(cvals1) ))
FCT<-FCT+1
qq<-pvals1*0+1 
# qobj<-qvalue(pvals1[didvals == 1],pi0.method="smoother",smooth.df=9,smooth.log.pi0=TRUE,robust=TRUE) 
# qq[ didvals == 1 ]<-(qobj$qvalues) 
 qq[ didvals == 1 ]<-p.adjust(pvals1[ didvals == 1],method="BH")
# qq[ didvals == 1 ]<-fdrtool(cvals1[ didvals == 1],statistic=c("studentt"))$qval
# qq[ didvals == 1 ]<-fdrtool(pvals1[ didvals == 1],statistic=c("pvalue"))$qval
 print(paste(NAMES[1],"fdr1-q",max(1-qq)))
writeBin(1-qq, VECOUTPUTSRAW[FCT], size = 4, endian = .Platform$endian)
FCT<-FCT+1

qq[ didvals == 1 ]<-p.adjust(pvals1[ didvals == 1],method="BH")
print(paste(NAMES[1],"BH fdr1",max(1-qq)))
for ( i in 1:length(VECOUTPUTSMHD)) {
cmd<-paste(AntsImageMath,VECOUTPUTSNII[i]," ConvertVectorToImage ",MASK,VECOUTPUTSMHD[i])
print(paste(cmd," FCT ",i))
        bb<-try(system(cmd, intern = TRUE, ignore.stderr = TRUE))
print(bb)
}

q()


