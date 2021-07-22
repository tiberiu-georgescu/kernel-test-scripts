#!/bin/bash

OUTPUT_FILE=~/dd_pagemap.out

if [[ ! -e "$OUTPUT_FILE" ]]; then
  echo "Creating temporary file $OUTPUT_FILE..."
  touch $OUTPUT_FILE
fi

OPTIND=1

ITERATIONS=10
OFFSET=0
COUNT=256
MUTE=0

while getopts ":p:v:c:o:m" arg; do
  case $arg in
    p) PID=$OPTARG;;
    v) VADDR=$OPTARG;;
    c) COUNT=$OPTARG;;
    o) OFFSET=$OPTARG;;
    i) ITERATIONS=$OPTARG;;
    m) MUTE=1;;
    ?) echo "Invalid option: -${OPTARG}."
       exit 2 ;;
  esac
done

if [ $MUTE -eq 0 ]; then
  echo "SWAPPED %, PRESENT %, NONE %, REAL TIME, USER TIME, SYS TIME"
fi

SKIP=$(($VADDR / 4096 + $OFFSET))
dd if=/proc/$PID/pagemap ibs=8 skip=$SKIP count=$COUNT >$OUTPUT_FILE 2>/dev/null
TIMES=$( (time for i in $(eval echo {1..$ITERATIONS}); do \
                 dd if=/proc/$PID/pagemap ibs=8 skip=$SKIP count=$COUNT &>/dev/null; \
               done) |& grep -Po [0-9]*m[0-9]*\.[0-9]*s)

SAVEIFS=$IFS   # Save current IFS
IFS=$'\n'      # Change IFS to new line
TIMES=($TIMES) # split to array $TIMES
IFS=$SAVEIFS   # Restore IFS

swapped=$(cat $OUTPUT_FILE | hexdump -C | cut -c 9-59 | grep -Po '([0-9a-f]{2}\s){7}[0-9a-f]{2}' | grep -Po '([0-9a-f]{2}\s){7}[4-5]0' | wc -l)
present=$(cat $OUTPUT_FILE | hexdump -C | cut -c 9-59 | grep -Po '([0-9a-f]{2}\s){7}[0-9a-f]{2}' | grep -Po '([0-9a-f]{2}\s){7}[0-9a-f]1' | wc -l)
zeroed=$(($COUNT - $swapped - $present))

echo "$swapped/$COUNT, $present/$COUNT, $zeroed/$COUNT, ${TIMES[0]}, ${TIMES[1]}, ${TIMES[2]}"


OPTIND=1
