#!/bin/sh
#
# Program:  RunSafelyAndStable.sh
#
# Synopsis: This script runs another program three times.  If the program works
#           correctly, this script has no effect, otherwise it will do things
#           like print a stack trace of a core dump.  It always returns
#           "successful" so that tests will continue to be run.
#
#           This script funnels stdout and stderr from the program into the
#           first argument specified, and outputs a <outputfile>.time file which
#           contains timing information for the fastest of the three runs of the
#           program.
#
# Syntax:
#    ./RunSafelyAndStable.sh <ulimit> <stdinfile> <stdoutfile> <program> <args...>
#
ULIMIT=$1
INFILE=$2
OUTFILE=$3
PROGRAM=$4
shift 4

ulimit -t $ULIMIT
rm -f core core.*
ulimit -c unlimited
# To prevent infinite loops which fill up the disk, specify a limit on size of
# files being output by the tests. 10 MB should be enough for anybody. ;)
ulimit -f 10485760

#
# Run the command, timing its execution.
# The standard output and standard error of $PROGRAM should go in $OUTFILE,
# and the standard error of time should go in $OUTFILE.time.
#
# Ah, the joys of shell programming!
# To get the time program and the specified program different output filenames,
# we tell time to launch a shell which in turn executes $PROGRAM with the
# necessary I/O redirection.
#
(time -p sh -c "$PROGRAM $* > $OUTFILE 2>&1 < $INFILE") 2>&1 | awk -- '\
BEGIN     { cpu = 0.0; }
/^user/   { cpu += $2; print }
/^sys/    { cpu += $2; print }
!/^user/ && !/^sys/  { print }
END       { printf("program %f\n", cpu); }' > $OUTFILE.time1

if test $? -eq 0
then
    touch $OUTFILE.exitok
fi

if ls | egrep "^core" > /dev/null
then
    # If we are on a sun4u machine (UltraSparc), then the code we're generating
    # is 64 bit code.  In that case, use gdb-64 instead of gdb.
    myarch=`uname -m`
    if [ "$myarch" = "sun4u" ]
    then
	GDB="gdb-64"
    else
	GDB=gdb
    fi

    corefile=`ls core* | head -n 1`
    echo "where" > StackTrace.$$
    $GDB -q -batch --command=StackTrace.$$ --core=$corefile $PROGRAM < /dev/null
    rm -f StackTrace.$$ $corefile
    exit 0
fi

TIME1=`grep program $OUTFILE.time1 | sed 's/^program//'`
echo "Program $PROGRAM run #1 time: $TIME1"

# Do the second and third runs now

(time -p sh -c "$PROGRAM $* > $OUTFILE 2>&1 < $INFILE") 2>&1 | awk -- '\
BEGIN     { cpu = 0.0; }
/^real/   { print }
/^user/   { cpu += $2; print }
/^sys/    { cpu += $2; print }
!/^real/ && !/^user/ && !/^sys/  { print }
END       { printf("program %f\n", cpu); }' > $OUTFILE.time2

TIME2=`grep program $OUTFILE.time2 | sed 's/^program//'`
echo "Program $PROGRAM run #2 time: $TIME2"

(time -p sh -c "$PROGRAM $* > $OUTFILE 2>&1 < $INFILE") 2>&1 | awk -- '\
BEGIN     { cpu = 0.0; }
/^real/   { print }
/^user/   { cpu += $2; print }
/^sys/    { cpu += $2; print }
!/^real/ && !/^user/ && !/^sys/  { print }
END       { printf("program %f\n", cpu); }' > $OUTFILE.time3

TIME3=`grep program $OUTFILE.time3 | sed 's/^program//'`
echo "Program $PROGRAM run #3 time: $TIME3"

# Figure out which run had the smallest run time:
SHORTEST=`echo -e "$TIME1 time1\n$TIME2 time2\n$TIME3 time3" | sort | 
                head -1 | sed "s|.*time||"`

echo "Program $PROGRAM run #$SHORTEST was fastest"
cp $OUTFILE.time$SHORTEST $OUTFILE.time

exit 0
