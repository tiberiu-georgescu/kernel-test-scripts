#!/bin/bash

OPTIND=1

OFFSET=0
COUNT=256

while getopts ":p:v:c:o:" arg; do
  case $arg in
    p) PID=$OPTARG;;
    v) VADDR=$OPTARG;;
    c) COUNT=$OPTARG;;
    o) OFFSET=$OPTARG;;
  esac
done

dd if=/proc/$PID/pagemap ibs=8 skip=$(($VADDR / 4096 + $OFFSET)) count=$COUNT 2>/dev/null

OPTIND=1
