seqware-meta-reporting
======================

A few scripts that crawl through OICR's seqware_meta_db and report pertinent statistics.

The scripts require direct DB access to execute SQL commands and use R to generate statistics and graphs.


Assumptions
-----------
SQL
* We only support exome, whole genome and targeted sequencing for genomic DNA at the moment.
* We rely on the library sample (lowest sample in the sample_hierarchy) to have a name containing one of three suffices: WG for whole genome libraries, EX for exome libraries, and TS for targeted sequencing libraries
* We homogenize some of our job names (full list in dumpProcessingStats.sql) so that they can be calculated over

R
* We assume that jobs with the same name are launched simultaneously for a single workflow run


Usage
-----
First, run the SQL script dumpProcessingStats.sql in order to generate csv files with the relevant information.

    psql -f dumpProcessingStats.sql -h seqwaremetabb.host seqware_meta_db

This script puts four files in your current working directory: processing_all.csv, processing_wg.csv, processing_ex.csv, and processing_ts.csv. Once you have these files, you can run the R script:

    Rscript calculateStatsByWorkflowJob.R processing_wg.csv processing_ex.csv processing_ts.csv > results

There are two PDFs and a text file produced from this. 

* histogram-by-workflow.pdf : a simple set of histograms for each workflow showing the runtimes of each job in a distribution. Red - WG, Blue - EX, Green - TS
* boxplots-by-workflow-max.pdf : boxplots by job duration by workflow. The script finds the longest running time of a distinct job name in a particular workflow run and reports that as the 'max'. In a perfect world, the jobs with the same name would be run simultaneously and therefore the job of the longest duration would represent the critical path.
* text file : CSV of "Workflow JobName, median, mean, stddev, counts"




