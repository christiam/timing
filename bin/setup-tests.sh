#!/bin/bash
# setup-tests.sh: Script to override etc
#
# Author: Christiam Camacho (camacho@ncbi.nlm.nih.gov)

CMDS_FILE=etc/cmds.tab
INPUT_FILE=/net/snowman/vol/export2/camacho/work/aws/timing/data/quick_blastn.txt
INPUT_FILE=/net/snowman/vol/export2/camacho/work/aws/timing/data/blastdbcmd_nt.txt
JARFILE=/net/snowman/vol/export2/camacho/workspace/blastonspark/target/blastOnSpark-1.0.jar
CLASS=gov.ncbi.blast.app.BlastOnSparkDaemon
NUM_CORES="2 4 8 12"
#NUM_CORES="2 4 8 16 32 64 128"
#NUM_CORES="128 64 32 16 8 4 2 "
NUM_CORES="4 2 "
# Yarn cluster at NCBI cannot take more than this
EXECUTOR_RAM=7808M
EXECUTOR_RAM=2G
SLICES=10

rm $CMDS_FILE
for n in ${NUM_CORES} ; do
	output=simple-search-on-yarn-$n-cores.out
	#echo -e "$n\tspark-submit --name \"JavaSparkPi on $n cores\" --master mesos://zk://mesos11:2181,mesos12:2181,mesos13:2181,/mesos --conf spark.executor.uri=hdfs://mesosdev/dist/spark-1.2.0-bin-2.5.0-cdh5.3.0.tgz --total-executor-cores $n --executor-memory $EXECUTOR_RAM --driver-memory 2G --conf spark.executorEnv.NCBI=/etc --class ${CLASS} ${JARFILE} $SLICES" >> ${CMDS_FILE}
	echo -e "$n\tspark-submit --name \"blastx $n cores\" --master yarn-client --num-executors $n --executor-memory $EXECUTOR_RAM --driver-memory 2G --class ${CLASS} ${JARFILE} $INPUT_FILE $output DUMMY_RID" >> ${CMDS_FILE} 
	#echo -e "$n\tspark-submit --name \"JavaSparkPi on $n cores\" --master local[$n] --class ${CLASS} ${JARFILE} $SLICES" >> ${CMDS_FILE}
done
echo "run make run simple show NUM_REPEATS=5 GRAPH_SIMPLE=filename.png TITLE_SIMPLE=title"
