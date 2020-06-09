This is a generic runtime timing framework.

By providing commands in the `etc/cmds.tab` file and setting the number of
repetitions on the `Makefile` (default value of 1 provided), one can record the
runtime (wall clock, system and user time as well as timestamp) of test cases.

# Instructions
1. Edit the `bin/setup-tests.sh` script to easily overwrite the file containing
the commands to run (etc/cmds.tab). This file should contain lines with the
format "label\tcmd" format.
2. Run `make help` for a description of the targets

## Manifest
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
