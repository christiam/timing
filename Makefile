.PHONY: all clean reset dump
DBNAME=data/timings.db

all: ${DBNAME}
	bin/driver.pl -r 3 -l log/driver.log

${DBNAME}:
	sqlite3 ${DBNAME} < ddl/create.sql

clean:
	-rm -f ${DBNAME} log/*

dump: ${DBNAME}
	sqlite3 -header -column ${DBNAME} < ddl/select.sql

reset: ${DBNAME}
	sqlite3 ${DBNAME} < ddl/delete.sql
