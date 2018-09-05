rm(list=ls())

setwd("C:\\LauraProjects_May_2018\\ier_Sleeve_merged")
myT <- read.table("IER_SleevepariedPValuesMerged.txt", header=TRUE,sep="\t")

plot(myT$Sleeve_DIO_FOb, myT$IER_DIO_FOb,pch=15,cex=1.2,xlab="Sleeve dio vs FoB", ylab= "ier dio vs Fob")