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


echo "PAGES, ACCESS, DIRTY %, SWAPPED %, PRESENT %, NONE %, REAL TIME, USER TIME, SYS TIME"

# for PAGES in 16 32 64 128 256 512 1024 2048 4096 8192 16384 32768 65536
for PAGES in 64 128 256
do
  for ACCESS in '-p' '-s' ;
  do
    for DIRTY_PER in 0 50 100 ;
    do
      . reset_test_cgroup.sh &>/dev/null
      cgexec -g memory:examples ~/kernel-test-scripts/create_page -t -c $PAGES $ACCESS -a -d $DIRTY_PER &>/dev/null &
      sleep 2
      DD_TIME=$(. ~/kernel-test-scripts/stats_dd_pagemap.sh -c $PAGES -v 0x600000000000 -m -p $(pgrep create_page))
      pkill -15 create_page >/dev/null
      echo "$PAGES, $ACCESS, $DIRTY_PER, $DD_TIME"
    done
  done
done



#     JOB_PID=$!
#     JOB_ID=$(jobs -l | grep $JOB_PID | cut -c2)
#     sleep 2
#     pkill -15 create_page >/dev/null
#     fg %$JOB_ID
