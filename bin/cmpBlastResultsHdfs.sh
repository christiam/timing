#!/bin/bash
# cmp.sh: What this script does
#
# Author: Christiam Camacho (camacho@ncbi.nlm.nih.gov)

INPUT_FILE=/net/snowman/vol/export2/camacho/work/aws/timing/data/quick_blastn.txt
NUM_REPEATS=5
OUTPUT_BASE_NAME=simple-search
OUTPUT_BASE_NAME=simple-search-on-mesos
OUTPUT_BASE_NAME=simple-search-on-yarn
NUM_CORES_MINUS_1ST="4 8 12"
NUM_CORES_MINUS_1ST="4 8 16 32 64 128"
NUM_CORES="2 ${NUM_CORES_MINUS_1ST}"

# Only needed for Yarn
#. ~/hadoop/setenv.sh

set -xe
if [ ! -f ref.out ] ; then
    sh -x $INPUT_FILE > ref.out
fi
for n in ${NUM_CORES}; do
    # Download hadoop output and remove it from HDFS
    for m in $(seq 1 $NUM_REPEATS); do
        hadoop fs -getmerge $OUTPUT_BASE_NAME-$n-cores.out-$m $n-$m.out
        hadoop fs -rm -f -r $OUTPUT_BASE_NAME-$n-cores.out-$m
    done
    # Remove the duplicates from hadoop, as they should be identical
    for m in $(seq 2 $NUM_REPEATS); do
        cmp $n-1.out $n-$m.out
        if [ $? == 0 ] ; then
            rm $n-$m.out
        else
            echo "Warning: found diff in BLAST output when for multiple runs of the same command"
        fi
    done
done

for n in ${NUM_CORES_MINUS_1ST}; do
    cmp 2-1.out $n-1.out
    if [ $? == 0 ] ; then
        rm $n-1.out
    fi
done

grep -v '^#' ref.out | sort > ref-no-comment-sort.out
grep -v '^#' 2-1.out | sort > 2-1-no-comment-sort.out
cmp ref-no-comment-sort.out 2-1-no-comment-sort.out
if [ $? == 0 ] ; then
    rm ref-no-comment-sort.out 2-1-no-comment-sort.out 2-1.out ref.out
fi
