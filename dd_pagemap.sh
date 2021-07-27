#!/bin/bash

# Default Parameters
VADDR=$((0x600000000000))
COUNT=256
OFFSET=0
ITERATIONS=10
BATCH_SIZE=1

# Initialising Parameters
OPTIND=1
while getopts ":p:v:c:o:b:" arg; do
  case $arg in
    p) PID=$OPTARG;;
    v) VADDR=$OPTARG;;
    c) COUNT=$OPTARG;;
    o) OFFSET=$OPTARG;;
    b) BATCH_SIZE=$OPTARG;;
    ?) echo "Invalid option: -${OPTARG}."
       exit 1 ;;
  esac
done

# Convert Params for Batching
IBS=$(($BATCH_SIZE * 8))
BATCH_SKIP=$((($VADDR / 4096 + $OFFSET) / $BATCH_SIZE))
BATCH_COUNT=$(($COUNT / $BATCH_SIZE))

# Run program once
dd if=/proc/$PID/pagemap ibs=$IBS skip=$BATCH_SKIP count=$BATCH_COUNT 2>/dev/null

OPTIND=1
