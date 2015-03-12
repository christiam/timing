.PHONY: all clean reset dump
DBNAME=data/timings.db

all: ${DBNAME}
	bin/driver.pl -l log/driver.log

${DBNAME}:
	sqlite3 ${DBNAME} < ddl/create.sql

clean:
	-rm -f ${DBNAME} log/*

dump:
	sqlite3 -header -column ${DBNAME} < ddl/select.sql

reset:
	sqlite3 ${DBNAME} < ddl/delete.sql
