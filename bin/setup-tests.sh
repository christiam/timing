#!/bin/bash
# cmp-time.sh: What this script does
#
# Author: Christiam Camacho (camacho@ncbi.nlm.nih.gov)

INPUT_FILE=/net/snowman/vol/export2/camacho/work/aws/timing/data/quick_blastn.txt
JARFILE=/net/snowman/vol/export2/camacho/workspace/blastonspark/target/blastOnSpark-1.0.jar
rm etc/cmds.tab
for n in 64 32 16 8 4 ; do
	output=simple-search-$n.out
	echo -e "$n\tspark-submit --name \"blastxOnSpark on $n cores\" --master mesos://zk://mesos11:2181,mesos12:2181,mesos13:2181,/mesos --conf spark.executor.uri=hdfs://mesosdev/dist/spark-1.2.0-bin-2.5.0-cdh5.3.0.tgz --total-executor-cores $n --executor-memory 4G --driver-memory 2G --conf spark.executorEnv.NCBI=/etc --class gov.ncbi.blast.app.BlastOnSparkDaemon ${JARFILE} ${INPUT_FILE} $output DUMMY_RID" >> etc/cmds.tab
done
