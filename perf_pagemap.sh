#!/bin/bash

TEST_FILE=/tmp/test_file.txt
CREATE_PAGE_DIRTY_FILE=/tmp/create_page_dirty.txt
OUTPUT_FILE=~/perf_pagemap_out.csv

# Create (potentially) necessary files
if [[ ! -e "$TEST_FILE" ]]; then
  echo "Creating temporary file $TEST_FILE..."
  touch $TEST_FILE
  head -c 1073741824 </dev/urandom >$TEST_FILE
fi

if [[ ! -e "$OUTPUT_FILE" ]]; then
  echo "Creating output file $OUTPUT_FILE..."
  touch $OUTPUT_FILE
fi

# Remove trace of previous run
rm -f $CREATE_PAGE_DIRTY_FILE

# Table Column Names
echo "PAGES, ACCESS, DIRTY %, BATCH SIZE, SWAPPED %, PRESENT %, NONE %, MEAN REAL TIME, STDDEV, MEDIAN, USER TIME, SYS TIME, MIN TIME, MAX TIME"

# Run Performance Metrics for All Param Combinations
for PAGES in 4194304 # 16GB in pages
do
  for ACCESS in '-p' '-s' ;
  do
    for DIRTY_PER in 0 50 100 ;
    do
      # Create some pages and dirty them on a separate thread
      . reset_test_cgroup.sh -l 4G -s 60 1>2
      cgexec -g memory:examples ~/kernel-test-scripts/create_page -t -c $PAGES $ACCESS -a -d $DIRTY_PER 1>2 &
      while ! test -e $CREATE_PAGE_DIRTY_FILE; do sleep 1; done
      rm -f $CREATE_PAGE_DIRTY_FILE

      # Output Performance Metrics for All Param Combinations
      for BATCH_SIZE in 1 2 4 8 16 32 64;
      do
        DD_TIME=$(. ~/kernel-test-scripts/stats_dd_pagemap.sh -c $PAGES -v 0x600000000000 -m -b $BATCH_SIZE -i 5 -p $(pgrep create_page))
        echo "$PAGES, $ACCESS, $DIRTY_PER, $BATCH_SIZE, $DD_TIME"
      done

      pkill -15 create_page 1>2
      tail --pid=$(pgrep create_page) -f /dev/null 1>2
    done
  done
done
