seqware-meta-reporting
======================

A few scripts that crawl through OICR's seqware_meta_db and report pertinent statistics.

The scripts require direct DB access to execute SQL commands and use R to generate statistics and graphs.


Notes
-----------
SQL
* We only support exome, whole genome and targeted sequencing for genomic DNA at the moment.
* We rely on the library sample (lowest sample in the sample_hierarchy) to have a name containing one of three suffices: WG for whole genome libraries, EX for exome libraries, and TS for targeted sequencing libraries
* We homogenize some of our job names (full list in dumpProcessingStats.sql) so that they can be calculated over
* We rely on a user's ~/.pgpass file to be set up with the appropriate passwords to the database

R
* We assume that jobs with the same name are launched simultaneously for a single workflow run


Usage
-----

h3. Data files
First, run the SQL script dumpProcessingStats.sql in order to generate csv files with the relevant information.

    psql -f dumpProcessingStats.sql -h seqwaremetabb.host seqware_meta_db

This script puts four files in your current working directory: processing_all.csv, processing_wg.csv, processing_ex.csv, and processing_ts.csv. 

The CSV file format has a header with the following columns: name,algorithm,create_tstmp,create_update,stop_start,workflow_run_id. Each line corresponds to a single job that executed in SeqWare.

* name - the name of the workflow
* algorithm - the job name corresponding to 'algorithm' in the processing table
* create_tstmp - when the job started
* create_update - the difference between the last updated time and the creation time. We use this as the total duration of the job.
* stop_start - the different between run_stop_time and run_start_time. This corresponds to the amount of time the wrapped command took to run inside the SeqWare system. The difference between create_update and stop_start is the amount of overhead SeqWare adds per job.
* worklflow_run_id - the unique ID of the workflow run that owns the job

h3. Statistics and graphs

Once you have these files, you can run the R script to calculate summary statistics and produce several graphs. The first argument is the number of months in the past for which the information should be calculates (e.g. "6" would calculate from 6 months ago to the present time). The second argument is the file that should be used to produce the statistics. In this example we use the whole genome file (processing_wg.csv), but you can also calculate over all jobs, exome jobs and targeted sequencing jobs.

    Rscript calculateStatsByWorkflowJob.R 6 processing_wg.csv

The script produces two PDFs and a CSV file. 

* histogram-by-workflow.<filename>.pdf : histograms for each workflow showing the runtimes of each job
* boxplots-by-workflow-max.<filename>.pdf : boxplots by job duration by workflow. The script finds the longest running time of a distinct job name in a particular workflow run and reports that as the 'max'. In a perfect world, the jobs with the same name would be run simultaneously and therefore the job of the longest duration would represent the critical path.
* stats_by_workflow_job.<filename>.csv : Summary statistics by job and workflow. The CSV has a header: "", median, mean, stddev, counts. The first column is the name of the workflow plus the algorithm/job name. The following columns are summary statistics about the longest-running job by that name in a workflow run, as well as the total count of each job in the full dataset.


Support
---------
For support, email pde.jira@oicr.on.ca.




