#!/bin/sh
#
# Program:  DiffOutput.sh
#
# Synopsis: Check two output files for program executions and make sure they
#           match.
#
# Syntax:  ./DiffOutput [lli|llc] <testname>
#

# DIFFOUTPUT - The output filename to make
DIFFOUTPUT=Output/$2.diff-$1

# Diff the two files.
gdiff -u Output/$2.out-nat Output/$2.out-$1 > $DIFFOUTPUT || (
  # They are different!
  echo "******************** TEST '$2' FAILED! ********************"
  echo "Execution Context Diff:"
  cat $DIFFOUTPUT
  rm $DIFFOUTPUT
  echo "******************** TEST '$2' FAILED! ********************"
)
