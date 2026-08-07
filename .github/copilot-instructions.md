# Copilot instructions for `timing`

This is a Perl-based runtime timing/benchmarking framework. It runs commands from a
*commands file*, records elapsed/user/system time and memory/CPU usage (via
`/usr/bin/time` and `vmstat`/`free`) into a SQLite database, and provides reporting and
gnuplot graphing on top of that data. There is no Python/Node code in this repo.

## Build, test, and lint

Install Perl dependencies (see `cpanfile`; requires `gcc` for `DBD::SQLite`):
```bash
cpanm --installdeps .                 # with root
cpanm --installdeps . ; export PERL5LIB=$HOME/perl5/lib/perl5   # without root
```

Full test suite (also run in CI, `.github/workflows/ci.yml`, Perl 5.30):
```bash
make test
```
`make test` runs, in order: `check_perl_syntax`, `test_sql`, `test_consecutive`,
`test_parallel`, `test_config`. Each is also a standalone target, e.g. to run just one:
```bash
make check_perl_syntax   # `perl -c` on bin/*.pl + --version checks
make test_sql            # delegates to `make -C ddl test` (insert/select/update/delete.sql against dummy.db)
make test_consecutive    # builds a temp commands file, runs driver.pl sequentially against data/testdb.db
make test_parallel       # same, but driver.pl -parallel
make test_config         # same, exercising the -cfg ini setup/teardown/env feature
```
There is no unit-test framework (no `Test::More`/`prove`); tests are Makefile-driven
integration tests that spin up a real SQLite DB and run the CLI tools end-to-end.
To sanity-check a single script directly: `perl -c bin/driver.pl`.

Other useful targets: `make help` lists all targets (`show`, `dump`, `reset`, `clean`,
`distclean`, `graphs`, `simple`, `archive`).

## Architecture

- **Commands file** (`etc/cmds.tab` by default, overridable via `CMDS_FILE`): tab-separated
  `label\tcommand`. `{LABEL}` in the command is substituted with the label (plus a
  `-N` suffix per repeat when `NUM_REPEATS > 1`).
- **`bin/driver.pl`** is the main entry point. It reads the commands file and runs each
  command wrapped in `/usr/bin/time` in one of two modes:
  - *Consecutive*: sequential execution, each command repeated `NUM_REPEATS` times.
  - *Parallel* (`-parallel`): all commands run concurrently via `Parallel::ForkManager`;
    `NUM_REPEATS` is ignored, and system-wide CPU/memory usage is sampled periodically
    while jobs run (`system_info` table).
  Results are written to a SQLite DB (`data/timings.db` by default, `-db`/`DBNAME`).
- **Optional ini config** (`-cfg`, e.g. `etc/timing.ini`, parsed with `Config::Simple`):
  per-label or `[all]` sections can define `setup`/`teardown` commands (not timed, but
  their exit status is recorded in `setup_exit_status`/`teardown_exit_status`) and an
  `env` key (`;`-separated `KEY=VALUE` pairs) to inject/unset environment variables
  around a command's execution.
- **Schema** lives in `ddl/create.sql`: `host_info` (one row per machine), `runtime`
  (one row per label+host run, FK to `host_info`), `system_info` (periodic samples
  during parallel runs), plus `runtime_view`/`system_info_view` convenience views and
  triggers that auto-populate `started_at`/`finished_at`/`timestamp`. Other `ddl/*.sql`
  files (`insert.sql`, `select.sql`, `update.sql`, `delete.sql`, `report-*.sql`) are used
  by the Makefile-driven tests and `make show`/`make dump`.
- **`version.pl`** defines both the app `$VERSION` and `$DB_VERSION` (stored as SQLite
  `PRAGMA user_version`). **Bump `$DB_VERSION` whenever `ddl/create.sql` changes.**
  Both `bin/driver.pl` and `bin/reports.pl` `require` this file via `lib::abs`.
- **`bin/reports.pl`** reads back from the DB per label and computes statistics
  (`Statistics::Descriptive`) on a chosen `-metric` (default `elapsed_time`).
- **Graphing pipeline**: `sqlite3 ... < ddl/select.sql` output is piped through
  `bin/multi-series-extractor.pl` or `bin/data2gnuplot.pl` to produce a `.dat` file,
  which the Makefile's `%.png: %.dat` pattern rule feeds to `gnuplot` using one of the
  `etc/*.gnuplot.conf` configs.
- `ddl/Makefile` and `data/Makefile` are separate sub-makefiles invoked from the root
  Makefile via `make -C ddl ...` / `make -C data ...` (e.g. to create/reset per-run DBs).

## Conventions

- All Perl scripts start with `use strict; use warnings; use autodie;` and use
  `Log::Log4perl` for logging (never bare `print` for diagnostics/errors) and
  `Try::Tiny` (`try`/`catch`/`finally`) for exception handling.
- CLI tools follow a consistent `Getopt::Long` option set: `-db`, `-verbose|-v` (stackable,
  more `-v`'s = more verbose, mapped in `verbosity2threshold`), `-version`, `-help|-?`
  (triggers full POD via `pod2usage(-verbose=>2)`), `-dry_run`, `-logfile`. Match this
  pattern when adding options to `bin/driver.pl` / `bin/reports.pl`.
  Prefer new options are added following this style, and documented in the script's POD
  (`=head1 ARGUMENTS`, etc.) — that POD is the user-facing docs (`--help`), not a
  separate markdown file.
- SQL statements used from Perl are declared as `use constant SQL_XXX => "...";` near the
  top of the file, not inlined at the call site.
- `lib::abs::path('../version.pl')` is the standard way each `bin/*.pl` script locates
  `version.pl` regardless of CWD.
- Known limitation: a single commands-file entry cannot chain multiple shell commands
  (e.g. `cmd1 && cmd2`).
