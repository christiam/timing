![CI](https://github.com/christiam/timing/workflows/CI/badge.svg)

This is a generic runtime timing and reporting framework. It records runtime
information (elapsed time, user and system time), memory usage and percentage
CPU usage (among other relevant data) in a locally stored relational database.

The commands to be timed are specified in a *commands file*, which is a
text file with 2 columns separated by a single `\t` character. It can be
specified via the `CMDS_FILE` environment variable (default
value=`etc/cmds.tab`). The first column in this file is a label to _uniquely_
identify the command to run and the second is the actual command to run.

The timing framework has 2 modes of operation: *consecutive tests* and *concurrent tests*.

### Consecutive tests

* Runs commands specified in *commands file* sequentially.
* Each command can be executed multiple times, this is controlled by the
`NUM_REPEATS` environment variable (default value=1).

### Concurrent tests

* Runs all the commands in the *commands file* in parallel.
* `NUM_REPEATS` is ignored in this mode.
* System information (percentage of CPU and memory used) is recorded while
  commands are executing. 

# Installation
1. Clone this repo: `git clone https://github.com/christiam/timing.git && cd timing`
2. Install dependencies: 
   1. If you have root permissions: `sudo cpanm --installdeps .`
   1. Without root permissions: `cpanm --installdeps . ; export PERL5LIB=$HOME/perl5/lib/perl5`

# Instructions
1. Create a *commands file* (or edit the `bin/setup-tests.sh` script to help you create it/them).
2. Run `make help` for a description of the targets

## Tools
* `bin/driver.pl`: Main driver script to execute commands in *commands file*. Run with `--help` option for additional documentation.
* `bin/reports.pl`: Extracts data from database and prints various statistical measures. Run with `--help` option for additional documentation.
* `bin/setup-tests.sh`: facilitates creating *commands file*(s).
* `bin/multi-series-extractor.pl`: intended for identical test cases run in series (e.g.: with N-M threads) that should be compared across the board.
* `bin/data2gnuplot.pl`: Plots multiple data sets into a single data file, intended to produce histograms

## Dependencies
* `/usr/bin/time`
* `/usr/bin/vmstat`
* `make`
* SQLite3
* See `cpanfile`. You will need `gcc` to run `cpanm DBD::SQLite`

**Note**: This framework has only been tested in Linux.

## Known issues
* You cannot use multiple commands in a single entry (e.g.: cmd1 && cmd2)

## Future work
* Implement collection of overall system information collection
* Refactor/dockerize
* Optimization: normalize system info table
