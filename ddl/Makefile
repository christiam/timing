.PHONY: all test distclean
DB?=dummy.db
all: test

%.db:
	sqlite3 $@ < create.sql
	sqlite3 $@ "PRAGMA user_version=`awk '/DB_VERSION/ {print $$NF}' ../version.pl`"

test: ${DB}
	sqlite3 $^ 'PRAGMA user_version;'
	sqlite3 $^ < insert.sql
	sqlite3 -header -column $^ < select.sql
	sqlite3 $^ < update.sql
	sqlite3 -header -column $^ < select.sql
	sqlite3 $^ < delete.sql
	sqlite3 -header -column $^ < select.sql

clean: ${DB}
	sqlite3 $^ < delete.sql

distclean:
	${RM} *.db
