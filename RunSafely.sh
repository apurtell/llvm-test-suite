#!/bin/sh
#
# Program:  RunSafely.sh
#
# Synopsis: This script simply runs another program.  If the program works
#           correctly, this script has no effect, otherwise it will do things
#           like print a stack trace of a core dump.  It always returns
#           "successful" so that tests will continue to be run.
#
#           This script funnels stdout and stderr from the program into the
#           fourth argument specified, and outputs a <outfile>.time file which
#           contains a timing of the program and the program's exit code.
#          
#           If the <exitok> (2nd) parameter is 0 then this script always
#           returns 0, regardless of the actual exit of the <program>.
#           If the <exitok> parameter is non-zero then this script returns
#           the exit code of the <program>. If there is an error in getting
#           the <program>'s exit code, this script returns 99.
#
# Syntax: 
#
#   RunSafely.sh <timeout> <exitok> <infile> <outfile> <program> <args...>
#
#   where:
#     <timeout> is the maximum number of seconds to let the <program> run
#     <exitok>  is 1 if the program must exit with 0 return code
#     <infile>  is a file from which standard input is directed
#     <outfile> is a file to which standard output and error are directed
#     <program> is the path to the program to run
#     <args...> are the arguments to pass to the program.
#
if [ $# -lt 4 ]; then
  echo "./RunSafely.sh <timeout> <exitok> <infile> <outfile> <program> <args...>"
  exit 1
fi

DIR=${0%%`basename $0`}
ULIMIT=$1
EXITOK=$2
INFILE=$3
OUTFILE=$4
PROGRAM=$5
shift 5
SYSTEM=`uname -s`

case $SYSTEM in
  CYGWIN*) 
    ;;
  Darwin*)
    # Disable core file emission, the script doesn't find it anyway because it is put 
    # into /cores.
    ulimit -c 0
    ulimit -t $ULIMIT
    # To prevent infinite loops which fill up the disk, specify a limit on size of
    # files being output by the tests. 10 MB should be enough for anybody. ;)
    ulimit -f 10485760
    ;;
  *)
    ulimit -t $ULIMIT
    ulimit -c unlimited
    # To prevent infinite loops which fill up the disk, specify a limit on size of
    # files being output by the tests. 10 MB should be enough for anybody. ;)
    ulimit -f 10485760
esac
rm -f core core.*

#
# Run the command, timing its execution.
# The standard output and standard error of $PROGRAM should go in $OUTFILE,
# and the standard error of time should go in $OUTFILE.time. Note that the 
# return code of the program is appended to the $OUTFILE on an "Exit Val ="
# line.
#
# To get the time program and the specified program different output filenames,
# we tell time to launch a shell which in turn executes $PROGRAM with the
# necessary I/O redirection.
#
COMMAND="$PROGRAM $*"
if [ $SYSTEM == Darwin ]; then
  COMMAND="${DIR}TimedExec.sh $ULIMIT $COMMAND"
fi

( time -p sh -c "$COMMAND >$OUTFILE 2>&1 < $INFILE" ; echo exit $? ) 2>&1 \
  | awk -- '\
BEGIN     { cpu = 0.0; }
/^user/   { cpu += $2; print; }
/^sys/    { cpu += $2; print; }
!/^user/ && !/^sys/  { print; }
END       { printf("program %f\n", cpu); }' > $OUTFILE.time

if [ "$EXITOK" -ne 0 ] ; then
  exitval=`grep '^exit ' $OUTFILE.time | sed -e 's/^exit //'`
  if [ -z "$exitval" ] ; then
    exitval=99
  fi
else
  exitval=0
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
    echo "where 100" > StackTrace.$$
    $GDB -q -batch --command=StackTrace.$$ --core=$corefile $PROGRAM < /dev/null
    rm -f StackTrace.$$ $corefile
fi
exit "$exitval"
