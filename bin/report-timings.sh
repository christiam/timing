#!/bin/bash
# report-timings.sh: Produce table of results for S3 jim report
#
# Author: Christiam Camacho (camacho@ncbi.nlm.nih.gov)

DB=data/timings.db
PRODUCE_CSV=1

query_db() {
	label=$1

    # For visualization
    if [ $PRODUCE_CSV == 0 ] ; then
        echo "Initial $label run"
        sqlite3 -column -header $DB \
            "select avg(elapsed_time) as avg_elapsed, \
                    max(elapsed_time) as max_elapsed, \
                    min(elapsed_time) as min_elapsed, \
                    avg(system_time) as avg_system, \
                    max(system_time) as max_system, \
                    min(system_time) as min_system, \
                    avg(user_time) as avg_user, \
                    max(user_time) as max_user, \
                    min(user_time) as min_user, \
                    count(user_time) as num_experiments \
            from runtime where \
                    hostname like 'ip%211-43' and \
                    label like '$label-I%-1'"

        echo "Subsequent $label runs"
        sqlite3 -column -header $DB \
            "select avg(elapsed_time) as avg_elapsed, \
                    max(elapsed_time) as max_elapsed, \
                    min(elapsed_time) as min_elapsed, \
                    avg(system_time) as avg_system, \
                    max(system_time) as max_system, \
                    min(system_time) as min_system, \
                    avg(user_time) as avg_user, \
                    max(user_time) as max_user, \
                    min(user_time) as min_user, \
                    count(user_time) as num_experiments \
            from runtime where \
                    hostname like 'ip%211-43' and \
                    label like '$label-I%-2' or label like '$label-I%-3' or label like '$label-I%-4'"
    else
        # For importing into excel

        sqlite3 -csv $DB \
            "select '$label-1', avg(elapsed_time) as avg_elapsed, \
                    max(elapsed_time) as max_elapsed, \
                    min(elapsed_time) as min_elapsed, \
                    avg(system_time) as avg_system, \
                    max(system_time) as max_system, \
                    min(system_time) as min_system, \
                    avg(user_time) as avg_user, \
                    max(user_time) as max_user, \
                    min(user_time) as min_user, \
                    count(user_time) as num_experiments \
            from runtime where \
                    hostname like 'ip%211-43' and \
                    label like '$label-I%-1'"
        sqlite3 -csv $DB \
            "select '$label-2', avg(elapsed_time) as avg_elapsed, \
                    max(elapsed_time) as max_elapsed, \
                    min(elapsed_time) as min_elapsed, \
                    avg(system_time) as avg_system, \
                    max(system_time) as max_system, \
                    min(system_time) as min_system, \
                    avg(user_time) as avg_user, \
                    max(user_time) as max_user, \
                    min(user_time) as min_user, \
                    count(user_time) as num_experiments \
            from runtime where \
                    hostname like 'ip%211-43' and \
                    label like '$label-I%-2' or label like '$label-I%-3' or label like '$label-I%-4'"
    fi
}

if [ $PRODUCE_CSV == 1 ] ; then
    echo "Test_case,avg_elapsed,max_elapsed,min_elapsed,avg_system,max_system,min_system,avg_user,max_user,min_user,num_tests"
fi
query_db "blastp"
query_db "megablast"

query_db "blastp-s3"
query_db "megablast-s3"

query_db "blastp-rfs3"
query_db "megablast-rfs3"

# Dump download times for DBs so they can be added to the S3 only results
if [ $PRODUCE_CSV == 1 ] ; then
    for db in nt nr; do
        sqlite3 -csv $DB \
            "select label, \
                    avg(elapsed_time),\
                    max(elapsed_time),\
                    min(elapsed_time),\
                    avg(system_time),\
                    max(system_time),\
                    min(system_time),\
                    avg(user_time),\
                    max(user_time),\
                    min(user_time),\
                    count(*) 
            from runtime where label like 'download_$db%'"
    done
fi
