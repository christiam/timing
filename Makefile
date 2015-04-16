DATADIR=data
DBNAME=${DATADIR}/timings.db
NUM_REPEATS=1

BASIC_GNUPLOT_CONF=etc/basic.gnuplot.conf
VPATH = $(DATADIR)

TIMING_NAME=blastx-555-vs-nr09
GRAPHS=$(TIMING_NAME).png
TITLE=blastx search of nr.09
GNUPLOT_DATA=data/$(TIMING_NAME).dat
#GNUPLOT_CONF=etc/basic.gnuplot.conf
#GNUPLOT_CONF=etc/timings.gnuplot.conf
GNUPLOT_CONF=etc/multi-series.gnuplot.conf
#GNUPLOT_CONF_SIMPLE=etc/simple.gnuplot.conf

# Plots histograms of repeated tests
### GRAPHS=\
### blastx-185kb-query.png \
### blastx-209kb-query.png \
### blastx-214kb-query.png \
### megablast-185kb-query.png \
### megablast-209kb-query.png \
### megablast-214kb-query.png 

## Plots simple runtimes
#GRAPH_SIMPLE=estimatePiMesos.png
#TITLE_SIMPLE=Replace me
#GNUPLOT_DATA_SIMPLE=data/timings-simple.dat

.PHONY: all
all: ${DBNAME}
	bin/driver.pl -v -v -v -v -s
	#bin/driver.pl -v -v -v -v -s -repeats $(NUM_REPEATS) -rm_core_files

$(DBNAME): setup

%.db:
	sqlite3 $@ < ddl/create.sql

%.png: %.dat
	if [ -z "$T" ] ; then echo "Must define the T make variable for graph title"; exit 1; fi
	gnuplot -e "output='$@';title='$T'; data_file='$^'" $(BASIC_GNUPLOT_CONF)

%.dat: $(DBNAME)
	if [ -z "$Q" ] ; then echo "Must define the Q make variable to query $(DBNAME)"; exit 1; fi
	sqlite3 $^ "select label, ellapsed_time from runtime where label like '$Q-%'" | sed -e 's/$Q-//' | sort -n > $@

# This doesn't work, needs to be invoked by hand for each graph
##1336.png:
##	echo $(MAKE) $@ Q=1336q T=\"1336 WGS queries vs nt on spark mesos\"
##15795.png:
##	echo $(MAKE) $@ Q=15795q T=\"15795 WGS queries vs nt on spark mesos\"
##139340.png:
##	echo $(MAKE) $@ Q=139340q T=\"139340 WGS queries vs nt on spark mesos\"

.PHONY: dump
dump: ${DBNAME}
	sqlite3 ${DBNAME} .dump

.PHONY: show
show: ${DBNAME}
	sqlite3 -header -column ${DBNAME} < ddl/select.sql
	bin/reports.pl -label all | sort -n

.PHONY: reset
reset: ${DBNAME}
	sqlite3 ${DBNAME} < ddl/delete.sql

.PHONY: setup
setup:
	[ -d ${DATADIR} ] || mkdir ${DATADIR}

.PHONY: check
check:
	for f in bin/*.pl; do perl -c $$f ; done

.PHONY: simple
simple: ${GRAPH_SIMPLE}
.PHONY: graphs
graphs: ${GRAPHS}

#
#${GRAPHS}: ${GNUPLOT_DATA} ${GNUPLOT_CONF}
#	gnuplot -e "idx=0; title='megablast runtime: 215kb query vs. nt'; output='megablast-215kb-query.png'; data_file='${GNUPLOT_DATA}'" ${GNUPLOT_CONF}
#	gnuplot -e "idx=1; title='megablast runtime: 209kb query vs. nt'; output='megablast-209kb-query.png'; data_file='${GNUPLOT_DATA}'" ${GNUPLOT_CONF}
#	gnuplot -e "idx=2; title='megablast runtime: 185kb query vs. nt'; output='megablast-185kb-query.png'; data_file='${GNUPLOT_DATA}'" ${GNUPLOT_CONF}
#	gnuplot -e "idx=3; title='blastx runtime: 215kb query vs. nr'; output='blastx-215kb-query.png'; data_file='${GNUPLOT_DATA}'" ${GNUPLOT_CONF}
#	gnuplot -e "idx=4; title='blastx runtime: 209kb query vs. nr'; output='blastx-209kb-query.png'; data_file='${GNUPLOT_DATA}'" ${GNUPLOT_CONF}
#	gnuplot -e "idx=5; title='blastx runtime: 185kb query vs. nr'; output='blastx-185kb-query.png'; data_file='${GNUPLOT_DATA}'" ${GNUPLOT_CONF}
$(GRAPHS): $(GNUPLOT_DATA) $(GNUPLOT_CONF)
	gnuplot -e "title='$(TITLE)'; output='$@'; data_file='$<'" $(GNUPLOT_CONF)

${GNUPLOT_DATA}: ${DBNAME}
	#sqlite3 $< < ddl/select.sql | bin/data2gnuplot.pl > $@
	sqlite3 $< < ddl/select.sql | bin/multi-series-extractor.pl > $@

${GNUPLOT_DATA_SIMPLE}: ${DBNAME}
	bin/reports.pl -label all | sort -n | awk '{print $$1, $$3, $$5, $$7, $$9}' > $@

${GRAPH_SIMPLE}: ${GNUPLOT_DATA_SIMPLE} ${GNUPLOT_CONF_SIMPLE}
	gnuplot -e "output='$@'; title='$(TITLE_SIMPLE)'; data_file='$<'" ${GNUPLOT_CONF_SIMPLE}

.PHONY: clean
clean:
	$(RM) ${GNUPLOT_DATA} ${GRAPHS} ${GRAPH_SIMPLE} ${GNUPLOT_DATA_SIMPLE}

.PHONY: distclean
distclean: clean
	$(RM) ${DBNAME} log/*

