#original otu data sent to us (not from blj)
#excludes samples with NA tumor volume, includes vol in model 

rm(list=ls())

setwd('/Users/whitneyware/IER_Sleeve')
library("vegan")
library("nlme")

project <- "SleeveGastro"
taxa <- "genus"


inFile <- paste0("SleeveGastro_",taxa,"pcoa_metaMerged.txt")	
myT <- read.table(inFile, sep="\t", header=TRUE)	
numCols <- ncol(myT)
myColClasses <- c("character",rep("numeric", which(names(myT)=="BarcodeSequence")-2),
                  "character","character","numeric","numeric","numeric",
                  rep("numeric", numCols-which(names(myT)=="Cage.number")+1 ))

names <- colnames(myT)
check <- cbind(names,myColClasses)

myT <-read.table(inFile,header=TRUE,sep="\t",colClasses=myColClasses)
myT <- myT[!is.na(myT$Tumor.volume), ]
		
pValuesTime <-vector()
pValuesTumor <- vector()
pValuesGroup<- vector()
pValuesFobVsSG <- vector()
bugNames <- vector()
bugIndex <- vector()
pValuesLog10VolumeWithDirection <- vector()
corCoeffVolumeBug <- vector()
	
index <- 1
	
cage <- myT$Cage.number
time <- myT$Time.point..weeks.
time <- factor(time)
volume <- myT$Tumor.volume
treatmentGroup <- myT$Treatment.Group
treatmentGroup <- factor(treatmentGroup )
	
treatmentColors <- vector()
	
for( i in 1:length(treatmentGroup))
{
	if( treatmentGroup[i]=="Control" )
		treatmentColors[i] = "RED"
	
	if( treatmentGroup[i]=="DIO" )
		treatmentColors[i] = "BLUE"
				
	if( treatmentGroup[i]=="FOb" )
		treatmentColors[i] = "YELLOW"
			
	if( treatmentGroup[i]=="SG" )
		treatmentColors[i] = "BLACK"
}
	
toRun <- c(2:(which(names(myT)=="BarcodeSequence")-1),which(names(myT)=="MDS1"):which(names(myT)=="MDS10"))

for( i in toRun)
{
	bug <- myT[,i]
		
	if ( substr(names(myT)[i],1,3) != "MDS")
	{
		bug <- log( myT[,i] * 100000 + 1)	
	}
		
	if( sum( bug != 0) > nrow(myT) /4 ) 
{
		aFrame <- data.frame(cage,time,volume,bug)
		M.mixed <- lme( bug ~ time +volume+treatmentGroup, method = "REML", random = ~1 | cage, data =aFrame)
		
		pValuesTime[index] <-anova(M.mixed)$"p-value"[2]
		pValuesTumor[index] <- anova(M.mixed)$"p-value"[3]
		pValuesGroup[index] <- anova(M.mixed)$"p-value"[4]
		bugIndex[index] <- i
		bugNames[index] <- names(myT)[i]
		
		pValuesLog10VolumeWithDirection[index] <- log10(pValuesTumor[index] )
  
  		corCoeffVolumeBug[index] <- cor( bug,volume)
  
  		if(   corCoeffVolumeBug[index] < 0 ) 
  			pValuesLog10VolumeWithDirection[index] = -pValuesLog10VolumeWithDirection[index] 
	
		pValuesFobVsSG[index]  <- t.test( bug[time == 25 &  treatmentGroup ==  "SG" ] ,bug[time == 25 &  treatmentGroup ==  "FOb" ])$p.value
	
		index = index + 1
	}
}
	
dFrame <- data.frame(	bugNames, pValuesTime,pValuesTumor,pValuesGroup,bugIndex,pValuesFobVsSG ,
pValuesLog10VolumeWithDirection,corCoeffVolumeBug) 
	
dFrame <- dFrame [order(dFrame$pValuesGroup),]
dFrame$pValuesAdjustedTime<- p.adjust( dFrame$pValuesTime, method = "BH" )
dFrame$pValuesAdjustedTumor<- p.adjust( dFrame$pValuesTumor, method = "BH" )
dFrame$pValuesAdjustedGroup<- p.adjust( dFrame$pValuesGroup, method = "BH" )	
dFrame$pValuesFobVsSGAdjusted <- p.adjust( dFrame$pValuesFobVsSG , method = "BH" )	
		
write.table(dFrame, file=paste0(project,"_model.txt"), row.names=FALSE, sep="\t")
	
pdf(paste0(project,'_model.pdf'))
par(mfrow=c(2,2))
	
for( i in 1:nrow(dFrame))
{
	bug <- myT[,dFrame$bugIndex[i]]
		
	if ( substr(toString(dFrame$bugNames[i]),1,3) != "MDS")
	{
		bug <- log(bug * 100000 + 1)	
	}
		
	aText <- paste0(  "time\n", dFrame$bugNames[i] ,  "\nq= ",format( dFrame$pValuesAdjustedTime[i],digits=3))
	boxplot( bug ~ time, main=aText,cex.main=.8,xlab="timepoint")
	
	myFrame <- data.frame( bug,time )
	
	stripchart(bug~ time, data = myFrame,vertical = TRUE, pch = 21, add=TRUE )		
			
	aText <- paste0(  "tumor volume" ,  "\nq= ",format( dFrame$pValuesAdjustedTumor[i],digits=3))
	plot( bug ~ volume,main=aText,cex.main=.8,xlab="tumor volume",col=treatmentColors ,pch=16, cex=1.3 )	
		
	aText <- paste0(  "treatment group" ,  "\nq= ",format( dFrame$pValuesAdjustedGroup[i],digits=3),
	"\n timepoint fob vs sg =", format( dFrame$pValuesFobVsSGAdjusted[i],digits=3))
	boxplot( bug ~ treatmentGroup,main=aText,cex.main=.8,xlab="treatment group")	
		
	boxplot( bug ~ cage, main ="cage", xlab="cage",las=2)	
}
	
dev.off()

