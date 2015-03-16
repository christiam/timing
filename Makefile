.PHONY: all clean reset dump
DATADIR=data
DBNAME=${DATADIR}/timings.db

all: ${DBNAME}
	bin/driver.pl -v -v -v -v -r 3

${DBNAME}:
	[ -d ${DATADIR} ] || mkdir ${DATADIR}
	sqlite3 ${DBNAME} < ddl/create.sql

clean:
	-rm -f ${DBNAME} log/*

dump: ${DBNAME}
	sqlite3 ${DBNAME} .dump

show: ${DBNAME}
	sqlite3 -header -column ${DBNAME} < ddl/select.sql

reset: ${DBNAME}
	sqlite3 ${DBNAME} < ddl/delete.sql
