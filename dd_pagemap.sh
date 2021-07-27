#!/bin/bash

function usage {
  echo "Usage: $(basename $BASH_SOURCE) [-h] [-p PID] [-v VADDR] [-c PAGES] [-o OFFSET] [-b BATCH_SIZE]" 2>&1
  echo "   -p PID         PID of monitored process"
  echo "   -v VADDR       virtual address at which dd read starts"
  echo "   -c PAGES       number of pagemap entries that dd needs to read"
  echo "   -o OFFSET      pagemap entry index from which dd may want to read"
  echo "   -b BATCH_SIZE  number of pagemap entries being read in one function call"
  echo "   -h  Help menu"
  return 1
}

# if no input argument found, exit the script with usage
if [[ ${#} -eq 0 ]]; then
  usage
  return 1
fi

# Default Parameters
VADDR=$((0x600000000000))
COUNT=256
OFFSET=0
ITERATIONS=10
BATCH_SIZE=1

# Initialising Parameters
OPTIND=1
while getopts ":p:v:c:o:b:h" arg; do
  case $arg in
    h) usage
       return 1 ;;
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
