library(ggplot2)
library(reshape2)
library(plyr)

# path to the data directory
theDir=""

plinkPCA = function(PC=NULL,colLabel="Group", subVec=NULL,
                    xLim=NULL,yLim=NULL,labelPlot=NULL,
                    file="plink",theSep=" ") {
  if(!is.null(PC)){
    xAxis=PC[1]
    yAxis=PC[2]
  }else{
    xAxis="PC1"
    yAxis="PC2"
  }
  vecfile = paste(paste(theDir,file,sep=""),"eigenvec",sep=".")
  PCA=read.csv(vecfile,header=F,sep=theSep)
  
  valfile = paste(paste(theDir,file,sep=""),"eigenval",sep=".")
  EigVal=read.csv(valfile,header=F,sep=theSep)
  
  getLength=length(PCA[1,])
  HeaderVector=c("Group", "ID")
  start = 1
  while (start <= getLength-2){
    HeaderVector=c(HeaderVector, paste("PC",start,sep=""))
    start=start+1
  }
  colnames(PCA) <- HeaderVector
  
  p=ggplot(PCA,aes_string(xAxis,yAxis,colour="Group"))+geom_point(size=2,alpha = 6/10)
  p=p+ggtitle(paste(xAxis,yAxis,sep=" vs. "))+ theme(plot.title = element_text(lineheight=.5, face="bold",size=14))
  
  # p=p+guides(colour=guide_legend(nrow=20,byrow=TRUE)) 
  
  if(!is.null(subVec)){
    colorList=rainbow(length(subVec))
    start = 1
    for (i in subVec){
      print(i)
      p=p+geom_point(data=subset(PCA,Group==i), aes(shape=Group), size=3, color="black")
      start=start+1    
    }
  }
  
  if(!is.null(labelPlot)){
    start = 1
    for (i in labelPlot){
      print(i)
      p=p+geom_text(data=subset(PCA,Group==i), aes(label=ID),size=2.5,color='black')
      start=start+1    
    }
  }
  
  if(!is.null(xLim)){
    p=p+xlim(xLim[1],xLim[2])
  }
  
  if(!is.null(yLim)){
    p=p+ylim(yLim[1],yLim[2])
  }
  
  p
}
