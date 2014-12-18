#!/usr/bin/env Rscript 

args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args)==2)

#http://stackoverflow.com/questions/5225823/how-to-subtract-months-from-a-date-in-r
tmp<-paste("-",args[1]," months", sep="")
sixmonths=seq(Sys.time(), length = 2, by = tmp)[2]


processing_table<-args[2]
#processing_ex<-args[2]
#processing_ts<-args[3]

table<-read.csv(processing_table, header=TRUE)
table_nopf <- subset(table, algorithm!='ProvisionFiles')
table_nopf <- subset(table_nopf, algorithm!='createdirs')
table_nopf <- subset(table_nopf, as.POSIXlt(create_tstmp)>sixmonths)

if (nrow(table_nopf)==0) {
	stop(paste("No processing events in the last",tmp,": since",sixmonths))
}

filename=basename(processing_table)

#ex<-read.csv(processing_ex, header=TRUE)
#ex_nopf <- subset(ex, algorithm!='ProvisionFiles')
#ex_nopf <- subset(ex_nopf, algorithm!='createdirs')
#ex_nopf <- subset(ex_nopf, as.POSIXlt(create_tstmp)>sixmonths)


#ts<-read.csv(processing_ts, header=TRUE)
#ts_nopf <- subset(ts, algorithm!='ProvisionFiles')
#ts_nopf <- subset(ts_nopf, algorithm!='createdirs')
#ts_nopf <- subset(ts_nopf, as.POSIXlt(create_tstmp)>sixmonths)


###HISTOGRAMS
pdf(paste("histogram-by-workflow",filename,"pdf", sep="."))
for (wf in levels(droplevels(table_nopf$name))) {
	newtable <- subset(table_nopf, name==wf)
	#newex<-subset(ex_nopf, name==wf)
	#newts<-subset(ts_nopf, name==wf)
	#mymax<-max(max(newtable$create_update,-Inf), max(newex$create_update, -Inf), max(newts$create_update, -Inf))/3600
	mymax<-max(newtable$create_update,-Inf)/3600
	bs<-c(seq(0,30,1), mymax)
	tableh<-hist(newtable$create_update/3600, plot=F, breaks=bs)
	plot(tableh, col=rgb(0,0,1,1/4), xlab='Job runtime (h)', main=paste('Histogram of',wf,'job runtimes(h)', sep=' '), freq=FALSE, xlim=range(0, min(mymax, 30)))
	
#	if (nrow(newex)>0) {
#		exh<-hist(newex$create_update/3600, plot=F, breaks=bs)
#		plot(exh, col=rgb(1,0,0,1/4), add=T,xlab='Job runtime (h)', main=paste('Histogram of',wf,'job runtimes(h)', sep=' ') , freq=FALSE, xlim=range(0, min(mymax, 30)))
#	}
#	if (nrow(newts)>0) {
#		tsh<-hist(newts$create_update/3600, plot=F, breaks=bs)
#		plot(tsh, col=rgb(0,1,0,1/4), add=T,xlab='Job runtime (h)', main=paste('Histogram of',wf,'job runtimes(h)', sep=' ') , freq=FALSE, xlim=range(0, min(mymax, 30)))
#	}
	
}
dev.off()

pdf(paste("boxplots-by-workflow-max",filename,"pdf", sep="."))
#take all the matrices and bind them together in a massive array
result<-do.call(rbind, lapply(levels(droplevels(table_nopf$name)), function(wf) {
	#pull out the workflow of interest
	data<-subset(table_nopf, name==wf)

	#in a workflow run, pull out the maximum run time for each job
	#there can be more than one job with a particular name so this finds
	#the longest path
	out <- lapply(levels(factor(data$workflow_run_id)),function(wf) {
		wf.data <- data[data$workflow_run_id==wf,]
		tapply(wf.data$create_update,droplevels(wf.data$algorithm),max)
	})
	names(out) <- levels(factor(data$workflow_run_id))

	#find the unique job names in the list and bind them together
	#in a matrix. Since different runs may have different job sets
	#we need to do this unique call and then rbind together
	categories <- unique(do.call(c,lapply(out,names)))
	what<-do.call(rbind,lapply(out, function(x) {
	    x[categories]
	}))
	colnames(what)<-categories

	#Make the box plot
	#extend the left margin so that it fits the longest name
	maxleft<-max(nchar(colnames(what)))/2
	par(mar=c(5,maxleft,4,2))
	#outliers are turned off so that this plot is less crazy
	boxplot(what/3600, horizontal=T, outline=F, las=2, xlab='Max Duration(h)', main=paste("Max job duration for workflow", wf, sep=" "), labels=categories )
	
	#calculate the means and medians for each job and return this matrix
	means<-apply(what/3600,2,mean,na.rm=TRUE)
	medians<-apply(what/3600,2,median,na.rm=TRUE)
	counts<-sapply(levels(droplevels(data$algorithm)), function(algo) { nrow(data[data$algorithm==algo,]) })
	stddevs<-apply(what/3600,2,sd,na.rm=TRUE)
	matrix(c(medians, means, stddevs, counts), ncol=4, dimnames=list(paste(wf, colnames(what)), c("median","mean", "stddev", "counts")))
}))
write.csv(result,file=paste("stats_by_workflow_job",filename,"csv",sep="."))
dev.off()
