![CI](https://github.com/christiam/timing/workflows/CI/badge.svg)

This is a generic runtime timing framework.

The commands to be timed are specified in a *commands file*, which is just a
plain text file with 2 columns separated by a single `\t` character. The
default is `etc/cmds.tab` and it can be overriden by using the `CMDS_FILE`
environment variable.

The framework has 2 modes of operation: *consecutive tests* and *concurrent tests*.

### Consecutive tests

* Runs tests specified in commands file sequentially.
* Each test can be executed multiple times, this is controlled by the
`NUM_REPEATS` `Makefile` variable (default value=1).

By providing commands in the commands file `etc/cmds.tab` file and setting the number of
repetitions on the `Makefile` (default value of 1 provided), one can record the
runtime (wall clock, system and user time as well as timestamp) of test cases.

### Concurrent tests

* Runs all the tests in the commands file in parallel.
* `NUM_REPEATS` is ignored in this mode.

# Instructions
1. Edit the `bin/setup-tests.sh` script to easily overwrite the file containing
the commands to run (`etc/cmds.tab`). This file should contain lines with the
format "label\tcmd" format.
2. Run `make help` for a description of the targets

## Tools
* `bin/driver.pl`: Main driver script
* `bin/reports.pl`: Extracts data from database and prints various statistical measures
* `bin/setup-tests.sh`: facilitates setting up the system to run tests
* `bin/multi-series-extractor.pl`: intended for identical test cases run in series (e.g.: with N-M threads) that should be compared across the board.
* `bin/data2gnuplot.pl`: Plots multiple data sets into a single data file, intended to produce histograms

## Dependencies
* `make`
* SQLite3
* See `cpanfile`. You will need `gcc` to run `cpanm DBD::SQLite`

## Known issues
* You cannot use multiple commands in a single entry (e.g.: cmd1 && cmd2)
