#!/bin/sh
#
# Program:  TimedExec.sh
#
# Synopsis: This script is a watchdog wrapper. It runs the specified program
# but times out if it does not complete in the allocated time frame.
# Syntax: ./TimedExec.sh <timeout> <program> <args...>
#

if [ $# -lt 2 ]; then
    echo "./TimedExec.sh <timeout> <program> <args...>"
    exit 1
fi

PARENT=""
if [ "$1" = "-p" ]; then
    PARENT=$2; shift; shift;
fi

TIMEOUT=$1
shift

if [ -z "$PARENT" ]; then
    # Start a watchdog process
    $0 -p $$ $TIMEOUT $* &
    exec "$@"
else
    # Sleep for a specified time then wake up to kill the parent process.
    exec > /dev/null 2>&1
    SEC=0
    while [ $SEC -lt $TIMEOUT ]; do
        sleep 1
        # Check if parent has completed.
        kill -s INFO $PARENT 2>/dev/null
        if [ $? -eq 1 ]; then
            exit 0
        fi
        SEC=$(($SEC + 1))
    done
    kill $PARENT && (sleep 2; kill -1 $PARENT) && (sleep 2; kill -9 $PARENT)
fi 

exit 0
