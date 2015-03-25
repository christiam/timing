#!/bin/bash
# setup-tests.sh: Script to override etc
#
# Author: Christiam Camacho (camacho@ncbi.nlm.nih.gov)

CMDS_FILE=etc/cmds.tab
INPUT_FILE=/net/snowman/vol/export2/camacho/work/aws/timing/data/quick_blastn.txt
JARFILE=/usr/local/spark/1.2.0/lib/spark-examples-1.2.0-hadoop2.5.0-cdh5.3.0.jar 
CLASS=org.apache.spark.examples.JavaSparkPi
SLICES=10

rm $CMDS_FILE
#for n in 2 4 8 12 ; do
for n in 2 4 8 16 32 64 128 ; do
	echo -e "$n\tspark-submit --name \"JavaSparkPi on $n cores\" --master mesos://zk://mesos11:2181,mesos12:2181,mesos13:2181,/mesos --conf spark.executor.uri=hdfs://mesosdev/dist/spark-1.2.0-bin-2.5.0-cdh5.3.0.tgz --total-executor-cores $n --executor-memory 4G --driver-memory 2G --conf spark.executorEnv.NCBI=/etc --class ${CLASS} ${JARFILE} $SLICES" >> ${CMDS_FILE}
	#echo -e "$n\tspark-submit --name \"JavaSparkPi on $n cores\" --master yarn-client --num-executors $n --class ${CLASS} ${JARFILE} $SLICES" >> ${CMDS_FILE} 
	#echo -e "$n\tspark-submit --name \"JavaSparkPi on $n cores\" --master local[$n] --class ${CLASS} ${JARFILE} $SLICES" >> ${CMDS_FILE}
done
echo "run make run simple show NUM_REPEATS=5 GRAPH_SIMPLE=filename.png TITLE_SIMPLE=title"
