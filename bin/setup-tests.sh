#!/bin/bash
# setup-tests.sh: Script to override etc
#
# Author: Christiam Camacho (camacho@ncbi.nlm.nih.gov)

CMDS_FILE=etc/cmds.tab
CMD_DIR=/net/snowman/vol/export2/camacho/work/aws/timing/data
INPUT_FILES="blast_cmd.1336.txt blast_cmd.15795.txt blast_cmd.139340.txt"
JARFILE=/net/snowman/vol/export2/camacho/workspace/blastonspark/target/blastOnSpark-1.0.jar
CLASS=gov.ncbi.blast.app.BlastOnSparkDaemon
#NUM_CORES="2 4 8 12"
#NUM_CORES="2 4 8 16 32 64 128"
NUM_CORES="128 64 32 16 8 4 2 "
# Yarn cluster at NCBI cannot take more than this
EXECUTOR_RAM=7808M
#EXECUTOR_RAM=2G
SLICES=10

# Update for BLAST+ baseline tests. Assumes query splits were generated using tools/fasta/split-fasta.sh
h=/home/ec2-user
fasta_input=${1:-$h/query.fna}
fasta_file_extension=$(echo $fasta_input | cut -f2 -d.)
fasta_file_prefix=$(echo $fasta_input | cut -f1 -d.)
db=${2:-ref_viruses_rep_genomes}
for n in 16 8 4 2 1; do
    dir=$h/queries-$n-parts
    cmds_file=$h/timing/etc/cmds-$n.tab

    if [ $n -eq 1 ] ; then
        echo -e "megablast-$n-parts\tblastn -query $fasta_input -db $db -evalue 0.001 -num_alignments 1 -num_threads 32 -outfmt '6 qseqid qlen sacc staxid sscinames slen pident evalue bitscore length' -out megablast-32-$n.out" > $cmds_file
    else
        for m in $(seq $n); do
            query=$fasta_file_prefix.part-$m.$fasta_file_extension
            echo -e "megablast-$n-parts-p$m\tblastn -query $query -db $db -evalue 0.001 -num_alignments 1 -num_threads $n -outfmt '6 qseqid qlen sacc staxid sscinames slen pident evalue bitscore length' -out megablast-$n-$m.out" >> $cmds_file;
        done
    fi
    

## rm -f $CMDS_FILE
## for f in ${INPUT_FILES}; do
## for n in ${NUM_CORES} ; do
## 	#output=simple-search-on-yarn-$n-cores.out
##     num_queries=$(echo $f|sed -e 's/blast_cmd.//;s/.txt//g')
##     label="${num_queries}q-$n"
## 	echo -e "$label\tspark-submit --name \"blastn nt vs $num_queries queries on $n cores\" --master mesos://zk://mesos11:2181,mesos12:2181,mesos13:2181,/mesos --conf spark.executor.uri=hdfs://mesosdev/dist/spark-1.2.0-bin-2.5.0-cdh5.3.0.tgz --total-executor-cores $n --executor-memory $EXECUTOR_RAM --driver-memory 2G --conf spark.executorEnv.NCBI=/etc --class ${CLASS} ${JARFILE} ${CMD_DIR}/$f $label DUMMY_RID" >> ${CMDS_FILE}
## 	#echo -e "$n\tspark-submit --name \"blastx $n cores\" --master yarn-client --num-executors $n --executor-memory $EXECUTOR_RAM --driver-memory 2G --class ${CLASS} ${JARFILE} $INPUT_FILE $output DUMMY_RID" >> ${CMDS_FILE} 
## 	#echo -e "$n\tspark-submit --name \"JavaSparkPi on $n cores\" --master local[$n] --class ${CLASS} ${JARFILE} $SLICES" >> ${CMDS_FILE}
##     #echo -e "blastx-100k-$n\tblastx -task blastx-fast -num_threads $n -searchsp 883742559635 -query /net/snowman/vol/export2/camacho/queries/100000-base-query.fsa -db nr -outfmt \"7 qseqid sseqid pident length mismatch gapopen gaps qstart qend sstart send\" -out /dev/null" >> ${CMDS_FILE}
## done
## done

### for n in ${NUM_CORES} ; do
###     echo -e "blastx-200k-$n\tblastx -task blastx-fast -num_threads $n -searchsp 883742559635 -query /net/snowman/vol/export2/camacho/queries/200000-base-query.fsa -db nr -outfmt \"7 qseqid sseqid pident length mismatch gapopen gaps qstart qend sstart send\" -out /dev/null" >> ${CMDS_FILE}
### done
### for n in ${NUM_CORES} ; do
###     echo -e "blastx-2500-$n\tblastx -task blastx-fast -num_threads $n -searchsp 883742559635 -query /net/snowman/vol/export2/camacho/queries/2500-base-query.fsa -db nr -outfmt \"7 qseqid sseqid pident length mismatch gapopen gaps qstart qend sstart send\" -out /dev/null" >> ${CMDS_FILE}
### done
### for n in ${NUM_CORES} ; do
###     echo -e "blastx-16500-$n\tblastx -task blastx-fast -num_threads $n -searchsp 883742559635 -query /net/snowman/vol/export2/camacho/queries/16500-base-query.fsa -db nr -outfmt \"7 qseqid sseqid pident length mismatch gapopen gaps qstart qend sstart send\" -out /dev/null" >> ${CMDS_FILE}
### done
