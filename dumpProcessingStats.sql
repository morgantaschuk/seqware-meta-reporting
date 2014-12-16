-----Make a copy of the processing table with just the fields we need and also pre-filtered
-----record the workflow name, workflow run ID, and all timestamps from the processing table
-----also filter to make sure the processing step didn't fail and the workflow is complete
create temporary table processing_new as
select w.name, wr.workflow_run_id, p.create_tstmp, p.update_tstmp, p.algorithm, p.run_stop_tstmp, p.run_start_tstmp from processing p
    join workflow_run wr on (p.workflow_run_id=wr.workflow_run_id OR p.ancestor_workflow_run_id=wr.workflow_run_id)
    join workflow w on (w.workflow_id = wr.workflow_id)
where
    p.create_tstmp is not null and p.update_tstmp is not null
    and p.status!='failed'
    and wr.status='completed';
;

-------Some of our jobs are poorly named. this corrects job names in the new table so that they can be better aggregated
update processing_new set algorithm='FastXTrim' where algorithm like 'FastXTrim%';
update processing_new set algorithm='clipProfile' where algorithm like 'clipProfile%';
update processing_new set algorithm='geneBody' where algorithm like 'geneBody%';
update processing_new set algorithm='inferExperiment' where algorithm like 'inferExperiment%';
update processing_new set algorithm='innerDistance' where algorithm like 'innerDistance%';
update processing_new set algorithm='junctionAnnotation' where algorithm like 'junctionAnnotation%';
update processing_new set algorithm='junctionSaturation' where algorithm like 'junctionSaturation%';
update processing_new set algorithm='readDistribution' where algorithm like 'readDistribution%';
update processing_new set algorithm='readDuplication' where algorithm like 'readDuplication%';
update processing_new set algorithm='readGC' where algorithm like 'readGC%';
update processing_new set algorithm='readNVC' where algorithm like 'readNVC%';
update processing_new set algorithm='readQuality' where algorithm like 'readQuality%';
update processing_new set algorithm='bamStats' where algorithm like 'bamStats%';
update processing_new set algorithm='average_coverage' where algorithm like 'average_coverage%';
update processing_new set algorithm='flagstatOfftargetRM' where algorithm like 'flagstat_OffTarget.RM%';
update processing_new set algorithm='flagstatOfftargetRM' where algorithm like 'flagstat_OffTarget_RM%';
update processing_new set algorithm='flagstatOfftargetSD' where algorithm like 'flagstat_OffTarget.SD%';
update processing_new set algorithm='flagstatOfftargetSD' where algorithm like 'flagstat_OffTarget_SD%';
update processing_new set algorithm='flagstatOfftarget' where algorithm like 'flagstat_OffTarget%';
update processing_new set algorithm='flagstatOntargetRM' where algorithm like 'flagstat_OnTarget.RM%';
update processing_new set algorithm='flagstatOntargetRM' where algorithm like 'flagstat_OnTarget_RM%';
update processing_new set algorithm='flagstatOntargetSD' where algorithm like 'flagstat_OnTarget.SD%';
update processing_new set algorithm='flagstatOntargetSD' where algorithm like 'flagstat_OnTarget_SD%';
update processing_new set algorithm='flagstatOntarget' where algorithm like 'flagstat_OnTarget%';
update processing_new set algorithm='ontargetRMReads' where algorithm like 'ontarget%RM%reads';
update processing_new set algorithm='flagstat' where algorithm like 'flagstat_%';
update processing_new set algorithm='offtarget_reads' where algorithm like 'offtarget_reads%';
update processing_new set algorithm='offtargetReadsSD' where algorithm like 'offtarget%SD%reads%';
update processing_new set algorithm='offtargetReadsRM' where algorithm like 'offtarget%RM%reads%';
update processing_new set algorithm='ontarget_reads' where algorithm like 'ontarget_reads%';
update processing_new set algorithm='ontargetReadsSD' where algorithm like 'ontarget%SD%reads%';
update processing_new set algorithm='ontargetReadsRM' where algorithm like 'ontarget%RM%reads%';
update processing_new set algorithm='percent_coverage' where algorithm like 'percent_coverage%';
update processing_new set algorithm='Novoalign' where algorithm = 'novoalign_0';
update processing_new set algorithm='PicardAddReadGroups' where algorithm ='PicardAddReadGroups_0';
update processing_new set algorithm='Bustard' where algorithm='ID10_Bustard';
update processing_new set algorithm='BamToJsonStats' where algorithm='bamToJsonStats';

-----calculate the span between create and update, and start and stop for all entries
create temporary table processing_all as
    select 
	name, algorithm, create_tstmp,
	abs(extract(epoch from (p.create_tstmp - p.update_tstmp))) as create_update,
        abs(extract(epoch from (p.run_stop_tstmp - p.run_start_tstmp))) as stop_start,
	workflow_run_id
    from processing_new p
    ;

\copy (select * from processing_all) to 'processing_all.csv' CSV HEADER


-----for just EX samples, calculate the span between create and update, and start and stop
create temporary table processing_ex as
    select
        name, algorithm, create_tstmp,
        abs(extract(epoch from (p.create_tstmp - p.update_tstmp))) as create_update,
        abs(extract(epoch from (p.run_stop_tstmp - p.run_start_tstmp))) as stop_start,
	workflow_run_id
    from processing_new p
	where 
	workflow_run_id in (
            select workflow_run_id from ius_workflow_runs
               join ius i using (ius_id)
               join sample s using (sample_id)
            where s.name like '%_EX'
         )
    ;

\copy (select * from processing_ex) to 'processing_ex.csv' CSV HEADER

-----for just WG samples, calculate the span between create and update, and start and stop
create temporary table processing_wg as
    select
        name, algorithm, create_tstmp,
        abs(extract(epoch from (p.create_tstmp - p.update_tstmp))) as create_update,
        abs(extract(epoch from (p.run_stop_tstmp - p.run_start_tstmp))) as stop_start,
	workflow_run_id
    from processing_new p
        where
        workflow_run_id in (
            select workflow_run_id from ius_workflow_runs
               join ius i using (ius_id)
               join sample s using (sample_id)
            where s.name like '%_WG'
         )
    ;   

\copy (select * from processing_wg) to 'processing_wg.csv' CSV HEADER

-----for just TS samples, calculate the span between create and update, and start and stop
create temporary table processing_ts as
    select
        name, algorithm, create_tstmp,
        abs(extract(epoch from (p.create_tstmp - p.update_tstmp))) as create_update,
        abs(extract(epoch from (p.run_stop_tstmp - p.run_start_tstmp))) as stop_start,
	workflow_run_id
    from processing_new p
        where 
        workflow_run_id in (
            select workflow_run_id from ius_workflow_runs
               join ius i using (ius_id)
               join sample s using (sample_id)
            where s.name like '%_TS'
         )
    ;
\copy (select * from processing_ts) to 'processing_ts.csv' CSV HEADER
