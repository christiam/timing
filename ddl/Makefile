.PHONY: all test distclean
DB?=dummy.db
all: test

%.db:
	sqlite3 $@ < create.sql

test: ${DB}
	sqlite3 $^ < insert.sql
	sqlite3 -header -column $^ < select.sql
	sqlite3 $^ < update.sql
	sqlite3 -header -column $^ < select.sql
	sqlite3 $^ < delete.sql
	sqlite3 -header -column $^ < select.sql

distclean:
	${RM} *.db
