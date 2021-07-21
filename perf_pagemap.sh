#!/bin/bash

TEST_FILE=/tmp/test_file.txt
INTER_FILE=/tmp/create_page.out
OUTPUT_FILE=~/perf_pagemap_out.csv

if [[ ! -e "$TEST_FILE" ]]; then
  echo "Creating temporary file $TEST_FILE..."
  touch $TEST_FILE
  head -c 1073741824 </dev/urandom >$TEST_FILE
fi

if [[ ! -e "$INTER_FILE" ]]; then
  echo "Creating output file for crate_page $INTER_FILE..."
  touch $INTER_FILE
fi

if [[ ! -e "$OUTPUT_FILE" ]]; then
  echo "Creating output file $OUTPUT_FILE..."
  touch $OUTPUT_FILE
fi

# for PAGES in 16 32 64 128 256 512 1024 2048 4096 8192 16384 32768 65536
for PAGES in 64 128 256
do
  for ACCESS in '-p' '-s' ;
    do
    for ALLOC in '-a' '-m' "-f $TEST_FILE"  ;
    do
      sudo cgexec -g memory:examples ~/kernel-test-scripts/create_page -c $PAGES $ACCESS $ALLOC 2>/dev/null
    done
  done
done



#     cgexec -g memory:examples /home/tiberiu.georgescu/kernel-test-scripts/create_page -c $PAGES $ACCESS $ALLOC >$INTER_FILE 2>/dev/null
#     JOB_PID=$!
#     JOB_ID=$(jobs -l | grep $JOB_PID | cut -c2)
#     sleep 2
#     cat $INTER_FILE
#     pkill -15 create_page >/dev/null
#     fg %$JOB_ID
