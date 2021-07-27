#!/bin/bash

function usage {
  echo "Usage: $(basename $BASH_SOURCE) [-h] [-m] [-p PID] [-v VADDR] [-c PAGES] [-i ITERATIONS] [-b BATCH_SIZE]" 2>&1
  echo "   -p PID         PID of monitored process"
  echo "   -v VADDR       virtual address at which dd read starts"
  echo "   -c PAGES       number of pagemap entries that dd needs to read"
  echo "   -i ITERATIONS  number of times dd is repeated for performance measurement"
  echo "   -b BATCH_SIZE  number of pagemap entries being read in one function call"
  echo "   -m  "MUTE". Only used in conjunction with perf_pagemap. Notifies not to output the top line of the results"
  echo "   -h  Help menu"
  return 1
}

EXPORT_CSV='/tmp/test.csv'
OUTPUT_FILE=~/dd_pagemap.out

# Create (potentially) necessary files
if [[ ! -e "$OUTPUT_FILE" ]]; then
  echo "Creating temporary file $OUTPUT_FILE..."
  touch $OUTPUT_FILE
fi

# if no input argument found, exit the script with usage
if [[ ${#} -eq 0 ]]; then
  usage
  return 1
fi

# Default Parameters
VADDR=$((0x600000000000))
COUNT=256
ITERATIONS=10
BATCH_SIZE=1
MUTE=0

# Initialising Parameters
OPTIND=1
while getopts ":p:v:c:i:b:mh" arg; do
  case $arg in
    h) usage
       return 1 ;;
    p) PID=$OPTARG;;
    v) VADDR=$OPTARG;;
    c) COUNT=$OPTARG;;
    i) ITERATIONS=$OPTARG;;
    b) BATCH_SIZE=$OPTARG;;
    m) MUTE=1;;
    ?) echo "Invalid option: -${OPTARG}."
       return 2 ;;
  esac
done

# Table Column Names
if [ $MUTE -eq 0 ]; then
  echo "SWAPPED %, PRESENT %, NONE %, MEAN REAL TIME, STDDEV, MEDIAN, USER TIME, SYS TIME, MIN TIME, MAX TIME"
fi

# Convert Params for Batching
IBS=$(($BATCH_SIZE * 8))
BATCH_SKIP=$((($VADDR / 4096) / $BATCH_SIZE))
BATCH_COUNT=$(($COUNT / $BATCH_SIZE))

# Run program once without checking performance, to retrieve output
dd if=/proc/$PID/pagemap ibs=$IBS skip=$BATCH_SKIP count=$BATCH_COUNT >$OUTPUT_FILE

# Retrieve Performance Metrics
hyperfine --style none --export-csv $EXPORT_CSV --warmup 2 --runs $ITERATIONS\
	"dd if=/proc/$PID/pagemap ibs=$IBS skip=$BATCH_SKIP count=$BATCH_COUNT" 1>2
TIMES=$(cat $EXPORT_CSV | tail -n 1 | cut -d "," -f2-)

# Retrieve Comparison Metrics from Output File
swapped=$(cat $OUTPUT_FILE | hexdump -C | cut -c 9-59 | grep -Po '([0-9a-f]{2}\s){7}[0-9a-f]{2}' | grep -Po '([0-9a-f]{2}\s){7}[4-5]0' | wc -l)
present=$(cat $OUTPUT_FILE | hexdump -C | cut -c 9-59 | grep -Po '([0-9a-f]{2}\s){7}[0-9a-f]{2}' | grep -Po '([0-9a-f]{2}\s){7}[0-9a-f]1' | wc -l)
zeroed=$(($COUNT - $swapped - $present))

# Output Performance Metrics
echo "$swapped/$COUNT, $present/$COUNT, $zeroed/$COUNT, $TIMES"

OPTIND=1
