#!/bin/bash
# make-graphs.sh: make stacked bar charts for test cases
#
# Author: Christiam Camacho (camacho@ncbi.nlm.nih.gov)

DB=data/timings.db
GNUPLOT_DATA=$$.dat
GNUPLOT_CONF=$$.conf
RATIOS=$$.ratios
DEBUG=0

trap "rm $GNUPLOT_DATA $GNUPLOT_CONF $RATIOS" KILL EXIT

make_gnuplot_conf_stacked_bars() {
    title=$1
    output=$2
    cat > $GNUPLOT_CONF <<EOF
set title "$title"
set xlabel "Data source"
set ylabel "Average time (seconds)"
set style data histograms
set style histogram rowstacked
set boxwidth 1 relative
set style fill solid 1.0 border -1
set grid
set datafile separator ","
#set key outside below Left title 'Legend' box
set terminal png
set output "$output.png"
set xtics ("remote-fuser from NCBI" 0, "Local disk" 1, "remote-fuser from S3" 2)
plot '$GNUPLOT_DATA' using 2 t "search time", '' using 3 t "download time from S3"
EOF
}

make_gnuplot_conf() {
    title=$1
    output=$2
    cat > $GNUPLOT_CONF <<EOF
set title "$title"
set xlabel "Data source"
set ylabel "Average time (seconds)"
set style data histograms
set style histogram rowstacked
set boxwidth 1 relative
set style fill solid 1.0 border -1
set grid
set datafile separator ","
set terminal png
set output "$output.png"
set xtics ("remote-fuser from NCBI" 0, "Local disk" 1, "remote-fuser from S3" 2)
plot '$GNUPLOT_DATA' using 2 notitle
EOF
}

get_first_run_data_no_download() {
    label=$1
    column=$2
    sqlite3 -csv $DB "select '$label-1', avg($column), 0, count(*) from runtime where \
        hostname like 'ip%211-43' and label like '$label-I%-1'"
}
get_first_run_data_download() {
    label=$1
    db=$2
    column=$3
    sqlite3 -csv $DB "\
        select '$label-1', avg($column), \
            (select avg($column) from runtime where label like 'download_$db%'), \
            count(*)
            from runtime where \
        hostname like 'ip%211-43' and label like '$label-I%-1'"
}
get_subsequent_data() {
    label=$1
    column=$2
    sqlite3 -csv $DB "select '$label-2', avg($column),count(*) from runtime where \
        hostname like 'ip%211-43' and \
        label like '$label-I%-2' or label like '$label-I%-3' or label like '$label-I%-4'"
}

for metric in 'elapsed_time' 'system_time' 'user_time'; do
    t=$(echo $metric | sed 's/_/ /')
    get_first_run_data_no_download "blastp" "$metric" > $GNUPLOT_DATA
    get_first_run_data_download "blastp-s3" "nr" "$metric" >>$GNUPLOT_DATA
    get_first_run_data_no_download "blastp-rfs3" "$metric" >>$GNUPLOT_DATA
    make_gnuplot_conf_stacked_bars "Initial blastp run ($t)" "blastp-1-$metric"
    gnuplot < $GNUPLOT_CONF
    if [ $DEBUG == 1 ] ; then
        cp $GNUPLOT_DATA blastp-1-$metric.dat
        cp $GNUPLOT_CONF blastp-1-$metric.conf
    fi
    echo "# blastp-1-$metric" >> $RATIOS
    bin/ratios.pl < $GNUPLOT_DATA >> $RATIOS

    get_first_run_data_no_download "megablast" "$metric" > $GNUPLOT_DATA
    get_first_run_data_download "megablast-s3" "nt" "$metric" >>$GNUPLOT_DATA
    get_first_run_data_no_download "megablast-rfs3" "$metric" >>$GNUPLOT_DATA
    make_gnuplot_conf_stacked_bars "Initial megablast run ($t)" "megablast-1-$metric"
    gnuplot < $GNUPLOT_CONF
    if [ $DEBUG == 1 ] ; then
        cp $GNUPLOT_DATA megablast-1-$metric.dat
        cp $GNUPLOT_CONF megablast-1-$metric.conf
    fi
    echo "# megablast-1-$metric" >> $RATIOS
    bin/ratios.pl < $GNUPLOT_DATA >> $RATIOS

    get_subsequent_data "blastp" "$metric" > $GNUPLOT_DATA
    get_subsequent_data "blastp-s3" "$metric" >> $GNUPLOT_DATA
    get_subsequent_data "blastp-rfs3" "$metric" >> $GNUPLOT_DATA
    make_gnuplot_conf "Subsequent blastp runs ($t)" "blastp-2-$metric"
    gnuplot < $GNUPLOT_CONF
    if [ $DEBUG == 1 ] ; then
        cp $GNUPLOT_DATA blastp-2-$metric.dat
        cp $GNUPLOT_CONF blastp-2-$metric.conf
    fi
    echo "# blastp-2-$metric" >> $RATIOS
    bin/ratios.pl < $GNUPLOT_DATA >> $RATIOS

    get_subsequent_data "megablast" "$metric" > $GNUPLOT_DATA
    get_subsequent_data "megablast-s3" "$metric" >> $GNUPLOT_DATA
    get_subsequent_data "megablast-rfs3" "$metric" >> $GNUPLOT_DATA
    make_gnuplot_conf "Subsequent megablast runs ($t)" "megablast-2-$metric"
    gnuplot < $GNUPLOT_CONF
    if [ $DEBUG == 1 ] ; then
        cp $GNUPLOT_DATA megablast-2-$metric.dat
        cp $GNUPLOT_CONF megablast-2-$metric.conf
    fi
    echo "# megablast-2-$metric" >> $RATIOS
    bin/ratios.pl < $GNUPLOT_DATA >> $RATIOS
done
cat $RATIOS
