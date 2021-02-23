# Makefile for data directory
# Author: Christiam Camacho (camacho@ncbi.nlm.nih.gov)

.PHONY: all clean distclean
GI?=555
DB=timings.db
all: ${DB}

%.db:
	sqlite3 $@ < ../ddl/create.sql
	sqlite3 $@ "PRAGMA user_version=`awk '/DB_VERSION/ {print $$NF}' ../version.pl`"

# Could also use -s "gb|accession" instead of -g below
%.fsa:
	idfetch -t 5 -c 1 -o $@ -g ${GI}

u00001.fsa:
	blastdbcmd -db nt -out $@ -entry u00001

129295.fsa:
	blastdbcmd -db nr -out $@ -entry 129295

clean:
	-for f in *.db; do if [ -s $$f ] ; then sqlite3 $$f < ../ddl/delete.sql; fi; done

distclean:
	$(RM) *.fsa *.db
