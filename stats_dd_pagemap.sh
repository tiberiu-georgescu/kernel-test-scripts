#!/bin/bash

EXPORT_CSV='/tmp/test.csv'
OUTPUT_FILE=~/dd_pagemap.out

if [[ ! -e "$OUTPUT_FILE" ]]; then
  echo "Creating temporary file $OUTPUT_FILE..."
  touch $OUTPUT_FILE
fi

OPTIND=1

ITERATIONS=10
COUNT=256
BATCH_SIZE=1
MUTE=0

while getopts ":p:v:c:i:b:m" arg; do
  case $arg in
    p) PID=$OPTARG;;
    v) VADDR=$OPTARG;;
    c) COUNT=$OPTARG;;
    i) ITERATIONS=$OPTARG;;
    b) BATCH_SIZE=$OPTARG;;
    m) MUTE=1;;
    ?) echo "Invalid option: -${OPTARG}."
       exit 2 ;;
  esac
done

if [ $MUTE -eq 0 ]; then
  echo "SWAPPED %, PRESENT %, NONE %, MEAN REAL TIME, STDDEV, MEDIAN, USER TIME, SYS TIME, MIN TIME, MAX TIME"
fi

IBS=$(($BATCH_SIZE * 8))
SKIP=$((($VADDR / 4096) / $BATCH_SIZE))
BATCH_COUNT=$(($COUNT / $BATCH_SIZE))
dd if=/proc/$PID/pagemap ibs=$IBS skip=$SKIP count=$BATCH_COUNT >$OUTPUT_FILE 2>/dev/null
hyperfine --style none --export-csv $EXPORT_CSV --warmup 3 --runs $ITERATIONS\
	"dd if=/proc/$PID/pagemap ibs=$IBS skip=$SKIP count=$BATCH_COUNT" &>/dev/null

TIMES=$(cat $EXPORT_CSV | tail -n 1 | cut -d "," -f2-)

swapped=$(cat $OUTPUT_FILE | hexdump -C | cut -c 9-59 | grep -Po '([0-9a-f]{2}\s){7}[0-9a-f]{2}' | grep -Po '([0-9a-f]{2}\s){7}[4-5]0' | wc -l)
present=$(cat $OUTPUT_FILE | hexdump -C | cut -c 9-59 | grep -Po '([0-9a-f]{2}\s){7}[0-9a-f]{2}' | grep -Po '([0-9a-f]{2}\s){7}[0-9a-f]1' | wc -l)
zeroed=$(($COUNT - $swapped - $present))

echo "$swapped/$COUNT, $present/$COUNT, $zeroed/$COUNT, $TIMES"


OPTIND=1
