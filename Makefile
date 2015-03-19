.PHONY: run clean reset dump graphs reset show purge
DATADIR=data
DBNAME=${DATADIR}/timings.db

run: ${DBNAME}
	bin/driver.pl -v -v -v -v -r 3

${DBNAME}:
	[ -d ${DATADIR} ] || mkdir ${DATADIR}
	sqlite3 ${DBNAME} < ddl/create.sql

dump: ${DBNAME}
	sqlite3 ${DBNAME} .dump

show: ${DBNAME}
	sqlite3 -header -column ${DBNAME} < ddl/select.sql
	bin/reports.pl -label all | sort -n

reset: ${DBNAME}
	sqlite3 ${DBNAME} < ddl/delete.sql

# Plots histograms of repeated tests
GRAPHS=\
blastx-185kb-query.png \
blastx-209kb-query.png \
blastx-214kb-query.png \
megablast-185kb-query.png \
megablast-209kb-query.png \
megablast-214kb-query.png 
GNUPLOT_DATA=data/timings.dat
GNUPLOT_CONF=etc/timings.gnuplot.conf

# Plots simple runtimes
GRAPH_SIMPLE=simple.png
GNUPLOT_DATA_SIMPLE=data/timings-simple.dat
GNUPLOT_CONF_SIMPLE=etc/simple.gnuplot.conf

simple: ${GRAPH_SIMPLE}
graphs: ${GRAPHS}

${GRAPHS}: ${GNUPLOT_DATA} ${GNUPLOT_CONF}
	gnuplot -e "idx=0; title='megablast runtime: 215kb query vs. nt'; output='megablast-215kb-query.png'; data_file='${GNUPLOT_DATA}'" ${GNUPLOT_CONF}
	gnuplot -e "idx=1; title='megablast runtime: 209kb query vs. nt'; output='megablast-209kb-query.png'; data_file='${GNUPLOT_DATA}'" ${GNUPLOT_CONF}
	gnuplot -e "idx=2; title='megablast runtime: 185kb query vs. nt'; output='megablast-185kb-query.png'; data_file='${GNUPLOT_DATA}'" ${GNUPLOT_CONF}
	gnuplot -e "idx=3; title='blastx runtime: 215kb query vs. nr'; output='blastx-215kb-query.png'; data_file='${GNUPLOT_DATA}'" ${GNUPLOT_CONF}
	gnuplot -e "idx=4; title='blastx runtime: 209kb query vs. nr'; output='blastx-209kb-query.png'; data_file='${GNUPLOT_DATA}'" ${GNUPLOT_CONF}
	gnuplot -e "idx=5; title='blastx runtime: 185kb query vs. nr'; output='blastx-185kb-query.png'; data_file='${GNUPLOT_DATA}'" ${GNUPLOT_CONF}

${GNUPLOT_DATA}: ${DBNAME}
	sqlite3 ${DBNAME} < ddl/select.sql | bin/data2gnuplot.pl > $@

${GNUPLOT_DATA_SIMPLE}: ${DBNAME}
	bin/reports.pl -label all | sort -n | awk '{print $$1, $$3, $$5, $$7, $$9}' > $@

${GRAPH_SIMPLE}: ${GNUPLOT_DATA_SIMPLE} ${GNUPLOT_CONF_SIMPLE}
	gnuplot -e "output='${GRAPH_SIMPLE}'; data_file='${GNUPLOT_DATA_SIMPLE}'" ${GNUPLOT_CONF_SIMPLE}

clean:
	-rm -f ${GNUPLOT_DATA} ${GRAPHS} ${GRAPH_SIMPLE} ${GNUPLOT_DATA} ${GNUPLOT_DATA_SIMPLE}

purge: clean
	-rm -f ${DBNAME} log/*

