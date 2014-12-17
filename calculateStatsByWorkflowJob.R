#!/usr/bin/Rscript 

args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args)==3)
processing_wg<-args[1]
processing_ex<-args[2]
processing_ts<-args[3]

#http://stackoverflow.com/questions/1962278/dealing-with-timestamps-in-r
sixmonths=seq(Sys.time(), length = 2, by = "-6 months")[2]

wg<-read.csv(processing_wg, header=TRUE)
wg_nopf <- subset(wg, algorithm!='ProvisionFiles')
wg_nopf <- subset(wg_nopf, algorithm!='createdirs')
wg_nopf <- subset(wg_nopf, as.POSIXlt(create_tstmp)>sixmonths)

ex<-read.csv(processing_ex, header=TRUE)
ex_nopf <- subset(ex, algorithm!='ProvisionFiles')
ex_nopf <- subset(ex_nopf, algorithm!='createdirs')
ex_nopf <- subset(ex_nopf, as.POSIXlt(create_tstmp)>sixmonths)


ts<-read.csv(processing_ts, header=TRUE)
ts_nopf <- subset(ts, algorithm!='ProvisionFiles')
ts_nopf <- subset(ts_nopf, algorithm!='createdirs')
ts_nopf <- subset(ts_nopf, as.POSIXlt(create_tstmp)>sixmonths)


###HISTOGRAMS
pdf("histogram-by-workflow.pdf")
for (wf in levels(droplevels(wg_nopf$name))) {
	newwg <- subset(wg_nopf, name==wf)
	newex<-subset(ex_nopf, name==wf)
	newts<-subset(ts_nopf, name==wf)
	mymax<-max(max(newwg$create_update,-Inf), max(newex$create_update, -Inf), max(newts$create_update, -Inf))/3600
	bs<-c(seq(0,30,1), mymax)
	wgh<-hist(newwg$create_update/3600, plot=F, breaks=bs)
	plot(wgh, col=rgb(0,0,1,1/4), xlab='Job runtime (h)', main=paste('Histogram of',wf,'job runtimes(h)', sep=' '), freq=FALSE, xlim=range(0, min(mymax, 30)))
	
	if (nrow(newex)>0) {
		exh<-hist(newex$create_update/3600, plot=F, breaks=bs)
		plot(exh, col=rgb(1,0,0,1/4), add=T,xlab='Job runtime (h)', main=paste('Histogram of',wf,'job runtimes(h)', sep=' ') , freq=FALSE, xlim=range(0, min(mymax, 30)))
	}
	if (nrow(newts)>0) {
		tsh<-hist(newts$create_update/3600, plot=F, breaks=bs)
		plot(tsh, col=rgb(0,1,0,1/4), add=T,xlab='Job runtime (h)', main=paste('Histogram of',wf,'job runtimes(h)', sep=' ') , freq=FALSE, xlim=range(0, min(mymax, 30)))
	}
	
}
dev.off()

pdf("boxplots-by-workflow-max.pdf")
#take all the matrices and bind them together in a massive array
result<-do.call(rbind, lapply(levels(wg_nopf$name), function(wf) {
	#pull out the workflow of interest
	data<-subset(wg_nopf, name==wf)

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
write.csv(result)
dev.off()
