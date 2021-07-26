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

rm -f /tmp/create_page_dirty.txt

echo "PAGES, ACCESS, DIRTY %, BATCH SIZE, SWAPPED %, PRESENT %, NONE %, MEAN REAL TIME, STDDEV, MEDIAN, USER TIME, SYS TIME, MIN TIME, MAX TIME"

# for PAGES in 16 32 64 128 256 512 1024 2048 4096 8192 16384 32768 65536
for PAGES in 4194304 # 16GB in pages
do
  for ACCESS in '-s' ;
  do
    for DIRTY_PER in 50 100 ;
    do
      for BATCH_SIZE in 1 2 4 8 16 32 64 ;
      do
        . reset_test_cgroup.sh &>/dev/null # -l 4G &>/dev/null # Curently flag not functional
        cgexec -g memory:examples ~/kernel-test-scripts/create_page -t -c $PAGES $ACCESS -a -d $DIRTY_PER &>/dev/null &
        while ! test -e /tmp/create_page_dirty.txt; do sleep 1; done
        rm -f /tmp/create_page_dirty.txt
        DD_TIME=$(. ~/kernel-test-scripts/stats_dd_pagemap.sh -c $PAGES -v 0x600000000000 -m -b $BATCH_SIZE -i 3 -p $(pgrep create_page))
        pkill -15 create_page >/dev/null
        tail --pid=$(pgrep create_page) -f /dev/null 2>/dev/null
        echo "$PAGES, $ACCESS, $DIRTY_PER, $BATCH_SIZE, $DD_TIME"
      done
    done
  done
done
