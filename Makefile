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

reset: ${DBNAME}
	sqlite3 ${DBNAME} < ddl/delete.sql

GRAPHS=\
blastx-185kb-query.png \
blastx-209kb-query.png \
blastx-214kb-query.png \
megablast-185kb-query.png \
megablast-209kb-query.png \
megablast-214kb-query.png 
GNUPLOT_DATA=data/timings.dat
GNUPLOT_CONF=etc/timings.gnuplot.conf

graphs: ${GRAPHS}

${GRAPHS}: ${GNUPLOT_DATA} ${GNUPLOT_CONF}
	gnuplot -e "idx=0; title='megablast runtime: 215kb query vs. nt'; output='megablast-215kb-query.png'; data_file='${GNUPLOT_DATA}'" ${GNUPLOT_CONF}
	gnuplot -e "idx=1; title='megablast runtime: 209kb query vs. nt'; output='megablast-209kb-query.png'; data_file='${GNUPLOT_DATA}'" ${GNUPLOT_CONF}
	gnuplot -e "idx=2; title='megablast runtime: 185kb query vs. nt'; output='megablast-185kb-query.png'; data_file='${GNUPLOT_DATA}'" ${GNUPLOT_CONF}
	gnuplot -e "idx=3; title='blastx runtime: 215kb query vs. nr'; output='blastx-215kb-query.png'; data_file='${GNUPLOT_DATA}'" ${GNUPLOT_CONF}
	gnuplot -e "idx=4; title='blastx runtime: 209kb query vs. nr'; output='blastx-209kb-query.png'; data_file='${GNUPLOT_DATA}'" ${GNUPLOT_CONF}
	gnuplot -e "idx=5; title='blastx runtime: 185kb query vs. nr'; output='blastx-185kb-query.png'; data_file='${GNUPLOT_DATA}'" ${GNUPLOT_CONF}
	if [ -s $@ ] ; then cp -v $@ ~/ ; else rm -f $@; fi

${GNUPLOT_DATA}: ${DBNAME}
	sqlite3 ${DBNAME} < ddl/select.sql | bin/data2gnuplot.pl > ${GNUPLOT_DATA}

clean:
	-rm -f ${GNUPLOT_DATA} ${GRAPHS}

purge:
	-rm -f ${DBNAME} log/*

